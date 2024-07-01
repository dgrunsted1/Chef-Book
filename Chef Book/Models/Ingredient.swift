//
//  Ingredient.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import Foundation


struct Ingredient: Decodable, Hashable {
    let id: String
    var quantity: Double
    var unit: String
    var name: String
}
