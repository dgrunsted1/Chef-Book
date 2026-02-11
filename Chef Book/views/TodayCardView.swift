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
        VStack {
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
            HStack {
                Text(recipe.title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
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
            .padding([.bottom,.horizontal], 5)
        }
        .background(Color("Base200Color"))
        .cornerRadius(10.0)
        .frame(height: 120)
    }

}

#Preview {
    TodayCardView(recipe: Recipe.sampleData[0], made: true)
        .previewLayout(.fixed(width: 355, height: 100))
        .environmentObject(Network())
}
