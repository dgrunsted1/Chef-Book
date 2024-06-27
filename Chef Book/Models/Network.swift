//
//  Network.swift
//  Chef Book
//
//  Created by David Grunsted on 6/25/24.
//

import SwiftUI

class Network: ObservableObject {
    @Published var recipes: [Recipe] = []
    
    func getRecipes() {
        guard let url = URL(string: "https://db.ivebeenwastingtime.com/api/collections/recipes/records?page=1&perPage=30&filter=made%3Dtrue&expand=ingr_list&sort=-created") else { fatalError("Missing URL") }

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
                                return Ingredient(quantity: ingr.quantity, unit: ingr.unit, name: ingr.ingredient)
                            }
                            return Recipe(id: recipeData.id, title: recipeData.title, description: recipeData.description, link_to_original_web_page: recipeData.url, author: recipeData.author, time_in_seconds: time_in_seconds, directions: recipeData.directions, image: recipeData.image, servings: recipeData.servings, cuisine: recipeData.cuisine, country: recipeData.country, notes: recipeData.notes, ingredients: ingredients, category: recipeData.category, made: recipeData.made, favorite: recipeData.favorite)
                        }
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }

        dataTask.resume()
    }
}
