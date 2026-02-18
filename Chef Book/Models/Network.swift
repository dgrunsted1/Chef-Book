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
    var recipeDetailCache: [String: Recipe] = [:]

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
            get_todays_menu()
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
                    self?.getRecipes()
                }
            }
        }

        realtime?.subscribe(to: "grocery_lists") { [weak self] data in
            guard let action = data["action"] as? String else { return }
            if action == "update" || action == "create" || action == "delete" {
                DispatchQueue.main.async {
                    self?.get_todays_menu()
                }
            }
        }

        realtime?.subscribe(to: "grocery_items") { [weak self] data in
            guard let action = data["action"] as? String else { return }
            if action == "update" || action == "create" || action == "delete" {
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
    
    func getRecipes(categories: [String] = [], cuisines: [String] = [], countries: [String] = [], authors: [String] = [], sort: String = "Most Recent", search: String = "") {
        guard let url = URL(string: "\(baseURL)/api/search") else { return }

        isLoading = true

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "search_val": search,
            "sort_val": sort,
            "page": 1,
            "per_page": 200,
            "selected_categories": categories,
            "selected_countries": countries,
            "selected_cuisines": cuisines,
            "selected_authors": authors
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                  let data = data else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            DispatchQueue.main.async {
                do {
                    let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
                    // Build lookup of existing detail-loaded recipes to preserve them
                    let existingById = Dictionary(uniqueKeysWithValues: self.recipes.filter { $0.isDetailLoaded }.map { ($0.id, $0) })

                    self.recipes = decoded.recipes.map { r in
                        // If we already have a detail-loaded version, keep it but update summary fields
                        if var existing = existingById[r.id] {
                            existing.title = r.title
                            existing.author = r.author
                            existing.image = r.image
                            existing.category = r.category
                            existing.cuisine = r.cuisine
                            existing.country = r.country
                            existing.servings = r.servings
                            return existing
                        }
                        return Recipe(
                            id: r.id,
                            title: r.title,
                            description: "",
                            link_to_original_web_page: "",
                            author: r.author,
                            time_in_seconds: 0,
                            time_display: r.time,
                            directions: [],
                            image: r.image,
                            servings: r.servings,
                            cuisine: r.cuisine,
                            country: r.country,
                            notes: [],
                            ingredients: [],
                            category: r.category,
                            made: false,
                            favorite: false,
                            url_id: r.url_id,
                            ingredientCount: Int(r.ingr_list) ?? 0,
                            directionCount: Int(r.directions) ?? 0,
                            user: r.user,
                            isDetailLoaded: false
                        )
                    }
                    self.categories = decoded.categories.map { $0.id }
                    self.cuisines = decoded.cuisines.map { $0.id }
                    self.countries = decoded.countries.map { $0.id }
                    self.authors = decoded.authors.map { $0.id }
                } catch let error {
                    print("Error decoding: ", error)
                }
                self.isLoading = false
            }
        }
        dataTask.resume()
    }

    func getRecipeDetail(urlId: String, completion: @escaping (Recipe?) -> Void) {
        let encodedFilter = "url_id%3D%22\(urlId)%22"
        guard let url = URL(string: "\(baseURL)/api/collections/recipes/records?filter=\(encodedFilter)&expand=notes%2Cingr_list") else {
            completion(nil)
            return
        }

        let dataTask = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            if let error = error {
                print("Recipe detail error: ", error)
                DispatchQueue.main.async { completion(nil) }
                return
            }
            guard let response = response as? HTTPURLResponse, response.statusCode == 200,
                  let data = data else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async {
                do {
                    let decoded = try JSONDecoder().decode(Response.self, from: data)
                    guard let recipeData = decoded.items.first else {
                        completion(nil)
                        return
                    }
                    let time_in_seconds = recipeData.time_new * 60
                    let ingredients = recipeData.expand.ingr_list.map { ingr in
                        Ingredient(id: ingr.id, quantity: ingr.quantity, unit: ingr.unit, name: ingr.ingredient)
                    }
                    let notes = recipeData.expand.notes?.map { RecipeNote(id: $0.id, content: $0.content) } ?? []
                    let recipe = Recipe(
                        id: recipeData.id,
                        title: recipeData.title,
                        description: recipeData.description,
                        link_to_original_web_page: recipeData.url,
                        author: recipeData.author,
                        time_in_seconds: time_in_seconds,
                        time_display: recipeData.time,
                        directions: recipeData.directions,
                        image: recipeData.image,
                        servings: recipeData.servings,
                        cuisine: recipeData.cuisine,
                        country: recipeData.country,
                        notes: notes,
                        ingredients: ingredients,
                        category: recipeData.category,
                        made: recipeData.made,
                        favorite: recipeData.favorite,
                        url_id: recipeData.url_id,
                        user: recipeData.user
                    )
                    self.recipeDetailCache[recipe.id] = recipe
                    completion(recipe)
                } catch let error {
                    print("Error decoding recipe detail: ", error)
                    completion(nil)
                }
            }
        }
        dataTask.resume()
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
        guard let userId = self.user?.record.id else {
            return
        }
        let endpoint = "\(baseURL)/api/collections/menus/records?page=1&perPage=1&filter=user%3D%22\(userId)%22%20%26%26%20today%3DTrue&expand=recipes%2Crecipes.notes%2Crecipes.ingr_list%2Cgrocery_list%2Cgrocery_list.items"
        isLoading = true

        makeAuthenticatedRequest(to: endpoint) { (data, response, error) in
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

                        let temp_groceries = (menuItem.expand.grocery_list?.expandedItems ?? []).map { groc_item in
                            return GroceryItem(id: groc_item.id, checked: groc_item.checked, ingredient: Ingredient(id: groc_item.id, quantity: groc_item.qty, unit: groc_item.unit, name: groc_item.name))
                        }

                        self.today = MyMenu(created: menuItem.created, desc: menuItem.description, grocery_list: temp_groceries, grocery_list_id: menuItem.expand.grocery_list?.id ?? menuItem.grocery_list, id: menuItem.id, made: menuItem.made, notes: menuItem.notes, recipes: temp_recipes, servings: menuItem.servings, sub_recipes: menuItem.sub_recipes ?? [:], title: menuItem.title, today: menuItem.today, updated: menuItem.updated)
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }
    }

    // MARK: - Helper

    func mapRecipeData(_ recipeData: RecipeData) -> Recipe {
        let time_in_seconds = recipeData.time_new * 60
        let ingredients = recipeData.expand.ingr_list.map { ingr in
            Ingredient(id: ingr.id, quantity: ingr.quantity, unit: ingr.unit, name: ingr.ingredient)
        }
        let notes = recipeData.expand.notes?.map { RecipeNote(id: $0.id, content: $0.content) } ?? []
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
            print("[update_recipe] Failed to serialize fields: \(fields)")
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/recipes/records/\(id)", method: "PATCH", body: jsonData, contentType: "application/json") { data, response, error in
            if let error = error {
                print("[update_recipe] Network error: \(error.localizedDescription)")
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
                print("[update_recipe] Failed (\(statusCode)) for id=\(id) fields=\(fields.keys): \(body)")
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
                if let idx = self.today?.recipes.firstIndex(where: { $0.id == recipeId }) {
                    self.today?.recipes[idx].favorite = value
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
                if let idx = self.today?.recipes.firstIndex(where: { $0.id == recipeId }) {
                    self.today?.recipes[idx].made = value
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

    func toggle_menu_made(recipeId: String, value: Bool, completion: @escaping (Bool) -> Void) {
        guard let menuId = self.today?.id else {
            completion(false)
            return
        }
        // Update local state
        self.today?.made[recipeId] = value

        // PATCH the menus collection with updated made dictionary
        let updatedMade = self.today?.made ?? [:]
        update_menu(id: menuId, fields: ["made": updatedMade]) { success in
            if success && value {
                // When toggling ON: also set recipe.made = true globally
                if let idx = self.recipes.firstIndex(where: { $0.id == recipeId }), !self.recipes[idx].made {
                    self.recipes[idx].made = true
                }
                if let idx = self.today?.recipes.firstIndex(where: { $0.id == recipeId }), !(self.today?.recipes[idx].made ?? false) {
                    self.today?.recipes[idx].made = true
                }
                self.update_recipe(id: recipeId, fields: ["made": true]) { _ in }

                // Create recipe_log entry
                let logBody: [String: Any] = ["recipe": recipeId, "user": self.user?.record.id ?? ""]
                if let logData = try? JSONSerialization.data(withJSONObject: logBody) {
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
                        let temp_groceries = (menuItem.expand.grocery_list?.expandedItems ?? []).map { groc_item in
                            GroceryItem(id: groc_item.id, checked: groc_item.checked, ingredient: Ingredient(id: groc_item.id, quantity: groc_item.qty, unit: groc_item.unit, name: groc_item.name))
                        }
                        return MyMenu(created: menuItem.created, desc: menuItem.description, grocery_list: temp_groceries, grocery_list_id: menuItem.expand.grocery_list?.id ?? menuItem.grocery_list, id: menuItem.id, made: menuItem.made, notes: menuItem.notes, recipes: temp_recipes, servings: menuItem.servings, sub_recipes: menuItem.sub_recipes ?? [:], title: menuItem.title, today: menuItem.today, updated: menuItem.updated)
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

    func toggle_grocery_item(itemId: String, checked: Bool, completion: @escaping (Bool) -> Void) {
        let body: [String: Any] = ["checked": checked]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/grocery_items/records/\(itemId)", method: "PATCH", body: jsonData, contentType: "application/json") { [weak self] data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async {
                // Update local state optimistically
                if let idx = self?.today?.grocery_list.firstIndex(where: { $0.id == itemId }) {
                    self?.today?.grocery_list[idx].checked = checked
                }
                completion(true)
            }
        }
    }

    func add_grocery_item(groceryListId: String, name: String, qty: Double, unit: String, completion: @escaping (Bool) -> Void) {
        let body: [String: Any] = ["name": name, "qty": qty, "unit": unit, "checked": false, "active": true]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/grocery_items/records", method: "POST", body: jsonData, contentType: "application/json") { [weak self] data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let newItemId = json["id"] as? String else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            // Link to grocery list
            guard let linkData = try? JSONSerialization.data(withJSONObject: ["items+": newItemId]) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            self?.makeAuthenticatedRequest(to: "\(self?.baseURL ?? "")/api/collections/grocery_lists/records/\(groceryListId)", method: "PATCH", body: linkData, contentType: "application/json") { [weak self] _, resp, _ in
                guard let httpResp = resp as? HTTPURLResponse,
                      (200...299).contains(httpResp.statusCode) else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }
                DispatchQueue.main.async {
                    self?.get_todays_menu()
                    completion(true)
                }
            }
        }
    }

    func edit_grocery_item(itemId: String, name: String, qty: Double, unit: String, completion: @escaping (Bool) -> Void) {
        let body: [String: Any] = ["name": name, "qty": qty, "unit": unit]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/grocery_items/records/\(itemId)", method: "PATCH", body: jsonData, contentType: "application/json") { [weak self] data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async {
                self?.get_todays_menu()
                completion(true)
            }
        }
    }

    func delete_grocery_item(itemId: String, groceryListId: String, completion: @escaping (Bool) -> Void) {
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/grocery_items/records/\(itemId)", method: "DELETE") { [weak self] data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            // Unlink from grocery list
            guard let unlinkData = try? JSONSerialization.data(withJSONObject: ["items-": itemId]) else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            self?.makeAuthenticatedRequest(to: "\(self?.baseURL ?? "")/api/collections/grocery_lists/records/\(groceryListId)", method: "PATCH", body: unlinkData, contentType: "application/json") { [weak self] _, resp, _ in
                DispatchQueue.main.async {
                    self?.get_todays_menu()
                    completion(true)
                }
            }
        }
    }

    func reset_grocery_list(menuId: String, completion: @escaping (Bool) -> Void) {
        guard let menu = (today?.id == menuId ? today : menus.first(where: { $0.id == menuId })) else {
            completion(false)
            return
        }

        let oldGroceryListId = menu.grocery_list_id

        // Collect ingredients from all recipes in the menu
        var items: [[String: Any]] = []
        for recipe in menu.recipes {
            for ingredient in recipe.ingredients {
                items.append([
                    "name": ingredient.name,
                    "qty": ingredient.quantity,
                    "unit": ingredient.unit,
                    "checked": false,
                    "active": true
                ])
            }
        }

        // Delete old grocery items first
        let oldItemIds = menu.grocery_list.map { $0.id }
        let deleteGroup = DispatchGroup()
        for itemId in oldItemIds {
            deleteGroup.enter()
            makeAuthenticatedRequest(to: "\(baseURL)/api/collections/grocery_items/records/\(itemId)", method: "DELETE") { _, _, _ in
                deleteGroup.leave()
            }
        }

        deleteGroup.notify(queue: .global()) { [weak self] in
            guard let self = self else { return }

            // Delete old grocery list if it exists
            if !oldGroceryListId.isEmpty {
                self.makeAuthenticatedRequest(to: "\(self.baseURL)/api/collections/grocery_lists/records/\(oldGroceryListId)", method: "DELETE") { _, _, _ in }
            }

            // Create new grocery items
            var newItemIds: [String] = []
            let createGroup = DispatchGroup()
            for item in items {
                createGroup.enter()
                guard let jsonData = try? JSONSerialization.data(withJSONObject: item) else {
                    createGroup.leave()
                    continue
                }
                self.makeAuthenticatedRequest(to: "\(self.baseURL)/api/collections/grocery_items/records", method: "POST", body: jsonData, contentType: "application/json") { data, response, error in
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let id = json["id"] as? String {
                        newItemIds.append(id)
                    }
                    createGroup.leave()
                }
            }

            createGroup.notify(queue: .global()) {
                // Create new grocery list with all items
                let listBody: [String: Any] = [
                    "menu": menuId,
                    "items": newItemIds,
                    "active": true
                ]
                guard let listData = try? JSONSerialization.data(withJSONObject: listBody) else {
                    DispatchQueue.main.async { completion(false) }
                    return
                }
                self.makeAuthenticatedRequest(to: "\(self.baseURL)/api/collections/grocery_lists/records", method: "POST", body: listData, contentType: "application/json") { data, response, error in
                    guard let data = data,
                          let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode),
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let newListId = json["id"] as? String else {
                        DispatchQueue.main.async { completion(false) }
                        return
                    }
                    // Link new grocery list to menu
                    self.update_menu(id: menuId, fields: ["grocery_list": newListId]) { success in
                        DispatchQueue.main.async {
                            self.get_todays_menu()
                            completion(success)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notes Methods

    func create_note(content: String, recipeId: String, completion: @escaping (String?) -> Void) {
        let body: [String: Any] = ["content": content]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("[create_note] Failed to serialize body")
            completion(nil)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/notes/records", method: "POST", body: jsonData, contentType: "application/json") { data, response, error in
            if let error = error {
                print("[create_note] Network error: \(error.localizedDescription)")
            }
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let noteId = json["id"] as? String else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
                print("[create_note] Failed (\(statusCode)): \(body)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            // Link note to recipe via notes+ (append)
            self.makeAuthenticatedRequest(to: "\(self.baseURL)/api/collections/recipes/records/\(recipeId)", method: "PATCH", body: try? JSONSerialization.data(withJSONObject: ["notes+": [noteId]]), contentType: "application/json") { _, _, _ in
                DispatchQueue.main.async { completion(noteId) }
            }
        }
    }

    func update_note(id: String, content: String, completion: @escaping (Bool) -> Void) {
        let body: [String: Any] = ["content": content]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("[update_note] Failed to serialize body")
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/notes/records/\(id)", method: "PATCH", body: jsonData, contentType: "application/json") { data, response, error in
            if let error = error {
                print("[update_note] Network error: \(error.localizedDescription)")
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
                print("[update_note] Failed (\(statusCode)) for id=\(id): \(body)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async { completion(true) }
        }
    }

    func delete_note(id: String, completion: @escaping (Bool) -> Void) {
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/notes/records/\(id)", method: "DELETE") { data, response, error in
            if let error = error {
                print("[delete_note] Network error: \(error.localizedDescription)")
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("[delete_note] Failed (\(statusCode)) for id=\(id)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async { completion(true) }
        }
    }

    // MARK: - Ingredient CRUD

    func update_ingredient(id: String, fields: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: fields) else {
            print("[update_ingredient] Failed to serialize fields: \(fields)")
            completion(false)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/ingr_list/records/\(id)", method: "PATCH", body: jsonData, contentType: "application/json") { data, response, error in
            if let error = error {
                print("[update_ingredient] Network error: \(error.localizedDescription)")
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
                print("[update_ingredient] Failed (\(statusCode)) for id=\(id): \(body)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async { completion(true) }
        }
    }

    func create_ingredient(recipeId: String, fields: [String: Any], completion: @escaping (String?) -> Void) {
        var body = fields
        body["recipe"] = [recipeId]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            print("[create_ingredient] Failed to serialize fields: \(body)")
            completion(nil)
            return
        }
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/ingr_list/records", method: "POST", body: jsonData, contentType: "application/json") { data, response, error in
            if let error = error {
                print("[create_ingredient] Network error: \(error.localizedDescription)")
            }
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ingrId = json["id"] as? String else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
                print("[create_ingredient] Failed (\(statusCode)): \(body)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            // Link ingredient to recipe via ingr_list+ (append)
            self.makeAuthenticatedRequest(to: "\(self.baseURL)/api/collections/recipes/records/\(recipeId)", method: "PATCH", body: try? JSONSerialization.data(withJSONObject: ["ingr_list+": [ingrId]]), contentType: "application/json") { _, _, _ in
                DispatchQueue.main.async { completion(ingrId) }
            }
        }
    }

    func delete_ingredient(id: String, recipeId: String, completion: @escaping (Bool) -> Void) {
        makeAuthenticatedRequest(to: "\(baseURL)/api/collections/ingr_list/records/\(id)", method: "DELETE") { data, response, error in
            if let error = error {
                print("[delete_ingredient] Network error: \(error.localizedDescription)")
            }
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("[delete_ingredient] Failed (\(statusCode)) for id=\(id)")
                DispatchQueue.main.async { completion(false) }
                return
            }
            DispatchQueue.main.async { completion(true) }
        }
    }
}

