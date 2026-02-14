//
//  Menu.swift
//  Chef Book
//
//  Created by David Grunsted on 7/8/24.
//

import Foundation
import SwiftData

//@Model
struct MyMenu: Identifiable {
    var created: String
    var desc: String
    var grocery_list: [GroceryItem]
    var grocery_list_id: String
    var id: String
    var made: [String: Bool]
    var notes: String
    var recipes: [Recipe]
    var servings: [String: String]
    var sub_recipes: [String:[SubRecipe]]
    var title: String
    var today: Bool
    var updated: String
}

struct GroceryItem: Identifiable {
    var id: String
    var checked: Bool
    var ingredient: Ingredient
}
