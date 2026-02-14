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
        var remainingSeconds: Int
        var isComplete: Bool
    }

    var stepNumber: Int
    var stepSnippet: String
    var timerLabel: String
    var totalSeconds: Int
}
#endif
