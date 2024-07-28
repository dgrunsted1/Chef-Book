//
//  TodayCardView.swift
//  Chef Book
//
//  Created by David Grunsted on 7/7/24.
//

import SwiftUI

struct TodayCardView: View {
    var recipe: Recipe
    @Binding var made: Bool
    
    @ViewBuilder
    var body: some View {
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
                Text(recipe.title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Toggle("", isOn: $made)
                    .toggleStyle(.switch)
                    .labelsHidden()
                Image(systemName: "heart")
            }
            .padding([.bottom,.horizontal], 5)
        }
        .background(Color("Base200Color"))
        .cornerRadius(10.0)
        .frame(height: 120)
    }

}

#Preview {
    @State var made = true
    TodayCardView(recipe: Recipe.sampleData[0], made: $made)
        .previewLayout(.fixed(width: 355, height: 100))
}
