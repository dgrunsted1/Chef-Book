//
//  ActiveCookingSession.swift
//  Chef Book
//
//  Created by David Grunsted on 4/27/26.
//

import Foundation
#if os(iOS)
import ActivityKit
import UIKit
#endif

@Observable
class ActiveCookingSession: Identifiable {
    let id: String
    var recipe: Recipe
    var sourceTab: AppTab
    var timers: [Int: CookTimer] = [:] {
        didSet { updateLiveActivity() }
    }
    var blurredIngredients: Set<Int> = []
    var blurredDirections: Set<Int> = [] {
        didSet { updateLiveActivity() }
    }

    #if os(iOS)
    private var activity: Activity<CookTimerAttributes>?
    private var cachedImageData: Data?
    #endif

    init(recipe: Recipe, sourceTab: AppTab) {
        self.id = recipe.id
        self.recipe = recipe
        self.sourceTab = sourceTab
    }

    var runningTimerCount: Int {
        timers.values.filter { $0.isRunning && !$0.isComplete }.count
    }

    var shortestRunningTimer: CookTimer? {
        timers.values
            .filter { $0.isRunning && !$0.isComplete }
            .min(by: { $0.remainingSeconds < $1.remainingSeconds })
    }

    func stopAllTimers() {
        timers.values.forEach { $0.reset() }
        timers.removeAll()
        endLiveActivity()
    }

    // MARK: - Live Activity

    /// The first non-blurred direction step, used as "current step" in the Live Activity.
    private var currentStep: (number: Int, snippet: String)? {
        for (i, direction) in recipe.directions.enumerated() {
            if !blurredDirections.contains(i) {
                return (i + 1, direction)
            }
        }
        return nil
    }

    /// The most relevant timer to display (running or just completed, least time remaining).
    private var displayTimer: CookTimer? {
        timers.values
            .filter { $0.isRunning || $0.isComplete }
            .min(by: { $0.remainingSeconds < $1.remainingSeconds })
    }

    func startLiveActivity() {
        #if os(iOS)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        cacheRecipeImageIfNeeded()
        let state = makeContentState()
        if let existing = activity {
            Task { await existing.update(.init(state: state, staleDate: nil)) }
        } else {
            let attributes = CookTimerAttributes(
                recipeName: recipe.title,
                recipeImageData: cachedImageData,
                recipeId: recipe.id
            )
            do {
                activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil),
                    pushType: nil
                )
            } catch {
                print("Failed to start Live Activity: \(error)")
            }
        }
        #endif
    }

    func updateLiveActivity() {
        #if os(iOS)
        guard let activity else { return }
        let state = makeContentState()
        Task { await activity.update(.init(state: state, staleDate: nil)) }
        #endif
    }

    func endLiveActivity() {
        #if os(iOS)
        guard let activity else { return }
        let state = makeContentState()
        Task {
            await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.activity = nil
        #endif
    }

    #if os(iOS)
    private func makeContentState() -> CookTimerAttributes.ContentState {
        let step = currentStep
        let t = displayTimer
        return CookTimerAttributes.ContentState(
            stepNumber: step?.number ?? 0,
            stepSnippet: step?.snippet ?? "",
            remainingSeconds: t?.remainingSeconds ?? 0,
            totalSeconds: t?.totalSeconds ?? 0,
            isTimerComplete: t?.isComplete ?? false,
            targetDate: t?.targetDate
        )
    }

    private func cacheRecipeImageIfNeeded() {
        guard cachedImageData == nil,
              !recipe.image.isEmpty,
              let url = URL(string: recipe.image) else { return }
        let request = URLRequest(url: url)
        if let cached = URLCache.shared.cachedResponse(for: request)?.data,
           let original = UIImage(data: cached) {
            cachedImageData = resized(original, to: 36)
        } else {
            DispatchQueue.global(qos: .utility).async { [weak self] in
                guard let data = try? Data(contentsOf: url),
                      let original = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self?.cachedImageData = self?.resized(original, to: 36)
                }
            }
        }
    }

    private func resized(_ image: UIImage, to targetSize: CGFloat) -> Data? {
        let aspect = image.size.width / image.size.height
        let size = aspect > 1
            ? CGSize(width: targetSize, height: targetSize / aspect)
            : CGSize(width: targetSize * aspect, height: targetSize)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.jpegData(withCompressionQuality: 0.3) { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    #endif
}
