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
            HStack(spacing: 12) {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: progressValue(context: context))
                        .stroke(
                            context.state.isComplete ? Color.green : Color.orange,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))

                    if context.state.isComplete {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Text(timeString(context.state.remainingSeconds))
                            .font(.system(size: 11, design: .monospaced))
                            .bold()
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.recipeName)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(context.state.isComplete ? .green : .primary)
                        .lineLimit(1)

                    Text(context.attributes.stepSnippet)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if context.state.isComplete {
                    Text("Done!")
                        .font(.headline)
                        .foregroundColor(.green)
                } else {
                    RecipeImageView(url: context.attributes.recipeImageURL, size: 44)
                }
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.8))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    RecipeImageView(url: context.attributes.recipeImageURL, size: 36)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timeString(context.state.remainingSeconds))
                        .font(.system(.title, design: .monospaced))
                        .bold()
                        .monospacedDigit()
                        .foregroundColor(context.state.isComplete ? .green : .orange)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.recipeName)
                            .font(.caption)
                            .bold()
                            .lineLimit(1)
                        Text("Step \(context.attributes.stepNumber) - \(context.attributes.stepSnippet)")
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                RecipeImageView(url: context.attributes.recipeImageURL, size: 24)
            } compactTrailing: {
                Text(timeString(context.state.remainingSeconds))
                    .font(.system(.caption, design: .monospaced))
                    .bold()
                    .monospacedDigit()
                    .foregroundColor(context.state.isComplete ? .green : .orange)
            } minimal: {
                RecipeImageView(url: context.attributes.recipeImageURL, size: 22)
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
    let url: String
    let size: CGFloat

    var body: some View {
        if !url.isEmpty, let imageURL = URL(string: url) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
                default:
                    fallbackIcon
                }
            }
        } else {
            fallbackIcon
        }
    }

    private var fallbackIcon: some View {
        Image("AppIconImage")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }
}
