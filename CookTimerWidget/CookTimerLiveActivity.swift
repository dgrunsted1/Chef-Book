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
            // Lock screen / notification banner view
            HStack(spacing: 10) {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)

                    Circle()
                        .trim(from: 0, to: progressValue(context: context))
                        .stroke(
                            context.state.isComplete ? Color.green : Color.orange,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    if context.state.isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green)
                    } else if let target = context.state.targetDate {
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

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.recipeName)
                        .font(.caption)
                        .bold()
                        .foregroundColor(context.state.isComplete ? .green : .primary)
                        .lineLimit(1)

                    Text("\(context.attributes.stepSnippet)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }


                if context.state.isComplete {
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

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    AppIconView(size: 36)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let target = context.state.targetDate {
                        Text(timerInterval: Date.now...target, countsDown: true)
                            .font(.system(.title, design: .monospaced))
                            .bold()
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(context.state.isComplete ? .green : .orange)
                    } else {
                        Text(timeString(context.state.remainingSeconds))
                            .font(.system(.title, design: .monospaced))
                            .bold()
                            .monospacedDigit()
                            .foregroundColor(context.state.isComplete ? .green : .orange)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.recipeName)
                            .font(.caption)
                            .bold()
                            .lineLimit(1)
                        Text(context.attributes.stepSnippet)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                AppIconView(size: 24)
            } compactTrailing: {
                Text(timeString(context.state.remainingSeconds))
                    .font(.system(.caption2))
                    .monospacedDigit()
                    .foregroundColor(context.state.isComplete ? .green : .orange)
            } minimal: {
                AppIconView(size: 22)
            }
        }
    }

    private func progressValue(context: ActivityViewContext<CookTimerAttributes>) -> Double {
        guard context.attributes.totalSeconds > 0 else { return 0 }
        return Double(context.attributes.totalSeconds - context.state.remainingSeconds) / Double(context.attributes.totalSeconds)
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
