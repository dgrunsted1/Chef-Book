//
//  Ingredient.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import Foundation


struct Ingredient: Decodable, Hashable, Identifiable {
    let id: String
    var quantity: Double
    var unit: String
    var name: String
}

extension Ingredient {
    func toString() -> String {
        var ingredientString = ""
        
        if quantity != 0 {
            ingredientString += "\(String(format: "%g", quantity))"
        }
        
        if !unit.isEmpty {
            ingredientString += " \(unit)"
        }
        
        ingredientString += " \(name)"
        
        return String(ingredientString.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
