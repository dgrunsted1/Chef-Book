//
//  CookTimerState.swift
//  Chef Book
//
//  Created by David Grunsted on 2/14/26.
//

import Foundation
import AudioToolbox
#if os(iOS)
import UIKit
#endif

struct ParsedTimer {
    let totalSeconds: Int
    let displayLabel: String
}

enum TimerParser {
    private static let pattern = #"(\d+)\s*[-–]?\s*(\d+)?\s*(minutes?|mins?|hours?|hrs?|hr|seconds?|secs?)"#

    static func parse(direction: String) -> [ParsedTimer] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return []
        }
        let nsString = direction as NSString
        let matches = regex.matches(in: direction, range: NSRange(location: 0, length: nsString.length))

        var timers: [ParsedTimer] = []
        for match in matches {
            let numberStr = nsString.substring(with: match.range(at: 1))
            let unitStr = nsString.substring(with: match.range(at: 3)).lowercased()

            var value: Int
            if match.range(at: 2).location != NSNotFound {
                let secondNumberStr = nsString.substring(with: match.range(at: 2))
                value = Int(secondNumberStr) ?? Int(numberStr) ?? 0
            } else {
                value = Int(numberStr) ?? 0
            }

            guard value > 0 else { continue }

            let seconds: Int
            let label: String
            if unitStr.hasPrefix("h") {
                seconds = value * 3600
                label = value == 1 ? "1 hr" : "\(value) hrs"
            } else if unitStr.hasPrefix("s") {
                seconds = value
                label = "\(value) sec"
            } else {
                seconds = value * 60
                label = "\(value) min"
            }

            timers.append(ParsedTimer(totalSeconds: seconds, displayLabel: label))
        }
        return timers
    }
}

@Observable
class CookTimer {
    let totalSeconds: Int
    let displayLabel: String
    let stepNumber: Int
    let stepSnippet: String
    let nextStepSnippet: String?
    let recipeName: String
    let recipeImageURL: String
    private(set) var remainingSeconds: Int
    private(set) var isRunning: Bool = false
    private(set) var isComplete: Bool = false
    private var timer: Timer?
    private(set) var targetDate: Date?
    private var backgroundObserver: Any?
    private var foregroundObserver: Any?

    /// Called whenever the timer starts, pauses, completes, or resets.
    /// The owning ActiveCookingSession sets this to update the Live Activity.
    var onChange: (() -> Void)?

    var stepLabel: String {
        "Step \(stepNumber)"
    }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var timeString: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    init(totalSeconds: Int, displayLabel: String, stepNumber: Int, stepSnippet: String, nextStepSnippet: String? = nil, recipeName: String, recipeImageURL: String) {
        self.totalSeconds = totalSeconds
        self.displayLabel = displayLabel
        self.stepNumber = stepNumber
        self.stepSnippet = stepSnippet
        self.nextStepSnippet = nextStepSnippet
        self.recipeName = recipeName
        self.recipeImageURL = recipeImageURL
        self.remainingSeconds = totalSeconds
        setupBackgroundObservers()
    }

    func start() {
        guard !isRunning, remainingSeconds > 0 else { return }
        isRunning = true
        isComplete = false
        targetDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        startTicking()
        onChange?()
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        targetDate = nil
        onChange?()
    }

    func reset() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        targetDate = nil
        remainingSeconds = totalSeconds
        isComplete = false
        onChange?()
    }

    private func startTicking() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard isRunning, let targetDate else { return }
        let remaining = Int(ceil(targetDate.timeIntervalSinceNow))
        if remaining <= 0 {
            remainingSeconds = 0
            complete()
        } else {
            remainingSeconds = remaining
            onChange?()
        }
    }

    private func setupBackgroundObservers() {
        #if os(iOS)
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self, self.isRunning else { return }
            self.tick()
            self.startTicking()
        }
        #endif
    }

    private func complete() {
        isRunning = false
        isComplete = true
        timer?.invalidate()
        timer = nil
        targetDate = nil
        AudioServicesPlaySystemSound(1005)
        #if os(iOS)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        #endif
        onChange?()
    }

    deinit {
        timer?.invalidate()
        if let foregroundObserver { NotificationCenter.default.removeObserver(foregroundObserver) }
        if let backgroundObserver { NotificationCenter.default.removeObserver(backgroundObserver) }
    }
}
