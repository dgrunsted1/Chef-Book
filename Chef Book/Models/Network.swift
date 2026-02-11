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
    @Published var user: UserResponse?
    @Published var authToken: String?
    @Published var today: MyMenu?
    @Published var menus: [MyMenu] = []
    @Published var isLoading: Bool = false

    private let baseURL = "https://db.ivebeenwastingtime.com"
    private var realtime: PocketBaseRealtime?

    init() {
        restoreSession()
    }

    private func restoreSession() {
        if let userData = UserDefaults.standard.data(forKey: "user_response"),
           let savedUser = try? JSONDecoder().decode(UserResponse.self, from: userData) {
            self.user = savedUser
            self.authToken = savedUser.token
            connectRealtime()
        }
    }

    func connectRealtime() {
        realtime?.disconnect()
        realtime = PocketBaseRealtime(baseURL: baseURL)
        realtime?.connect(token: authToken)

        realtime?.subscribe(to: "recipes") { [weak self] data in
            guard let action = data["action"] as? String else { return }
            if action == "update" || action == "create" || action == "delete" {
                // Refresh recipes on any change
                DispatchQueue.main.async {
                    self?.getRecipes(category: "category", cuisine: "cuisine", country: "country", author: "author", sort: "most recent", made: true, search: "")
                }
            }
        }

        realtime?.subscribe(to: "grocery_lists") { [weak self] data in
            guard let action = data["action"] as? String else { return }
            if action == "update" {
                DispatchQueue.main.async {
                    self?.get_todays_menu()
                }
            }
        }

        realtime?.subscribe(to: "menus") { [weak self] data in
            guard let action = data["action"] as? String else { return }
            if action == "update" || action == "create" || action == "delete" {
                DispatchQueue.main.async {
                    self?.get_menus()
                }
            }
        }
    }

    func disconnectRealtime() {
        realtime?.disconnect()
        realtime = nil
    }

    private func persistSession() {
        if let user = self.user,
           let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "user_response")
        }
    }

    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: "user_response")
    }

    func sign_out() {
        self.user = nil
        self.authToken = nil
        self.today = nil
        self.menus = []
        clearSession()
        disconnectRealtime()
    }

    func makeAuthenticatedRequest(to endpoint: String, method: String = "GET", body: Data? = nil, contentType: String? = nil, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let url = URL(string: endpoint) else {
            completion(nil, nil, NSError(domain: "Invalid URL", code: 0, userInfo: nil))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        if let ct = contentType {
            request.setValue(ct, forHTTPHeaderField: "Content-Type")
        }

        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                DispatchQueue.main.async {
                    self.sign_out()
                }
            }
            completion(data, response, error)
        }
        task.resume()
    }
    
    func getRecipes(category: String, cuisine: String, country: String, author: String, sort: String, made: Bool, search: String) {
        let filter = build_filter(category: category, cuisine: cuisine, country: country, author: author, sort: sort, made: made, search: search)
        guard let url = URL(string: "\(baseURL)/api/collections/recipes/records?page=1&perPage=150\(filter)&expand=notes%2C%20ingr_list") else { return }

        isLoading = true
        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            DispatchQueue.main.async { self.isLoading = false }
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
                            let notes = recipeData.expand.notes?.map { $0.content } ?? []
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
                output += "&sort=+ingr_num"
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
                output += "&sort=+recipe.ingr_num"
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

    
    func sign_in(username: String, password: String) {
        let requestBody = "identity=\(username)&password=\(password)".data(using: .utf8)
        makePostRequest(to: "\(baseURL)/api/collections/users/auth-with-password", with: requestBody) { data, response, error in
            if let error = error {
                print("Error: \(error)")
            } else if let data = data {
                DispatchQueue.main.async {
                    do {
                        let decoded = try JSONDecoder().decode(UserResponse.self, from: data)
                        self.user = decoded
                        self.authToken = decoded.token
                        self.persistSession()
                        self.connectRealtime()
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }
    }

    func register(username: String, password: String, passwordConfirm: String, email: String, name: String, completion: @escaping (Bool, String?) -> Void) {
        let body: [String: Any] = [
            "username": username,
            "password": password,
            "passwordConfirm": passwordConfirm,
            "email": email,
            "name": name
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false, "Failed to encode request")
            return
        }

        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/users/records", method: "POST", body: jsonData, contentType: "application/json") { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(false, error.localizedDescription) }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(false, "No response") }
                return
            }
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                DispatchQueue.main.async {
                    self.sign_in(username: username, password: password)
                    completion(true, nil)
                }
            } else {
                let msg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Registration failed"
                DispatchQueue.main.async { completion(false, msg) }
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
    
    func get_todays_menu() {
        guard let userId = self.user?.record.id else { return }
        guard let url = URL(string: "\(baseURL)/api/collections/menus/records?page=1&perPage=1&filter=user%3D%22\(userId)%22%20%26%26%20today%3DTrue&expand=recipes%2Crecipes.notes%2Crecipes.ingr_list%2C%20grocery_list") else { return }
        isLoading = true
        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            DispatchQueue.main.async { self.isLoading = false }
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
                        guard !decoded_menu.items.isEmpty else {
                            self.today = nil
                            return
                        }
                        let menuItem = decoded_menu.items[0]
                        let temp_recipes = menuItem.expand.recipes.map { recipeData in
                            self.mapRecipeData(recipeData)
                        }

                        let temp_groceries = menuItem.expand.grocery_list.list.map { groc_item in
                            return GroceryItem(id: groc_item.id, checked: groc_item.checked, ingredient: Ingredient(id: groc_item.id, quantity: groc_item.quantity.value, unit: groc_item.unit, name: groc_item.ingredient))
                        }

                        self.today = MyMenu(created: menuItem.created, desc: menuItem.description, grocery_list: temp_groceries, id: menuItem.id, made: menuItem.made, notes: menuItem.notes, recipes: temp_recipes, servings: menuItem.servings, sub_recipes: menuItem.sub_recipes, title: menuItem.title, today: menuItem.today, updated: menuItem.updated)
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }

        dataTask.resume()
    }

    // MARK: - Helper

    func mapRecipeData(_ recipeData: RecipeData) -> Recipe {
        let time_in_seconds = recipeData.time_new * 60
        let ingredients = recipeData.expand.ingr_list.map { ingr in
            Ingredient(id: ingr.id, quantity: ingr.quantity, unit: ingr.unit, name: ingr.ingredient)
        }
        let notes = recipeData.expand.notes?.map { $0.content } ?? []
        return Recipe(id: recipeData.id, title: recipeData.title, description: recipeData.description, link_to_original_web_page: recipeData.url, author: recipeData.author, time_in_seconds: time_in_seconds, directions: recipeData.directions, image: recipeData.image, servings: recipeData.servings, cuisine: recipeData.cuisine, country: recipeData.country, notes: notes, ingredients: ingredients, category: recipeData.category, made: recipeData.made, favorite: recipeData.favorite)
    }

    static func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 && minutes > 0 {
            return "\(hours) hr \(minutes) min"
        } else if hours > 0 {
            return "\(hours) hr"
        } else {
            return "\(minutes) min"
        }
    }

    // MARK: - Recipe Methods

    func save_recipe(recipe: [String: Any], completion: @escaping (Bool, String?) -> Void) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: recipe) else {
            completion(false, "Failed to encode recipe")
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/save_recipe", method: "POST", body: jsonData, contentType: "application/json") { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(false, error.localizedDescription) }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let msg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Save failed"
                DispatchQueue.main.async { completion(false, msg) }
                return
            }
            DispatchQueue.main.async { completion(true, nil) }
        }
    }

    func update_recipe(id: String, fields: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: fields) else {
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/recipes/records/\(id)", method: "PATCH", body: jsonData, contentType: "application/json") { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async { completion(true) }
        }
    }

    func delete_recipe(id: String, completion: @escaping (Bool) -> Void) {
        let body: [String: Any] = ["id": id]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/delete_recipe", method: "POST", body: jsonData, contentType: "application/json") { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async {
                self.recipes.removeAll { $0.id == id }
                completion(true)
            }
        }
    }

    func toggle_favorite(recipeId: String, value: Bool, completion: @escaping (Bool) -> Void) {
        update_recipe(id: recipeId, fields: ["favorite": value]) { success in
            if success {
                if let idx = self.recipes.firstIndex(where: { $0.id == recipeId }) {
                    self.recipes[idx].favorite = value
                }
            }
            completion(success)
        }
    }

    func toggle_made(recipeId: String, value: Bool, completion: @escaping (Bool) -> Void) {
        update_recipe(id: recipeId, fields: ["made": value]) { success in
            if success {
                if let idx = self.recipes.firstIndex(where: { $0.id == recipeId }) {
                    self.recipes[idx].made = value
                }
                if value {
                    let logBody: [String: Any] = ["recipe": recipeId, "user": self.user?.record.id ?? ""]
                    guard let logData = try? JSONSerialization.data(withJSONObject: logBody) else { return }
                    self.makeAuthenticatedRequest(to: "\(self.baseURL)/api/collections/recipe_log/records", method: "POST", body: logData, contentType: "application/json") { _, _, _ in }
                }
            }
            completion(success)
        }
    }

    func copy_recipe(recipeId: String, completion: @escaping (Bool) -> Void) {
        let body: [String: Any] = ["id": recipeId]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/copy", method: "POST", body: jsonData, contentType: "application/json") { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async { completion(true) }
        }
    }

    func scrape_recipe(url: String, completion: @escaping ([String: Any]?) -> Void) {
        let body: [String: Any] = ["url": url]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(nil)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/scrape", method: "POST", body: jsonData, contentType: "application/json") { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(json) }
        }
    }

    func upload_image(imageData: Data, completion: @escaping (String?) -> Void) {
        let boundary = UUID().uuidString
        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"recipe.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/photos/records", method: "POST", body: body, contentType: "multipart/form-data; boundary=\(boundary)") { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let photoId = json["id"] as? String else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(photoId) }
        }
    }

    // MARK: - Menu Methods

    func get_menus() {
        guard let userId = self.user?.record.id else { return }
        isLoading = true
        let urlStr = "\(baseURL)/api/collections/menus/records?page=1&perPage=100&filter=user%3D%22\(userId)%22&sort=-created&expand=recipes%2Crecipes.ingr_list%2Crecipes.notes%2Cgrocery_list"
        makeAuthenticatedRequest(to: urlStr) { data, response, error in
            DispatchQueue.main.async { self.isLoading = false }
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }
            DispatchQueue.main.async {
                do {
                    let decoded = try JSONDecoder().decode(TodaysResponse.self, from: data)
                    self.menus = decoded.items.map { menuItem in
                        let temp_recipes = menuItem.expand.recipes.map { self.mapRecipeData($0) }
                        let temp_groceries = menuItem.expand.grocery_list.list.map { groc_item in
                            GroceryItem(id: groc_item.id, checked: groc_item.checked, ingredient: Ingredient(id: groc_item.id, quantity: groc_item.quantity.value, unit: groc_item.unit, name: groc_item.ingredient))
                        }
                        return MyMenu(created: menuItem.created, desc: menuItem.description, grocery_list: temp_groceries, id: menuItem.id, made: menuItem.made, notes: menuItem.notes, recipes: temp_recipes, servings: menuItem.servings, sub_recipes: menuItem.sub_recipes, title: menuItem.title, today: menuItem.today, updated: menuItem.updated)
                    }
                } catch {
                    print("Error decoding menus: ", error)
                }
            }
        }
    }

    func create_menu(title: String, recipeIds: [String], servings: [String: String], completion: @escaping (Bool) -> Void) {
        guard let userId = self.user?.record.id else {
            completion(false)
            return
        }
        let body: [String: Any] = [
            "title": title,
            "recipes": recipeIds,
            "servings": servings,
            "user": userId,
            "today": false,
            "made": [String: Bool](),
            "sub_recipes": [String: [Any]](),
            "notes": "",
            "description": ""
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/menus/records", method: "POST", body: jsonData, contentType: "application/json") { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async {
                self.get_menus()
                completion(true)
            }
        }
    }

    func update_menu(id: String, fields: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: fields) else {
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/menus/records/\(id)", method: "PATCH", body: jsonData, contentType: "application/json") { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async { completion(true) }
        }
    }

    func delete_menu(id: String, completion: @escaping (Bool) -> Void) {
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/menus/records/\(id)", method: "DELETE") { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async {
                self.menus.removeAll { $0.id == id }
                completion(true)
            }
        }
    }

    func set_today_menu(menuId: String, completion: @escaping (Bool) -> Void) {
        // Unset current today menu first
        if let currentToday = self.menus.first(where: { $0.today }) {
            update_menu(id: currentToday.id, fields: ["today": false]) { _ in }
        }
        // Set new today
        update_menu(id: menuId, fields: ["today": true]) { success in
            if success {
                self.get_todays_menu()
                self.get_menus()

                // Create menu_log
                let logBody: [String: Any] = ["menu": menuId, "user": self.user?.record.id ?? ""]
                if let logData = try? JSONSerialization.data(withJSONObject: logBody) {
                    self.makeAuthenticatedRequest(to: "\(self.baseURL)/api/collections/menu_log/records", method: "POST", body: logData, contentType: "application/json") { _, _, _ in }
                }
            }
            completion(success)
        }
    }

    // MARK: - Grocery Methods

    func create_grocery_list(menuId: String, items: [[String: Any]], completion: @escaping (Bool) -> Void) {
        let body: [String: Any] = [
            "menu": menuId,
            "list": items,
            "active": true
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/grocery_lists/records", method: "POST", body: jsonData, contentType: "application/json") { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let groceryListId = json["id"] as? String else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            // Link grocery list to menu
            self.update_menu(id: menuId, fields: ["grocery_list": groceryListId]) { success in
                completion(success)
            }
        }
    }

    func update_grocery_item(menuId: String, itemId: String, checked: Bool, completion: @escaping (Bool) -> Void) {
        // Grocery items are embedded in the grocery_list record's `list` array,
        // so we need to fetch the grocery list, update the item, and PATCH back
        guard let menu = menus.first(where: { $0.id == menuId }) ?? (today?.id == menuId ? today : nil) else {
            completion(false)
            return
        }
        var updatedList = menu.grocery_list
        if let idx = updatedList.firstIndex(where: { $0.id == itemId }) {
            updatedList[idx].checked = checked
        }
        completion(true)
    }

    // MARK: - Notes Methods

    func create_note(content: String, recipeId: String, completion: @escaping (Bool) -> Void) {
        let body: [String: Any] = ["content": content]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/notes/records", method: "POST", body: jsonData, contentType: "application/json") { data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let noteId = json["id"] as? String else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            // Link note to recipe via notes+ (append)
            self.makeAuthenticatedRequest(to: "\(self.baseURL)/api/collections/recipes/records/\(recipeId)", method: "PATCH", body: try? JSONSerialization.data(withJSONObject: ["notes+": [noteId]]), contentType: "application/json") { _, _, _ in
                DispatchQueue.main.async { completion(true) }
            }
        }
    }

    func update_note(id: String, content: String, completion: @escaping (Bool) -> Void) {
        let body: [String: Any] = ["content": content]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/notes/records/\(id)", method: "PATCH", body: jsonData, contentType: "application/json") { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async { completion(true) }
        }
    }

    func delete_note(id: String, completion: @escaping (Bool) -> Void) {
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/notes/records/\(id)", method: "DELETE") { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async { completion(true) }
        }
    }
}

