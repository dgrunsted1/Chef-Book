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
    @State var is_made: Bool
    @State var is_favorite: Bool

    init(recipe: Recipe, made: Bool) {
        self.recipe = recipe
        _is_made = State(initialValue: made)
        _is_favorite = State(initialValue: recipe.favorite)
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
                    Toggle("", isOn: $is_made)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .onChange(of: is_made) {
                            network.toggle_made(recipeId: recipe.id, value: is_made) { _ in }
                        }

                    Button {
                        is_favorite.toggle()
                        network.toggle_favorite(recipeId: recipe.id, value: is_favorite) { _ in }
                    } label: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(is_favorite ? Color("MyPrimaryColor") : Color("NeutralColor"))
                    }
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
    TodayCardView(recipe: Recipe.sampleData[0], made: true)
        .previewLayout(.fixed(width: 355, height: 100))
        .environmentObject(Network())
}
