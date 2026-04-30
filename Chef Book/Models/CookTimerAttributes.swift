//
//  CookTimerAttributes.swift
//  Chef Book
//
//  Created by David Grunsted on 2/14/26.
//

#if os(iOS)
import ActivityKit
import Foundation

struct CookTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Current active step (first non-blurred direction). stepNumber == 0 means none.
        var stepNumber: Int
        var stepSnippet: String
        // Timer fields — zero/nil when no active timer
        var remainingSeconds: Int
        var totalSeconds: Int
        var isTimerComplete: Bool
        var targetDate: Date?
    }

    var recipeName: String
    var recipeImageData: Data?
    var recipeId: String
}
#endif
