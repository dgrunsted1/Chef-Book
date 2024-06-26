//
//  RecipeCardView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI

struct RecipeCardView: View {
    var recipe: Recipe
    let edit: Bool
    
    @ViewBuilder
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: recipe.images[0])) { image in
                image.resizable()
                    .frame(width: 50, height: 50)
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } placeholder: {
                ProgressView()
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading) {
                Text(recipe.title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                HStack {

                    Text("\(recipe.ingredients.count) ingredients")
                        .accessibilityLabel("\(recipe.ingredients.count) ingredients")
                    Spacer()
                    Text("\(recipe.servings) servings")
                    Spacer()
                    Text("\(recipe.time_in_seconds/60)m")
                }
                .font(.caption)
                .padding(.horizontal)
            }
            if edit {
                VStack{
                    HStack {
                        Image(systemName: "hand.thumbsup")
                        Spacer()
                        Image(systemName: "heart")
                    }
                    Spacer()
                    HStack {
                        Image(systemName: "square")
                        Spacer()
                        Image(systemName: "trash")
                    }
                }
                .frame(width: 50, height:50)
            } else {
                Image(systemName: "plus.app.fill")
                    .resizable()
                    .frame(width:30, height:30)
                    .cornerRadius(10)
                    .foregroundColor(Color("MyPrimaryColor"))
            }
        }
        .padding(10)
        .background(Color("Base200Color"))
        .cornerRadius(10.0)
    }

}

struct CardView_Previews: PreviewProvider {
    static var recipe = Recipe.sampleData[0]
    static var previews: some View {
        RecipeCardView(recipe: recipe, edit: false)
            .previewLayout(.fixed(width: 355, height: 75))
    }
}

