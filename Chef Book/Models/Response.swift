//
//  Response.swift
//  Chef Book
//
//  Created by David Grunsted on 6/26/24.
//

import Foundation

struct Response: Decodable {
    var page: Int
    var perPage: Int
    var totalItems: Int
    var totalPages: Int
    var items: [RecipeData]
}

struct RecipeData: Decodable, Identifiable {
    var author: String
    var category: String
    let collectionId: String
    let collectionName: String
    var country: String
    var created: String
    var cuisine: String
    var description: String
    var directions: [String]
    var expand: Expand
    var favorite: Bool
    let id: String
    var image: String
    var ingr_list: [String]
    var ingr_num: Int
    var made: Bool
    var notes: [String]
    var servings: String
    var time: String
    var time_new: Int
    var title: String
    var updated: String
    var url: String
    var url_id: String
    var user: String
}

struct Expand: Decodable {
    var ingr_list: [IngredientData]
    var notes: [NotesData]!
}

struct NotesData: Decodable {
    var collectionId: String
    var collectionName: String
    var content: String
    var created: String
    var id: String
    var updated: String
}

struct IngredientData: Decodable {
    let collectionId: String
    let collectionName: String
    let created: String
    let id: String
    var ingredient: String
    var quantity: Double
    var recipe: [String]
    var symbol: String
    var unit: String
    var unitPlural: String
    var updated: String
}

struct CatResponse: Decodable {
    var page: Int
    var perPage: Int
    var totalItems: Int
    var items: [CatData]
}

struct CatData: Decodable {
    var collectionId: String
    var collectionName: String
    var id: String
}

struct IngredientResponse: Decodable {
    var page: Int
    var perPage: Int
    var totalItems: Int
    var items: [IngredientRecipeData]
}

struct ExpandIngr: Decodable {
    var recipe: [RecipeData]
}

struct IngredientRecipeData: Decodable {
    let collectionId: String
    let collectionName: String
    let created: String
    let id: String
    var ingredient: String
    var quantity: Double
    var recipe: [String]
    var symbol: String
    var unit: String
    var unitPlural: String
    var updated: String
    var expand: ExpandIngr
}

struct UserResponse: Decodable {
    var record: User
    var token: String
}

struct TodaysResponse: Decodable {
    var page: Int
    var perPage: Int
    var totalItems: Int
    var totalPages: Int
    var items: [MenuItem]
}

struct MenuItem: Decodable {
    var collectionId: String
    var collectionName: String
    var created: String
    var description: String
    var expand: TodayExpand
    var grocery_list: String
    var id: String
    var made: [String: Bool]
    var notes: String
    var recipes: [String]
    var servings: [String: String]
    var sub_recipes: [String:[SubRecipe]]
    var title: String
    var today: Bool
    var updated: String
    var user: String
}

struct SubRecipe: Decodable {
    var ingr_id: String?
    var recipe_id: String?
}

struct TodayExpand: Decodable {
    var recipes: [RecipeData]
    var grocery_list: GroceryList
}

struct GroceryList: Decodable, Identifiable {
    var active: Bool
    var collectionId: String
    var collectionName: String
    var created: String
    var id: String
    var list: [GroceryItemResponse]
    var menu: String
    var updated: String
}

struct GroceryItemResponse: Decodable {
    var checked: Bool
    var collectionId: String
    var collectionName: String
    var created: String
    var id: String
    var ingredient: String
    var quantity: QuantityValue
    var recipe: [String]
    var symbol: String
    var unit: String
    var unitPlural: String
    var updated: String
}

struct QuantityValue: Decodable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            if let doubleValue = Double(stringValue) {
                value = doubleValue
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid quantity value")
            }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid quantity value")
        }
    }
}
