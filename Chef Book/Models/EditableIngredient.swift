//
//  EditableIngredient.swift
//  Chef Book
//

import Foundation

class EditableIngredient: Identifiable, ObservableObject {
    let id = UUID()
    @Published var quantity: String
    @Published var unit: String
    @Published var name: String

    init(quantity: String = "", unit: String = "", name: String = "") {
        self.quantity = quantity
        self.unit = unit
        self.name = name
    }

    init(from ingredient: Ingredient) {
        self.quantity = ingredient.quantity == 0 ? "" : String(format: "%g", ingredient.quantity)
        self.unit = ingredient.unit
        self.name = ingredient.name
    }

    func toDict() -> [String: Any] {
        return [
            "quantity": Double(quantity) ?? 0,
            "unit": unit,
            "ingredient": name
        ]
    }
}
