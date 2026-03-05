//
//  GroceryListGenerator.swift
//  Chef Book
//

import Foundation

struct GroceryListGenerator {

    struct GroceryItem: Identifiable {
        let id = UUID()
        var name: String
        var qty: Double
        var unit: String
        var checked: Bool = false
        var active: Bool = true
        var ingrIds: [String] = []
    }

    // MARK: - Main Entry Point

    static func generate(recipes: [Recipe], servings: [String: String]) -> [GroceryItem] {
        var rawItems: [GroceryItem] = []

        for recipe in recipes {
            let mult = calculateServingsMultiplier(for: recipe, servings: servings)
            for ingredient in recipe.ingredients {
                let normalizedName = normalizeItemName(ingredient.name)
                guard !normalizedName.isEmpty else { continue }
                rawItems.append(GroceryItem(
                    name: normalizedName,
                    qty: roundAmount(ingredient.quantity * mult),
                    unit: ingredient.unit,
                    ingrIds: [ingredient.id]
                ))
            }
        }

        let merged = merge(rawItems)
        let grouped = groupBySimilarity(merged)
        return grouped
    }

    // MARK: - Servings Multiplier

    private static func calculateServingsMultiplier(for recipe: Recipe, servings: [String: String]) -> Double {
        guard let targetStr = servings[recipe.id],
              let target = Double(targetStr),
              let original = Double(recipe.servings),
              original > 0 else { return 1.0 }
        return target / original
    }

    // MARK: - Name Normalization (ports ingr_to_groc.js normalizeItemName + merge_ingredients.js trim_verbs/trim_prepositions)

    static func normalizeItemName(_ name: String) -> String {
        guard !name.isEmpty else { return "" }

        var cleaned = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove parenthetical content
        cleaned = cleaned.replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)

        // Remove quotes and fractions
        cleaned = cleaned.replacingOccurrences(of: "[\"\"\"''½⅓⅔¼¾⅛⅜⅝⅞]", with: "", options: .regularExpression)

        // Remove numbers (digits and decimals)
        cleaned = cleaned.replacingOccurrences(of: "[\\d.]+", with: "", options: .regularExpression)

        // Remove common descriptors
        let descriptors = ["fresh", "freshly", "organic", "raw", "cooked", "dried", "frozen", "canned",
                           "whole", "chopped", "diced", "sliced", "ground", "boneless", "skinless",
                           "large", "medium", "small", "extra-virgin", "extra", "coarse", "fine",
                           "thick-cut", "thick", "thin", "room temperature", "chilled", "thawed",
                           "ripe", "unripe", "warm", "packed"]
        for desc in descriptors {
            cleaned = cleaned.replacingOccurrences(
                of: "\\b\(NSRegularExpression.escapedPattern(for: desc))\\b",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }

        // Remove measurements
        let measurements = ["cup", "cups", "c", "tablespoon", "tablespoons", "tbsp", "tsp",
                            "teaspoon", "teaspoons", "ounce", "ounces", "oz", "pound", "pounds",
                            "lb", "lbs", "gram", "grams", "g", "kilogram", "kg", "liter", "l",
                            "milliliter", "ml", "pint", "pints", "quart", "quarts", "gallon"]
        for measure in measurements {
            cleaned = cleaned.replacingOccurrences(
                of: "\\b\(NSRegularExpression.escapedPattern(for: measure))s?\\b",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }

        // Remove commas, semicolons, periods and everything after them
        if let range = cleaned.range(of: "[,;.].*", options: .regularExpression) {
            cleaned = String(cleaned[cleaned.startIndex..<range.lowerBound])
        }

        // Trim verbs (ports the 280+ verb list from merge_ingredients.js)
        cleaned = trimVerbs(cleaned)

        // Normalize garlic variations
        cleaned = normalizeGarlicName(cleaned)

        // Handle plurals
        if cleaned.hasSuffix("ies") {
            cleaned = String(cleaned.dropLast(3)) + "y"
        } else if cleaned.hasSuffix("s") && !cleaned.hasSuffix("ss") {
            cleaned = String(cleaned.dropLast(1))
        }

        // Final cleanup
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) : cleaned
    }

