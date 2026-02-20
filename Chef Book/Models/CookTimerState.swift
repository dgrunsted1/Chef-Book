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
import UIKit
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
    let recipeName: String
    let recipeImageURL: String
    private(set) var remainingSeconds: Int
    private(set) var isRunning: Bool = false
    private(set) var isComplete: Bool = false
    private var timer: Timer?
    private var targetDate: Date?
    private var backgroundObserver: Any?
    private var foregroundObserver: Any?

    #if os(iOS)
    private var activity: Activity<CookTimerAttributes>?
    private var cachedImageData: Data?
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

    init(totalSeconds: Int, displayLabel: String, stepNumber: Int, stepSnippet: String, recipeName: String, recipeImageURL: String) {
        self.totalSeconds = totalSeconds
        self.displayLabel = displayLabel
        self.stepNumber = stepNumber
        self.stepSnippet = stepSnippet
        self.recipeName = recipeName
        self.recipeImageURL = recipeImageURL
        self.remainingSeconds = totalSeconds
        setupBackgroundObservers()
        #if os(iOS)
        cacheRecipeImage()
        #endif
    }

    #if os(iOS)
    private func cacheRecipeImage() {
        guard !recipeImageURL.isEmpty, let url = URL(string: recipeImageURL) else { return }
        // Try to get the image from URLCache synchronously (already loaded by AsyncImage)
        let request = URLRequest(url: url)
        let data: Data?
        if let cached = URLCache.shared.cachedResponse(for: request)?.data {
            data = cached
        } else {
            // Fallback: try synchronous load (image should be cached by OS)
            data = try? Data(contentsOf: url)
        }
        guard let data, let original = UIImage(data: data) else { return }
        let targetSize: CGFloat = 36
        let aspect = original.size.width / original.size.height
        let thumbSize: CGSize
        if aspect > 1 {
            thumbSize = CGSize(width: targetSize, height: targetSize / aspect)
        } else {
            thumbSize = CGSize(width: targetSize * aspect, height: targetSize)
        }
        let renderer = UIGraphicsImageRenderer(size: thumbSize)
        cachedImageData = renderer.jpegData(withCompressionQuality: 0.3) { ctx in
            original.draw(in: CGRect(origin: .zero, size: thumbSize))
        }
    }
    #endif

    func start() {
        guard !isRunning, remainingSeconds > 0 else { return }
        isRunning = true
        isComplete = false
        targetDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        cancelNotification()
        scheduleNotification()
        // End any stale activity before starting a new one
        endLiveActivity()
        startLiveActivity()
        startTicking()
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        targetDate = nil
        cancelNotification()
        updateLiveActivity()
    }

    func reset() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        targetDate = nil
        remainingSeconds = totalSeconds
        isComplete = false
        cancelNotification()
        endLiveActivity()
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
            updateLiveActivity()
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

        // Try to attach the recipe image
        if !recipeImageURL.isEmpty, let url = URL(string: recipeImageURL) {
            let task = URLSession.shared.dataTask(with: url) { [notificationId] data, response, _ in
                if let data, !data.isEmpty {
                    // Derive extension from URL path, MIME type, or default to jpg
                    let ext: String
                    let pathExt = url.pathExtension.lowercased()
                    if ["jpg", "jpeg", "png", "gif", "webp"].contains(pathExt) {
                        ext = pathExt
                    } else if let mimeType = (response as? HTTPURLResponse)?.mimeType,
                              let mimeSuffix = mimeType.split(separator: "/").last {
                        ext = String(mimeSuffix)
                    } else {
                        ext = "jpg"
                    }
                    let tmpFile = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(ext)
                    do {
                        try data.write(to: tmpFile)
                        let attachment = try UNNotificationAttachment(identifier: "image", url: tmpFile)
                        content.attachments = [attachment]
                    } catch {}
                }
                let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
            task.resume()
        } else {
            let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
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

        // Truncate snippet for Live Activity to stay under 4KB payload limit
        let snippet = stepSnippet
        let attributes = CookTimerAttributes(
            stepNumber: stepNumber,
            stepSnippet: snippet,
            timerLabel: displayLabel,
            totalSeconds: totalSeconds,
            recipeName: recipeName,
            recipeImageData: cachedImageData
        )
        let state = CookTimerAttributes.ContentState(
            remainingSeconds: remainingSeconds,
            isComplete: false,
            targetDate: targetDate
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
            isComplete: isComplete,
            targetDate: isRunning ? targetDate : nil
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
            isComplete: true,
            targetDate: nil
        )
        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.activity = nil
        #endif
    }

    deinit {
        timer?.invalidate()
        if let foregroundObserver { NotificationCenter.default.removeObserver(foregroundObserver) }
        if let backgroundObserver { NotificationCenter.default.removeObserver(backgroundObserver) }
        cancelNotification()
        #if os(iOS)
        if let activity {
            let finalState = CookTimerAttributes.ContentState(remainingSeconds: 0, isComplete: true, targetDate: nil)
            Task {
                await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            }
        }
        #endif
    }
}
