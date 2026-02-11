//
//  IngredientParser.swift
//  Chef Book
//

import Foundation

struct IngredientParser {
    // Common units for matching
    private static let units = [
        "cup", "cups", "tablespoon", "tablespoons", "tbsp", "teaspoon", "teaspoons", "tsp",
        "ounce", "ounces", "oz", "pound", "pounds", "lb", "lbs",
        "gram", "grams", "g", "kilogram", "kilograms", "kg",
        "ml", "milliliter", "milliliters", "liter", "liters", "l",
        "gallon", "gallons", "gal", "quart", "quarts", "qt",
        "pint", "pints", "pt", "stick", "sticks",
        "clove", "cloves", "head", "heads", "bunch", "bunches",
        "slice", "slices", "piece", "pieces", "can", "cans",
        "package", "packages", "pkg", "bag", "bags",
        "pinch", "dash", "handful", "sprig", "sprigs",
        "large", "medium", "small"
    ]

    // Fraction map
    private static let fractions: [String: Double] = [
        "¼": 0.25, "½": 0.5, "¾": 0.75,
        "⅓": 0.333, "⅔": 0.667,
        "⅛": 0.125, "⅜": 0.375, "⅝": 0.625, "⅞": 0.875
    ]

    static func parse(_ text: String) -> EditableIngredient {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return EditableIngredient() }

        var remaining = trimmed
        var quantity: Double = 0

        // Try to parse quantity at the beginning
        // Pattern: number (potentially with fraction)
        let numberPattern = #"^(\d+\s*[½¼¾⅓⅔⅛⅜⅝⅞]|\d+\/\d+|\d+\.?\d*|[½¼¾⅓⅔⅛⅜⅝⅞])\s*"#
        if let range = remaining.range(of: numberPattern, options: .regularExpression) {
            let match = String(remaining[range]).trimmingCharacters(in: .whitespaces)
            remaining = String(remaining[range.upperBound...]).trimmingCharacters(in: .whitespaces)

            // Check for unicode fractions
            var found = false
            for (frac, val) in fractions {
                if match.contains(frac) {
                    let wholePart = match.replacingOccurrences(of: frac, with: "").trimmingCharacters(in: .whitespaces)
                    let wholeNum = Double(wholePart) ?? 0
                    quantity = wholeNum + val
                    found = true
                    break
                }
            }

            if !found {
                // Check for slash fraction like "1/2"
                if match.contains("/") {
                    let parts = match.split(separator: "/")
                    if parts.count == 2, let num = Double(parts[0].trimmingCharacters(in: .whitespaces)),
                       let den = Double(parts[1].trimmingCharacters(in: .whitespaces)), den != 0 {
                        quantity = num / den
                    }
                } else {
                    quantity = Double(match) ?? 0
                }
            }
        }

        // Try to parse unit
        var unit = ""
        let words = remaining.split(separator: " ", maxSplits: 1)
        if let firstWord = words.first {
            let lower = String(firstWord).lowercased()
            if units.contains(lower) {
                unit = lower
                remaining = words.count > 1 ? String(words[1]) : ""
            }
        }

        // Normalize unit to singular
        let singularMap: [String: String] = [
            "cups": "cup", "tablespoons": "tablespoon", "teaspoons": "teaspoon",
            "ounces": "ounce", "pounds": "pound", "grams": "gram",
            "kilograms": "kilogram", "milliliters": "milliliter", "liters": "liter",
            "gallons": "gallon", "quarts": "quart", "pints": "pint",
            "sticks": "stick", "cloves": "clove", "heads": "head",
            "bunches": "bunch", "slices": "slice", "pieces": "piece",
            "cans": "can", "packages": "package", "bags": "bag", "sprigs": "sprig",
            "lbs": "lb"
        ]
        if let singular = singularMap[unit] {
            unit = singular
        }

        return EditableIngredient(
            quantity: quantity == 0 ? "" : String(format: "%g", quantity),
            unit: unit,
            name: remaining.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