    // MARK: - Verb Trimming (ports trim_verbs from merge_ingredients.js)

    private static let cookingVerbs: [String] = [
        "acidulate", "add", "allow", "alternate", "arrange",
        "bake", "barrel", "baste", "beat", "bind", "blanch", "blend", "blister", "blow",
        "boil", "bone", "bottle", "braid", "braise", "break", "brine", "broil", "brown",
        "bruise", "brush",
        "caramelize", "carry", "carve", "chafe", "chill", "chop", "churn", "circle",
        "clarify", "clean", "coat", "coddle", "coil", "collar", "collect", "color",
        "combine", "complete", "continue", "cook", "cool", "core", "count", "coarsely",
        "cover", "crease", "crisscross", "cross", "crush", "cut",
        "decorate", "deglaze", "dice", "dilute", "discard", "dish", "dissolve", "distill",
        "dot", "drain", "dredge", "drop", "dust", "dye",
        "eat", "empty", "emulsify", "eviscerate",
        "fasten", "feathers", "filet", "fill", "fire", "fit", "flake", "flame", "flatten",
        "flavor", "flay", "flip", "fold", "force", "form", "freeze", "frost", "froth", "fry",
        "garnish", "gas", "gash", "gild", "glaze", "grate", "grease", "grill", "grind",
        "hack", "halved", "hands", "hang", "hard-boil", "heat", "hold", "hollow", "hull", "husk",
        "indent", "insert",
        "julienne",
        "keep", "knead",
        "lard", "lay", "layer", "leaven", "light", "line",
        "make", "marinate", "mash", "mask", "measure", "melt", "mince", "mix", "moisten", "mold",
        "ornament", "oven",
        "pack", "parboil", "pare", "pat", "peeled", "pick", "pickle", "pierce", "pile",
        "pinch", "pipe", "place", "plank", "plunge", "poach", "pound", "pour", "prepare",
        "preserve", "prick", "pull", "pulverize", "purée", "push", "put", "quartered",
        "reduce", "reheat", "remove", "rinse", "rise", "rub", "rusty",
        "sauté", "saw", "scald", "scale", "schedule", "scoop", "scotch", "scour", "scrape",
        "seal", "sear", "season", "seasonal", "separate", "serve", "set", "sew", "shake",
        "shape", "shave", "shell", "shovel", "shred", "sift", "simmer", "singe", "skewer",
        "skim", "skin", "slash", "slice", "slit", "sliver", "smoke", "smooth", "snip",
        "soak", "souse", "sow", "spit", "splat", "split", "spread", "sprinkle", "squeeze",
        "stack", "stamp", "stand", "steam", "steep", "stemmed", "stew", "stick", "stir",
        "store", "strain", "strew", "strip", "stuff", "substitute", "surround", "sweeten",
        "swing", "syringe",
        "take", "taste", "temperature", "thicken", "thin", "throw", "tie", "toast", "top",
        "toss", "trail", "trim", "truss", "try", "turn",
        "unmold", "use",
        "variation",
        "warm", "wash", "weigh", "weight", "whip", "whisk", "wipe", "work", "wrap", "wring",
        "finely", "rings", "deveined", "tails removed", "diagonal", "the", "wedge",
        "morton", "kosher", "store-bought", "homemade"
    ]

