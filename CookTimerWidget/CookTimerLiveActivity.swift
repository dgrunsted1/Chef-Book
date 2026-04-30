//
//  CookTimerLiveActivity.swift
//  CookTimerWidget
//
//  Created by David Grunsted on 2/14/26.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct CookTimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CookTimerAttributes.self) { context in
            // Lock screen / notification banner
            HStack(spacing: 10) {
                // Left: progress ring when timer is active, app logo otherwise
                if context.state.totalSeconds > 0 {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 3)

                        Circle()
                            .trim(from: 0, to: progressValue(context: context))
                            .stroke(
                                context.state.isTimerComplete ? Color.green : Color.orange,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))

                        if context.state.isTimerComplete {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
                        } else if let target = context.state.targetDate, target > Date.now {
                            Text(timerInterval: Date.now...target, countsDown: true)
                                .font(.system(size: 10, design: .monospaced))
                                .bold()
                                .multilineTextAlignment(.center)
                        } else {
                            Text(timeString(context.state.remainingSeconds))
                                .font(.system(size: 10, design: .monospaced))
                                .bold()
                        }
                    }
                    .frame(width: 40, height: 40)
                } else {
                    AppIconView(size: 40)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.recipeName)
                        .font(.caption)
                        .bold()
                        .foregroundColor(context.state.isTimerComplete ? .green : .primary)
                        .lineLimit(1)

                    if context.state.stepNumber > 0 {
                        Text(context.state.stepSnippet)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                if context.state.isTimerComplete {
                    Text("Done!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .bold()
                } else {
                    RecipeImageView(imageData: context.attributes.recipeImageData, size: 56)
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 6)
            .padding(.vertical, 14)
            .activityBackgroundTint(.black.opacity(0.8))
            .activitySystemActionForegroundColor(.white)
            .widgetURL(URL(string: "chefbook://cook/\(context.attributes.recipeId)"))

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if let url = URL(string: "chefbook://cook/\(context.attributes.recipeId)") {
                        Link(destination: url) {
                            AppIconView(size: 36)
                                .padding(.leading, 6)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let url = URL(string: "chefbook://cook/\(context.attributes.recipeId)") {
                        Link(destination: url) {
                            if context.state.totalSeconds > 0 {
                                if context.state.isTimerComplete {
                                    Text("Done!")
                                        .font(.system(.title3, design: .monospaced))
                                        .bold()
                                        .foregroundColor(.green)
                                        .padding(.trailing, 6)
                                } else if let target = context.state.targetDate, target > Date.now {
                                    Text(timerInterval: Date.now...target, countsDown: true)
                                        .font(.system(.title, design: .monospaced))
                                        .bold()
                                        .monospacedDigit()
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.orange)
                                        .padding(.trailing, 6)
                                } else {
                                    Text(timeString(context.state.remainingSeconds))
                                        .font(.system(.title, design: .monospaced))
                                        .bold()
                                        .monospacedDigit()
                                        .foregroundColor(.orange)
                                        .padding(.trailing, 6)
                                }
                            } else if context.state.stepNumber > 0 {
                                Text("Step \(context.state.stepNumber)")
                                    .font(.system(.subheadline).bold())
                                    .foregroundColor(.primary)
                                    .padding(.trailing, 6)
                            }
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let url = URL(string: "chefbook://cook/\(context.attributes.recipeId)") {
                        Link(destination: url) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(context.attributes.recipeName)
                                    .font(.caption)
                                    .bold()
                                    .lineLimit(1)
                                if context.state.stepNumber > 0 {
                                    Text("Step \(context.state.stepNumber): \(context.state.stepSnippet)")
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 6)
                        }
                    }
                }
            } compactLeading: {
                if let url = URL(string: "chefbook://cook/\(context.attributes.recipeId)") {
                    Link(destination: url) {
                        AppIconView(size: 24)
                    }
                }
            } compactTrailing: {
                if let url = URL(string: "chefbook://cook/\(context.attributes.recipeId)") {
                    Link(destination: url) {
                        if context.state.totalSeconds > 0 {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 2.5)
                                Circle()
                                    .trim(from: 0, to: progressValue(context: context))
                                    .stroke(
                                        context.state.isTimerComplete ? Color.green : Color.orange,
                                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                if context.state.isTimerComplete {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.green)
                                }
                            }
                            .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "fork.knife")
                                .font(.caption2)
                                .foregroundColor(.primary)
                        }
                    }
                }
            } minimal: {
                AppIconView(size: 22)
            }
        }
    }

    private func progressValue(context: ActivityViewContext<CookTimerAttributes>) -> Double {
        guard context.state.totalSeconds > 0 else { return 0 }
        if context.state.isTimerComplete { return 1.0 }
        if let target = context.state.targetDate, target > Date.now {
            let remaining = target.timeIntervalSinceNow
            return 1.0 - (remaining / TimeInterval(context.state.totalSeconds))
        }
        return Double(context.state.totalSeconds - context.state.remainingSeconds) / Double(context.state.totalSeconds)
    }

    private func timeString(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Recipe Image View

private struct RecipeImageView: View {
    let imageData: Data?
    let size: CGFloat

    var body: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
        } else {
            AppIconView(size: size)
        }
    }
}

// MARK: - App Icon View

private struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        Image("AppIconImage")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }
}
