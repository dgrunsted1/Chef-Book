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
            if recipe.image != "" {
                AsyncImage(url: URL(string: recipe.image)) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 75, height: 80)
                        .clipped()
                } placeholder: {
                    ProgressView()
                        .frame(width: 75)
                }
            } else {
                Spacer()
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
            .frame(height: 70)
            .padding(.vertical, 5)
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
                    .padding([.trailing], 10)
            }
                
        }
        .background(Color("Base200Color"))
        .cornerRadius(10.0)
        .frame(height: 80)
    }

}

struct CardView_Previews: PreviewProvider {
//    var network = Network()
    static var previews: some View {
        RecipeCardView(recipe: Recipe.sampleData[0], edit: false)
            .previewLayout(.fixed(width: 355, height: 100))
//
    }
}

