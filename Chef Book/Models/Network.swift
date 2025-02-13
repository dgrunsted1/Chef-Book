//
//  Network.swift
//  Chef Book
//
//  Created by David Grunsted on 6/25/24.
//

import SwiftUI

class Network: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var categories: [String] = []
    @Published var cuisines: [String] = []
    @Published var countries: [String] = []
    @Published var authors: [String] = []
    @Published var user: UserResponse?;
    @Published var today: MyMenu?;
    
    func getRecipes(category: String, cuisine: String, country: String, author: String, sort: String, made: Bool, search: String) {
        let filter = build_filter(category: category, cuisine: cuisine, country: country, author: author, sort: sort, made: made, search: search)
        guard let url = URL(string: "https://db.ivebeenwastingtime.com/api/collections/recipes/records?page=1&perPage=150\(filter)&expand=notes%2C%20ingr_list") else { fatalError("Missing URL") }

        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            
            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decoded_recipes = try JSONDecoder().decode(Response.self, from: data)
                        self.recipes = decoded_recipes.items.map { recipeData in
                            let time_in_seconds = recipeData.time_new*60
                            let ingredients = recipeData.expand.ingr_list.map { ingr in
                                return Ingredient(id: ingr.id, quantity: ingr.quantity, unit: ingr.unit, name: ingr.ingredient)
                            }
                            var notes: [String] = []
                            if recipeData.expand.notes != nil {
                                notes = recipeData.expand.notes.map { note in
                                    return note.content
                                }
                            }
                            return Recipe(id: recipeData.id, title: recipeData.title, description: recipeData.description, link_to_original_web_page: recipeData.url, author: recipeData.author, time_in_seconds: time_in_seconds, directions: recipeData.directions, image: recipeData.image, servings: recipeData.servings, cuisine: recipeData.cuisine, country: recipeData.country, notes: notes, ingredients: ingredients, category: recipeData.category, made: recipeData.made, favorite: recipeData.favorite)
                        }
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }

        dataTask.resume()
        if search != "" { 
            getIngredientRecipes(category: category, cuisine: cuisine, country: country, author: author, sort: sort, made: made, search: search)
        }
    }
    
    func getIngredientRecipes(category: String, cuisine: String, country: String, author: String, sort: String, made: Bool, search: String) {
        let filter = build_ingredient_filter(category: category, cuisine: cuisine, country: country, author: author, sort: sort, made: made, search: search)
        print(filter)
        guard let url = URL(string: "https://db.ivebeenwastingtime.com/api/collections/ingredients/records?page=1&perPage=30&expand=recipe%2C%20recipe.ingr_list\(filter)") else { fatalError("Missing URL") }

        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            
            if response.statusCode == 200 {
                guard let data = data else { return }
                
                DispatchQueue.main.async {
                    do {
                        let decoded_recipes = try JSONDecoder().decode(IngredientResponse.self, from: data)
                        let temp_recipes: [[Recipe]] = decoded_recipes.items.map { ingredientData in
                            return ingredientData.expand.recipe.map { recipeData in
                                
                                let ingr_list = recipeData.expand.ingr_list.map { currIngr in
                                    return Ingredient(id: currIngr.id, quantity: currIngr.quantity, unit: currIngr.unit, name: currIngr.ingredient)
                                }
                                let time_in_seconds = recipeData.time_new*60
                                return Recipe(id: recipeData.id, title: recipeData.title, description: recipeData.description, link_to_original_web_page: recipeData.url, author: recipeData.author, time_in_seconds: time_in_seconds, directions: recipeData.directions, image: recipeData.image, servings: recipeData.servings, cuisine: recipeData.cuisine, country: recipeData.country, notes: recipeData.notes, ingredients: ingr_list, category: recipeData.category, made: recipeData.made, favorite: recipeData.favorite)
                            }
                        }
                        temp_recipes.forEach { recipe_list in
                            recipe_list.forEach { curr_recipe in
                                var add = true
                                self.recipes.forEach { check_recipe in
                                    if curr_recipe.id == check_recipe.id {
                                        add = false
                                    }
                                }
                                if add {
                                    self.recipes.append(curr_recipe)
                                }
                            }
                        }

                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }

        dataTask.resume()
    }
    
    func getCategories() {
        guard let url = URL(string: "https://db.ivebeenwastingtime.com/api/collections/categories/records?page=1&perPage=200&sort=%2Bid") else { fatalError("Missing URL") }

        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            
            if response.statusCode == 200 {
                guard let data = data else { return }
                
                DispatchQueue.main.async {
                    do {
                        let decoded_categories = try JSONDecoder().decode(CatResponse.self, from: data)
                        self.categories = decoded_categories.items.map { curr in
                            return curr.id
                        }
                        self.categories.insert("category", at: 0)
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }

        dataTask.resume()
    }
    
    func getCuisines() {
        guard let url = URL(string: "https://db.ivebeenwastingtime.com/api/collections/cuisines/records?page=1&perPage=200&sort=%2Bid") else { fatalError("Missing URL") }

        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            
            if response.statusCode == 200 {
                guard let data = data else { return }
                
                DispatchQueue.main.async {
                    do {
                        let decoded_categories = try JSONDecoder().decode(CatResponse.self, from: data)
                        self.cuisines = decoded_categories.items.map { curr in
                            return curr.id
                        }
                        self.cuisines.insert("cuisine", at: 0)
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }

        dataTask.resume()
    }
    
    func getCountries() {
        guard let url = URL(string: "https://db.ivebeenwastingtime.com/api/collections/countries/records?page=1&perPage=200&sort=%2Bid") else { fatalError("Missing URL") }

        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            
            if response.statusCode == 200 {
                guard let data = data else { return }
                
                DispatchQueue.main.async {
                    do {
                        let decoded_categories = try JSONDecoder().decode(CatResponse.self, from: data)
                        self.countries = decoded_categories.items.map { curr in
                            return curr.id
                        }
                        self.countries.insert("country", at: 0)
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }

        dataTask.resume()
    }
    
    func getAuthors() {
        guard let url = URL(string: "https://db.ivebeenwastingtime.com/api/collections/authors/records?page=1&perPage=200&sort=%2Bid") else { fatalError("Missing URL") }

        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            
            if response.statusCode == 200 {
                guard let data = data else { return }
                
                DispatchQueue.main.async {
                    do {
                        let decoded_categories = try JSONDecoder().decode(CatResponse.self, from: data)
                        self.authors = decoded_categories.items.map { curr in
                            return curr.id
                        }
                        self.authors.insert("author", at: 0)
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }

        dataTask.resume()
    }
    
    private func build_filter(category: String, cuisine: String, country: String, author: String, sort: String, made: Bool, search: String) -> String{
        var output = ""
        if category != "category" {
            if output == ""{
                output += "&filter="
            } else {
                output += "%26%26%20"
            }
            output += "category%3D%22\(category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")%22"
        }
        if cuisine != "cuisine" {
            if output == ""{
                output += "&filter="
            } else {
                output += "%26%26%20"
            }
            output += "cuisine%3D%22\(cuisine.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")%22"
        }
        if country != "country" {
            if output == ""{
                output += "&filter="
            } else {
                output += "%26%26%20"
            }
            output += "country%3D%22\(country.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")%22"
        }
        if author != "author" {
            if output == "" {
                output += "&filter="
            } else {
                output += "%26%26%20"
            }
            output += "author%3D%22\(author.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")%22"
        }
        if search != "" {
            if output == "" {
                output += "&filter="
            } else {
                output += "%26%26%20"
            }
            output += "title~%22\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")%22"
        }
        
        if made {
            if output == "" {
                output += "&filter="
            } else {
                output += "%26%26%20"
            }
            output += "made%3D\(made)"
        }
        
        
        switch sort {
            case "least ingredients":
                output = "&sort=+ingr_num"
            case "most ingredients":
                output += "&sort=-ingr_num"
            case "least servings":
                output += "&sort=+servings_new"
            case "most servings":
                output += "&sort=-servings_new"
            case "least time":
                output += "&sort=+time_new"
            case "most time":
                output += "&sort=-time_new"
            case "least recent":
                output += "&sort=+created"
        default:
            output += "&sort=-created"
        }
        return output
    }
    
    private func build_ingredient_filter(category: String, cuisine: String, country: String, author: String, sort: String, made: Bool, search: String) -> String{
        var output = ""
        if category != "category" {
            if output == ""{
                output += "&filter="
            } else {
                output += "%26%26%20"
            }
            output += "recipe.category%3D%22\(category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")%22"
        }
        if cuisine != "cuisine" {
            if output == ""{
                output += "&filter="
            } else {
                output += "%26%26%20"
            }
            output += "recipe.cuisine%3D%22\(cuisine.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")%22"
        }
        if country != "country" {
            if output == ""{
                output += "&filter="
            } else {
                output += "%26%26%20"
            }
            output += "recipe.country%3D%22\(country.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")%22"
        }
        if author != "author" {
            if output == "" {
                output += "&filter="
            } else {
                output += "%26%26%20"
            }
            output += "recipe.author%3D%22\(author.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")%22"
        }
        if search != "" {
            if output == "" {
                output += "&filter="
            } else {
                output += "%26%26%20"
            }
            output += "ingredient~%22\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")%22"
        }
        
        if made {
            if output == "" {
                output += "&filter="
            } else {
                output += "%26%26%20"
            }
            output += "recipe.made%3D\(made)"
        }
        
        
        switch sort {
            case "least ingredients":
                output = "&sort=+recipe.ingr_num"
            case "most ingredients":
                output += "&sort=-recipe.ingr_num"
            case "least servings":
                output += "&sort=+recipe.servings_new"
            case "most servings":
                output += "&sort=-recipe.servings_new"
            case "least time":
                output += "&sort=+recipe.time_new"
            case "most time":
                output += "&sort=-recipe.time_new"
            case "least recent":
                output += "&sort=+recipe.created"
        default:
            output += "&sort=-recipe.created"
        }
        return output
    }

    
    func sign_in(username: String, password: String){
        let requestBody = "identity=\(username)&password=\(password)".data(using: .utf8)
        makePostRequest(to: "https://db.ivebeenwastingtime.com/api/collections/users/auth-with-password", with: requestBody) { data, response, error in
            if let error = error {
                print("Error: \(error)")
            } else if let data = data {
                print("Response data: \(String(data: data, encoding: .utf8) ?? "N/A")")
                DispatchQueue.main.async {
                    do {
                        self.user = try JSONDecoder().decode(UserResponse.self, from: data)
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }
    }
    
    func makePostRequest(to endpoint: String, with body: Data?, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(nil, nil, NSError(domain: "Invalid URL", code: 0, userInfo: nil))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            completion(data, response, error)
        }
        
        task.resume()
    }
    
    func get_todays_menu(){
        guard let url = URL(string: "https://db.ivebeenwastingtime.com/api/collections/menus/records?page=1&perPage=1&filter=user%3D%22\(self.user!.record.id)%22%20%26%26%20today%3DTrue&expand=recipes%2Crecipes.notes%2Crecipes.ingr_list%2C%20grocery_list") else { fatalError("Missing URL") }
        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }
            
            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decoded_menu = try JSONDecoder().decode(TodaysResponse.self, from: data)
                        let temp_recipes = decoded_menu.items[0].expand.recipes.map { recipeData in
                            let time_in_seconds = recipeData.time_new*60
                            let ingredients = recipeData.expand.ingr_list.map { ingr in
                                return Ingredient(id: ingr.id, quantity: ingr.quantity, unit: ingr.unit, name: ingr.ingredient)
                            }
                            var notes: [String] = []
                            if recipeData.expand.notes != nil {
                                notes = recipeData.expand.notes.map { note in
                                    return note.content
                                }
                            }
                            return Recipe(id: recipeData.id, title: recipeData.title, description: recipeData.description, link_to_original_web_page: recipeData.url, author: recipeData.author, time_in_seconds: time_in_seconds, directions: recipeData.directions, image: recipeData.image, servings: recipeData.servings, cuisine: recipeData.cuisine, country: recipeData.country, notes: notes, ingredients: ingredients, category: recipeData.category, made: recipeData.made, favorite: recipeData.favorite)
                        }
                        
                        let temp_groceries = decoded_menu.items[0].expand.grocery_list.list.map{ groc_item in
                            return GroceryItem(id: groc_item.id, checked: groc_item.checked, ingredient: Ingredient(id: groc_item.id, quantity: groc_item.quantity.value, unit: groc_item.unit, name: groc_item.ingredient))
                        }
                        
                        self.today = MyMenu(created: decoded_menu.items[0].created, desc: decoded_menu.items[0].description, grocery_list: temp_groceries, id: decoded_menu.items[0].id, made: decoded_menu.items[0].made, notes: decoded_menu.items[0].notes, recipes: temp_recipes, servings: decoded_menu.items[0].servings, sub_recipes: decoded_menu.items[0].sub_recipes, title: decoded_menu.items[0].title, today: decoded_menu.items[0].today, updated: decoded_menu.items[0].updated)
                        
//                        self.today = decoded_menu.items[0]
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }

        dataTask.resume()
        
    }
}