    private static func trimVerbs(_ input: String) -> String {
        var result = input
        let sorted = cookingVerbs.sorted { $0.count > $1.count }

        for verb in sorted {
            if result.lowercased().contains(verb) {
                let escaped = NSRegularExpression.escapedPattern(for: verb)
                let pattern = "\\b\\w*\(escaped)\\w*\\b"
                result = result.replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return trimPrepositions(result.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: - Preposition Trimming (ports trim_prepositions from merge_ingredients.js)

    private static let prepositions = [
        "of", "with", "to", "in", "on", "at", "for", "by", "from", "into", "over",
        "under", "through", "around", "beside", "between", "among", "towards", "room",
        "very", "more for serving", "for serving", "melon baller", "a", "press",
        "freshly ground", "crack", "seeded", "pit"
    ]

    private static let conjunctions = ["and", "or", "nor", "but", "yet", "so"]

    private static func trimPrepositions(_ input: String) -> String {
        var result = input
        let sorted = prepositions.sorted { $0.count > $1.count }

        for prep in sorted {
            let escaped = NSRegularExpression.escapedPattern(for: prep)
            let pattern = "\\b\(escaped)\\b"
            result = result.replacingOccurrences(of: pattern, with: "", options: [.regularExpression, .caseInsensitive])
        }

        // Trim conjunctions from beginning and end
        for conj in conjunctions {
            let escaped = NSRegularExpression.escapedPattern(for: conj)
            result = result.replacingOccurrences(of: "^\(escaped)\\s+", with: "", options: [.regularExpression, .caseInsensitive])
            result = result.replacingOccurrences(of: "\\s+\(escaped)$", with: "", options: [.regularExpression, .caseInsensitive])
        }

        // Trim punctuation from edges
        result = result.replacingOccurrences(of: "^[\\s.,]+|[\\s.,]+$", with: "", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Garlic Normalization

    private static func normalizeGarlicName(_ name: String) -> String {
        let lower = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let garlicPatterns = [
            "^garlic\\s+cloves?$",
            "^cloves?\\s+garlic$",
            "^garlic$"
        ]
        for pattern in garlicPatterns {
            if lower.range(of: pattern, options: .regularExpression) != nil {
                return "garlic"
            }
        }
        return name
    }

    // MARK: - Merge Pipeline (ports merge() from merge_ingredients.js)

    private static func merge(_ items: [GroceryItem]) -> [GroceryItem] {
        var groceryList: [GroceryItem] = []

        for item in items {
            guard !item.name.isEmpty else { continue }

            if let bestMatch = findBestMatch(item, in: groceryList) {
                mergeItems(existing: &groceryList[bestMatch.index], newItem: item)
            } else {
                groceryList.append(item)
            }
        }

        return groceryList
    }

    private struct MatchResult {
        let index: Int
        let similarity: Double
    }

    private static func findBestMatch(_ item: GroceryItem, in list: [GroceryItem]) -> MatchResult? {
        var bestSimilarity: Double = 0
        var bestIndex: Int = -1

        for (i, existing) in list.enumerated() {
            guard areItemsSimilar(item, existing),
                  areUnitsCompatible(item.unit, existing.unit) else { continue }

            let sim = calculateSimilarity(
                normalizeItemName(item.name),
                normalizeItemName(existing.name)
            )
            if sim > bestSimilarity {
                bestSimilarity = sim
                bestIndex = i
            }
        }

        return bestIndex >= 0 ? MatchResult(index: bestIndex, similarity: bestSimilarity) : nil
    }

    private static func mergeItems(existing: inout GroceryItem, newItem: GroceryItem) {
        // Keep longer name
        if newItem.name.count > existing.name.count {
            existing.name = newItem.name
        }
        existing.ingrIds.append(contentsOf: newItem.ingrIds)

        // Combine quantities with unit conversion if needed
        if existing.unit != newItem.unit && !existing.unit.isEmpty && !newItem.unit.isEmpty {
            if let rate = getConversionRate(from: newItem.unit, to: existing.unit) {
                existing.qty = roundAmount(existing.qty + newItem.qty * rate)
            } else {
                // Can't convert, just add raw quantities
                existing.qty = roundAmount(existing.qty + newItem.qty)
            }
        } else {
            existing.qty = roundAmount(existing.qty + newItem.qty)
            if existing.unit.isEmpty && !newItem.unit.isEmpty {
                existing.unit = newItem.unit
            }
        }
    }

    // MARK: - Similarity Checking (ports areItemsSimilar from merge_ingredients.js)

    private static func areItemsSimilar(_ a: GroceryItem, _ b: GroceryItem, threshold: Double = 0.8) -> Bool {
        let name1 = normalizeItemName(a.name)
        let name2 = normalizeItemName(b.name)

        // Exact match after normalization
        if name1 == name2 { return true }

        // One contains the other (avoid false positives)
        let minLen = min(name1.count, name2.count)
        if minLen >= 4 {
            if name1.contains(name2) || name2.contains(name1) {
                let problematicPairs: [(String, String)] = [
                    ("sugar", "powdered sugar"),
                    ("salt", "sea salt"),
                    ("pepper", "bell pepper"),
                    ("milk", "coconut milk")
                ]
                let isProblematic = problematicPairs.contains { (a, b) in
                    (name1.contains(a) && name2.contains(b)) ||
                    (name1.contains(b) && name2.contains(a))
                }
                if !isProblematic { return true }
            }
        }

        // Fuzzy matching using Levenshtein similarity
        let similarity = calculateSimilarity(name1, name2)
        return similarity >= threshold
    }

    // MARK: - Unit Compatibility (ports areUnitsCompatible from merge_ingredients.js)

    private static func areUnitsCompatible(_ unit1: String, _ unit2: String) -> Bool {
        // Both empty
        if unit1.isEmpty && unit2.isEmpty { return true }
        // One empty, one not
        if unit1.isEmpty || unit2.isEmpty { return false }
        // Exact match
        if unit1.lowercased() == unit2.lowercased() { return true }

        // Check conversion compatibility
        if getConversionRate(from: unit1, to: unit2) != nil { return true }

        // Special incompatible units
        let incompatible: Set<String> = ["small", "medium", "large", "clove", "whole"]
        let u1In = incompatible.contains(unit1.lowercased())
        let u2In = incompatible.contains(unit2.lowercased())
        return u1In == u2In
    }

    // MARK: - Unit Conversion (ports unit_conversions.js)

    private static let unitAbbreviations: [String: String] = [
        "teaspoon": "tsp", "ounce": "oz", "tablespoon": "tbsp", "pound": "lb",
        "gram": "g", "cup": "c", "pint": "pt", "quart": "qt", "gallon": "gal",
        "milliliter": "ml", "liter": "l", "kilogram": "kg", "fluid ounce": "fl oz"
    ]

    private static let customConversions: [String: Double] = [
        "tbsp/tsp": 3, "tsp/tbsp": 1.0/3.0,
        "c/tsp": 48, "tsp/c": 1.0/48.0,
        "c/tbsp": 16, "tbsp/c": 1.0/16.0,
        "medium/large": 1, "large/medium": 1,
        "small/medium": 1, "medium/small": 1,
        "large/small": 1, "small/large": 1,
        "sprig/tsp": 2.5, "tsp/sprig": 0.4,
        "sprig/tbsp": 7.5, "tbsp/sprig": 2.0/15.0,
        // Volume conversions
        "cup/oz": 8, "oz/cup": 0.125,
        "cup/tbsp": 16, "cup/tsp": 48,
        "tbsp/oz": 0.5, "oz/tbsp": 2,
        "tsp/oz": 1.0/6.0, "oz/tsp": 6,
        "cup/ml": 236.588, "ml/cup": 1.0/236.588,
        "tbsp/ml": 14.787, "ml/tbsp": 1.0/14.787,
        "tsp/ml": 4.929, "ml/tsp": 1.0/4.929,
        "oz/ml": 29.574, "ml/oz": 1.0/29.574,
        "l/ml": 1000, "ml/l": 0.001,
        "gal/cup": 16, "cup/gal": 1.0/16.0,
        "gal/qt": 4, "qt/gal": 0.25,
        "qt/cup": 4, "cup/qt": 0.25,
        "qt/pt": 2, "pt/qt": 0.5,
        "pt/cup": 2, "cup/pt": 0.5,
        // Weight conversions
        "lb/oz": 16, "oz/lb": 1.0/16.0,
        "kg/g": 1000, "g/kg": 0.001,
        "lb/g": 453.592, "g/lb": 1.0/453.592,
        "oz/g": 28.3495, "g/oz": 1.0/28.3495,
        "kg/lb": 2.20462, "lb/kg": 1.0/2.20462,
        "kg/oz": 35.274, "oz/kg": 1.0/35.274,
        // Weight-volume approximations
        "gram/tablespoon": 14, "tablespoon/gram": 1.0/14.0,
        "gram/tbsp": 14, "tbsp/gram": 1.0/14.0,
        "gram/teaspoon": 14.0/3.0, "teaspoon/gram": 3.0/14.0,
        "gram/tsp": 14.0/3.0, "tsp/gram": 3.0/14.0,
        "gram/cup": 224, "cup/gram": 1.0/224.0
    ]

    private static let invalidUnits: Set<String> = ["piece", "q.b."]

    static func getConversionRate(from fromUnit: String, to toUnit: String) -> Double? {
        let a = fromUnit.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let b = toUnit.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if a == b { return 1.0 }
        if invalidUnits.contains(a) || invalidUnits.contains(b) || a.isEmpty || b.isEmpty {
            return nil
        }

        // Try direct lookup
        let key = "\(a)/\(b)"
        if let rate = customConversions[key] { return rate }

        // Try with abbreviation normalization
        let aNorm = unitAbbreviations[a] ?? a
        let bNorm = unitAbbreviations[b] ?? b
        let normKey = "\(aNorm)/\(bNorm)"
        if let rate = customConversions[normKey] { return rate }

        // Try reverse abbreviation (full name from abbreviation)
        let aFull = unitAbbreviations.first(where: { $0.value == a })?.key ?? a
        let bFull = unitAbbreviations.first(where: { $0.value == b })?.key ?? b
        let fullKey = "\(aFull)/\(bFull)"
        if let rate = customConversions[fullKey] { return rate }

        return nil
    }

    // MARK: - Levenshtein Similarity

    static func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
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

    // MARK: - Group By Similarity (ports groupBySimilarity from merge_ingredients.js)

    private static func groupBySimilarity(_ items: [GroceryItem]) -> [GroceryItem] {
        let sorted = items.sorted { $0.name.count > $1.name.count }
        var groups: [[GroceryItem]] = []

        for item in sorted {
            let itemWords = removePunctuation(item.name).split(separator: " ").map(String.init)
            let (groupIndex, insertIndex) = findBestGroup(itemWords: itemWords, groups: groups)

            if groupIndex >= 0 {
                groups[groupIndex].insert(item, at: insertIndex)
            } else {
                groups.append([item])
            }
        }

        return groups.flatMap { $0 }
    }

    private static func findBestGroup(itemWords: [String], groups: [[GroceryItem]]) -> (Int, Int) {
        let similarityThreshold = 0.25
        var maxSimilarity: Double = 0
        var bestGroupIndex = -1
        var bestInsertIndex = 0

        for (groupIdx, group) in groups.enumerated() {
            for (itemIdx, groupItem) in group.enumerated() {
                let groupWords = removePunctuation(groupItem.name).split(separator: " ").map(String.init)
                let intersection = itemWords.filter { groupWords.contains($0) }.count
                guard !itemWords.isEmpty else { continue }
                let similarity = Double(intersection) / Double(itemWords.count)

                if similarity > maxSimilarity {
                    maxSimilarity = similarity
                    bestGroupIndex = groupIdx
                    bestInsertIndex = itemIdx
                }
            }
        }

        if maxSimilarity > similarityThreshold {
            return (bestGroupIndex, bestInsertIndex)
        }
        return (-1, 0)
    }

    private static func removePunctuation(_ text: String) -> String {
        text.replacingOccurrences(of: "[.,\\/#!$%\\^&\\*;:{}=\\-_`~()\"']", with: "", options: .regularExpression)
    }

    // MARK: - Utility

    private static func roundAmount(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
