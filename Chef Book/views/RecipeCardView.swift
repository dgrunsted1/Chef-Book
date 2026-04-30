//
//  RecipeCardView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI

struct RecipeCardView: View {
    @EnvironmentObject var network: Network
    var recipe: Recipe
    let edit: Bool
    
    private var activeSession: ActiveCookingSession? {
        network.activeSessions.first(where: { $0.id == recipe.id })
    }

    @ViewBuilder
    var body: some View {
        let isActive = activeSession != nil
        let activeTimer = activeSession?.timers.values
            .filter { $0.isRunning && !$0.isComplete }
            .min(by: { $0.remainingSeconds < $1.remainingSeconds })

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
                HStack(alignment: .firstTextBaseline) {
                    Text(recipe.title)
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
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
                HStack {
                    Text("\(recipe.ingredientCount) ingredients")
                        .accessibilityLabel("\(recipe.ingredientCount) ingredients")
                    Spacer()
                    Text("\(recipe.servings) servings")
                    Spacer()
                    Text(recipe.time_display.isEmpty ? "\(recipe.time_in_seconds/60)m" : recipe.time_display)
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
            } else if recipe.user != network.user?.record.id {
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
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color("MyPrimaryColor"), lineWidth: isActive ? 2 : 0)
        )
    }

}

struct CardView_Previews: PreviewProvider {
//    var network = Network()
    static var previews: some View {
        RecipeCardView(recipe: Recipe.sampleData[0], edit: false)
            .environmentObject(Network())
            .previewLayout(.fixed(width: 355, height: 100))
//
    }
}

