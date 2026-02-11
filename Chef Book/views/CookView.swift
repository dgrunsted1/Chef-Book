//
//  CookView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/30/24.
//

import SwiftUI

struct CookView: View {
    @EnvironmentObject var network: Network
    var recipe: Recipe
    @State var is_made: Bool
    @State var is_favorite: Bool
    @State var newNoteText: String = ""
    @State var showNewNote: Bool = false

    init(recipe: Recipe) {
        self.recipe = recipe
        _is_made = State(initialValue: recipe.made)
        _is_favorite = State(initialValue: recipe.favorite)
    }

    var body: some View {
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
                    .font(.title2)
                    .bold()
                Spacer()
                if !recipe.desc.isEmpty {
                    Text(recipe.desc)
                    Spacer()
                }
                HStack {
                    Spacer()
                    if !recipe.author.isEmpty {
                        Text(recipe.author)
                        Spacer()
                    }
                    Text(Network.formatTime(recipe.time_in_seconds))
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
                        .onChange(of: is_made) {
                            network.toggle_made(recipeId: recipe.id, value: is_made) { _ in }
                        }
                    Spacer()
                    Image(systemName: is_made ? "hand.thumbsup.fill" : "hand.thumbsup")
                    Spacer()
                    Button {
                        is_favorite.toggle()
                        network.toggle_favorite(recipeId: recipe.id, value: is_favorite) { _ in }
                    } label: {
                        Image(systemName: is_favorite ? "heart.fill" : "heart")
                            .foregroundColor(is_favorite ? Color("MyPrimaryColor") : Color("NeutralColor"))
                    }
                    Spacer()
                    Image(systemName: "square.and.pencil")
                    Spacer()
                }
                Spacer()

                HStack {
                    Text("ingredients")
                        .font(.headline)
                    Spacer()
                }
                ForEach(recipe.ingredients, id: \.self) { ingr in
                    HStack {
                        Text(ingr.toString())
                        Spacer()
                    }
                }
                Spacer()
                HStack {
                    Text("directions")
                        .font(.headline)
                    Spacer()
                }
                ForEach(Array(recipe.directions.enumerated()), id: \.offset) { index, dir in
                    HStack(alignment: .top) {
                        Text("\(index + 1).")
                            .bold()
                        Text(dir)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }

                Spacer()
                HStack {
                    Spacer()
                    Button("new note") {
                        showNewNote.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("MyPrimaryColor"))
                    .foregroundColor(.black)
                }

                if showNewNote {
                    HStack {
                        TextField("Add a note...", text: $newNoteText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Save") {
                            guard !newNoteText.isEmpty else { return }
                            network.create_note(content: newNoteText, recipeId: recipe.id) { success in
                                if success {
                                    newNoteText = ""
                                    showNewNote = false
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color("MyPrimaryColor"))
                        .foregroundColor(.black)
                    }
                }

                Spacer()
                ForEach(recipe.notes, id: \.self) { note in
                    HStack {
                        Text(note)
                            .padding(.vertical, 2)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    CookView(recipe: Recipe.sampleData[0])
        .environmentObject(Network())
}
