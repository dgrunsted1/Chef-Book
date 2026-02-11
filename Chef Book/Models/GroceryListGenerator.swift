//
//  GroceryListGenerator.swift
//  Chef Book
//

import Foundation

struct GroceryListGenerator {

    struct MergedItem: Identifiable {
        let id = UUID()
        var name: String
        var quantity: Double
        var unit: String
    }

    static func generate(recipes: [Recipe], servings: [String: String]) -> [MergedItem] {
        var items: [MergedItem] = []

        for recipe in recipes {
            let multiplier = servingMultiplier(for: recipe, servings: servings)

            for ingredient in recipe.ingredients {
                let normalizedName = normalize(ingredient.name)
                let adjustedQty = ingredient.quantity * multiplier

                if let idx = findSimilar(normalizedName, in: items) {
                    // Merge: add quantities if units match
                    if items[idx].unit.lowercased() == ingredient.unit.lowercased() || items[idx].unit.isEmpty || ingredient.unit.isEmpty {
                        items[idx].quantity += adjustedQty
                        if items[idx].unit.isEmpty && !ingredient.unit.isEmpty {
                            items[idx].unit = ingredient.unit
                        }
                    } else {
                        // Different units, add as separate item
                        items.append(MergedItem(name: normalizedName, quantity: adjustedQty, unit: ingredient.unit))
                    }
                } else {
                    items.append(MergedItem(name: normalizedName, quantity: adjustedQty, unit: ingredient.unit))
                }
            }
        }

        return items.sorted { $0.name < $1.name }
    }

    private static func servingMultiplier(for recipe: Recipe, servings: [String: String]) -> Double {
        guard let targetStr = servings[recipe.id],
              let target = Double(targetStr),
              let original = Double(recipe.servings),
              original > 0 else { return 1.0 }
        return target / original
    }

    private static func normalize(_ name: String) -> String {
        var result = name.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove common descriptors
        let descriptors = ["fresh", "dried", "ground", "chopped", "minced", "diced",
                          "sliced", "whole", "frozen", "canned", "organic"]
        for desc in descriptors {
            result = result.replacingOccurrences(of: "\(desc) ", with: "")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func findSimilar(_ name: String, in items: [MergedItem]) -> Int? {
        for (index, item) in items.enumerated() {
            if item.name == name { return index }
            let similarity = levenshteinSimilarity(item.name, name)
            if similarity >= 0.8 { return index }
        }
        return nil
    }

    private static func levenshteinSimilarity(_ s1: String, _ s2: String) -> Double {
        let a = Array(s1)
        let b = Array(s2)
        let m = a.count
        let n = b.count

        if m == 0 && n == 0 { return 1.0 }
        if m == 0 || n == 0 { return 0.0 }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }

        let maxLen = max(m, n)
        return 1.0 - Double(matrix[m][n]) / Double(maxLen)
    }

    static func toGroceryDicts(_ items: [MergedItem]) -> [[String: Any]] {
        return items.map { item in
            [
                "id": UUID().uuidString,
                "checked": false,
                "ingredient": item.name,
                "quantity": item.quantity,
                "unit": item.unit
            ]
        }
    }
}
