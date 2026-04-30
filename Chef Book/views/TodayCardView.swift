//
//  TodayCardView.swift
//  Chef Book
//
//  Created by David Grunsted on 7/7/24.
//

import SwiftUI

struct TodayCardView: View {
    @EnvironmentObject var network: Network
    var recipe: Recipe

    private var activeSession: ActiveCookingSession? {
        network.activeSessions.first(where: { $0.id == recipe.id })
    }

    private var madeBinding: Binding<Bool> {
        Binding(
            get: { network.today?.made[recipe.id] ?? false },
            set: { newValue in
                network.toggle_menu_made(recipeId: recipe.id, value: newValue) { _ in }
            }
        )
    }

    private var isFavorite: Bool {
        network.today?.recipes.first(where: { $0.id == recipe.id })?.favorite ?? recipe.favorite
    }

    var body: some View {
        let isActive = activeSession != nil
        let activeTimer = activeSession?.timers.values
            .filter { $0.isRunning && !$0.isComplete }
            .min(by: { $0.remainingSeconds < $1.remainingSeconds })

        VStack(spacing: 0) {
            if recipe.image != "" {
                AsyncImage(url: URL(string: recipe.image)) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(height: 80)
                        .clipped()
                } placeholder: {
                    ProgressView()
                        .frame(width: 75)
                }
            } else {
                Spacer()
            }
            VStack(spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recipe.title)
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                            .lineLimit(1)
                        if isActive {
                            if let timer = activeTimer {
                                Label(timer.timeString, systemImage: "timer")
                                    .font(.caption.monospacedDigit().weight(.medium))
                                    .foregroundColor(Color("MyPrimaryColor"))
                            } else {
                                Label("Now Cooking", systemImage: "fork.knife")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(Color("MyPrimaryColor"))
                            }
                        }
                    }
                    Spacer()
                    Toggle("", isOn: madeBinding)
                        .toggleStyle(.switch)
                        .labelsHidden()

                    Button {
                        network.toggle_favorite(recipeId: recipe.id, value: !isFavorite) { _ in }
                    } label: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(isFavorite ? Color("MyPrimaryColor") : Color("NeutralColor"))
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    Text("\(recipe.ingredientCount) ingr")
                    Spacer()
                    Text("\(recipe.directionCount) steps")
                    if !recipe.servings.isEmpty {
                        Spacer()
                        Text("\(recipe.servings) serv")
                    }
                    if recipe.time_in_seconds > 0 {
                        Spacer()
                        Text(Network.formatTime(recipe.time_in_seconds))
                    } else if !recipe.time_display.isEmpty {
                        Spacer()
                        Text(recipe.time_display)
                    }
                }
                .font(.caption)
                .foregroundColor(Color("NeutralColor"))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
        .background(Color("Base200Color"))
        .cornerRadius(10.0)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color("MyPrimaryColor"), lineWidth: isActive ? 2 : 0)
        )
    }

}

#Preview {
    TodayCardView(recipe: Recipe.sampleData[0])
        .previewLayout(.fixed(width: 355, height: 100))
        .environmentObject(Network())
}
