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
                    Text(recipe.title)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                        .lineLimit(1)
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
    }

}

#Preview {
    TodayCardView(recipe: Recipe.sampleData[0])
        .previewLayout(.fixed(width: 355, height: 100))
        .environmentObject(Network())
}
