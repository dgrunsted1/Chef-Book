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
    var items: [RecipeData]
}

struct RecipeData: Decodable {
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
