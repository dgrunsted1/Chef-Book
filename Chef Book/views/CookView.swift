//
//  CookView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/30/24.
//

import SwiftUI

struct CookView: View {
    var recipe: Recipe
    let formatter = NumberFormatter()
    var body: some View {
        @State var is_made = recipe.made
        ScrollView {
            VStack {
                if recipe.image != "" {
                    AsyncImage(url: URL(string: recipe.image)) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame( height: 200)
                            .clipped()
                    } placeholder: {
                        ProgressView()
                            .frame(width: 75)
                    }
                }
                Text(recipe.title)
                Spacer()
                Text(recipe.desc)
                Spacer()
                HStack {
                    Spacer()
                    Text(recipe.author)
                    Spacer()
                    Text("\(recipe.time_in_seconds) sec.")
                    Spacer()
                    Text("\(recipe.servings) servings")
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Text(recipe.category)
                    Spacer()
                    Text(recipe.cuisine)
                    Spacer()
                    Text(recipe.country)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    if recipe.link_to_original_web_page != "" {
                        Link("original", destination: URL(string: recipe.link_to_original_web_page)!)
                            .accentColor(Color("TextColor"))
                        Spacer()
                    }
                    Toggle("", isOn: $is_made)
                        .toggleStyle(.switch)
                        .labelsHidden()
                    Spacer()
                    if recipe.made {
                        Image(systemName: "hand.thumbsup.fill")
                    } else {
                        Image(systemName: "hand.thumbsup")
                    }
                    Spacer()
                    if recipe.favorite {
                        Image(systemName: "heart.fill")
                    } else {
                        Image(systemName: "heart")
                    }
                    Spacer()
                    Image(systemName: "square.and.pencil")
                    Spacer()
                }
                Spacer()
                
                HStack {
                    Text("ingredients")
                    Spacer()
                }
                List(recipe.ingredients, id: \.self) { ingr in
                    Text("\(String(format: "%.2g", ingr.quantity)) \(ingr.unit) \(ingr.name)")
                }
                .listStyle(.plain)
                .frame(height: 320)
                Spacer()
                HStack {
                    Text("directions")
                    Spacer()
                }
                List(recipe.directions, id: \.self) { dir in
                    Text(dir)
                }
                .listStyle(.plain)
                .frame(height: 320)
                
                Spacer()
                HStack {
                    Spacer()
                    Button("new note") {
                        
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("MyPrimaryColor"))
                .foregroundColor(.black)
                }
                
                Spacer()
                ForEach(recipe.notes, id: \.self) { note in
                    Text(note)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    CookView(recipe: Recipe.sampleData[0])
}
