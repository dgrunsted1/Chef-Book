//
//  TodayCardView.swift
//  Chef Book
//
//  Created by David Grunsted on 7/7/24.
//

import SwiftUI

struct TodayCardView: View {
    var recipe: Recipe
    
    
    @ViewBuilder
    var body: some View {
        @State var made = recipe.made
        VStack {
            if recipe.image != "" {
                AsyncImage(url: URL(string: recipe.image)) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: .infinity, height: 80)
                        .clipped()
                } placeholder: {
                    ProgressView()
                        .frame(width: 75)
                }
            } else {
                Spacer()
            }
            HStack {
                Spacer()
                Text(recipe.title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Toggle("", isOn: $made)
                    .toggleStyle(.switch)
                    .labelsHidden()
                Image(systemName: "heart")
                Spacer()
            }
            
//            VStack(alignment: .leading) {
//                Text(recipe.title)
//                    .font(.headline)
//                    .accessibilityAddTraits(.isHeader)
//                Spacer()
//                HStack {
//
//                    Text("\(recipe.ingredients.count) ingredients")
//                        .accessibilityLabel("\(recipe.ingredients.count) ingredients")
//                    Spacer()
//                    Text("\(recipe.servings) servings")
//                    Spacer()
//                    Text("\(recipe.time_in_seconds/60)m")
//                }
//                .font(.caption)
//                .padding(.horizontal)
////            }
//            .frame(height: 70)
//            .padding(.vertical, 5)
//            if edit {
//                VStack{
//                    HStack {
//                        Image(systemName: "hand.thumbsup")
//                        Spacer()
//                        Image(systemName: "heart")
//                    }
//                    Spacer()
//                    HStack {
//                        Image(systemName: "square")
//                        Spacer()
//                        Image(systemName: "trash")
//                    }
//                }
//                .frame(width: 50, height:50)
//            } else {
//                Image(systemName: "plus.app.fill")
//                    .resizable()
//                    .frame(width:30, height:30)
//                    .cornerRadius(10)
//                    .foregroundColor(Color("MyPrimaryColor"))
//                    .padding([.trailing], 10)
//            }
                
        }
        .background(Color("Base200Color"))
        .cornerRadius(10.0)
        .frame(height: 120)
    }

}

#Preview {
    TodayCardView(recipe: Recipe.sampleData[0])
        .previewLayout(.fixed(width: 355, height: 100))
}
