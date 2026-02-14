//
//  CookTimerState.swift
//  Chef Book
//
//  Created by David Grunsted on 2/14/26.
//

import Foundation
import AudioToolbox
import UserNotifications
#if os(iOS)
import ActivityKit
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
    private(set) var remainingSeconds: Int
    private(set) var isRunning: Bool = false
    private(set) var isComplete: Bool = false
    private var timer: Timer?

    #if os(iOS)
    private var activity: Activity<CookTimerAttributes>?
    #endif

    private var notificationId: String {
        "cooktimer-step\(stepNumber)"
    }

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

    init(totalSeconds: Int, displayLabel: String, stepNumber: Int, stepSnippet: String) {
        self.totalSeconds = totalSeconds
        self.displayLabel = displayLabel
        self.stepNumber = stepNumber
        self.stepSnippet = stepSnippet
        self.remainingSeconds = totalSeconds
    }

    func start() {
        guard !isRunning, remainingSeconds > 0 else { return }
        isRunning = true
        isComplete = false
        scheduleNotification()
        startLiveActivity()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.remainingSeconds > 0 {
                self.remainingSeconds -= 1
                self.updateLiveActivity()
                if self.remainingSeconds == 0 {
                    self.complete()
                }
            }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        cancelNotification()
        updateLiveActivity()
    }

    func reset() {
        pause()
        remainingSeconds = totalSeconds
        isComplete = false
        endLiveActivity()
    }

    private func complete() {
        isRunning = false
        isComplete = true
        timer?.invalidate()
        timer = nil
        updateLiveActivity()
        AudioServicesPlaySystemSound(1005)
        #if os(iOS)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        #endif
        // End the live activity after a short delay so user sees "Done!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.endLiveActivity()
        }
    }

    // MARK: - Notifications

    private func scheduleNotification() {
        cancelNotification()

        let content = UNMutableNotificationContent()
        content.title = "\(stepLabel) Timer Done"
        content.body = stepSnippet
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(remainingSeconds),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: notificationId,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationId]
        )
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        #if os(iOS)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = CookTimerAttributes(
            stepNumber: stepNumber,
            stepSnippet: stepSnippet,
            timerLabel: displayLabel,
            totalSeconds: totalSeconds
        )
        let state = CookTimerAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            isComplete: false
        )

        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Failed to start live activity: \(error)")
        }
        #endif
    }

    private func updateLiveActivity() {
        #if os(iOS)
        guard let activity else { return }
        let state = CookTimerAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            isComplete: isComplete
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
        #endif
    }

    private func endLiveActivity() {
        #if os(iOS)
        guard let activity else { return }
        let finalState = CookTimerAttributes.ContentState(
            remainingSeconds: 0,
            isComplete: true
        )
        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.activity = nil
        #endif
    }

    deinit {
        timer?.invalidate()
        cancelNotification()
        #if os(iOS)
        if let activity {
            let finalState = CookTimerAttributes.ContentState(remainingSeconds: 0, isComplete: true)
            Task {
                await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            }
        }
        #endif
    }
}
