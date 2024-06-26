//
//  RecipesView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI

struct RecipesView: View {
    @Binding var recipes: [Recipe]
    @State private var search_val: String = ""
    @State private var sort_val: String = "most recent"
    @State private var selected_cat: String = "category"
    @State private var selected_cuisine: String = "cuisine"
    @State private var selected_country: String = "country"
    @State private var selected_author: String = "author"
    @FocusState private var search_field_is_focused: Bool
    private let sort_options: [String] = ["least ingredients", "most ingredients", "least servings", "most servings", "least time", "most time", "least recent", "most recent"]
    private let cat_options: [String] = ["category", "main", "side", "dessert", "appetizer", "soup", "bread"]
    private let cuisine_options: [String] = ["cuisine", "north american", "south american", "central american", "east asian", "southeast asian", "south asian", "middle eastern", "north african", "south african", "mediteranian", "european"]
    private let country_options: [String] = ["country", "United States", "Mexico", "Brazil", "China", "France", "Greece", "Indie", "Isreal"]
    private let author_options: [String] = ["author", "David Grunsted", "J. Kenji Lopez Alt", "Carla Lalli Music", "Molly Baz", "Claire Saffitz"]
    

    
    var body: some View {
        VStack {
            List($recipes) { $recipe in
                RecipeCardView(recipe: recipe, edit: false)
            }
            .listStyle(PlainListStyle())
            
            VStack {
                    HStack {
                        TextField(
                            "search",
                            text: $search_val
                        )
                        .padding([.leading, .trailing])
                        .focused($search_field_is_focused)
                        .onSubmit {
                            //                            validate(name: $search_val)
                        }
                        .autocorrectionDisabled()
                        .disableAutocorrection(true)
                        .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("MyPrimaryColor"), lineWidth: 2)
                            )
                        Picker("sort", selection: $sort_val) {
                            ForEach(sort_options, id: \.self) {
                                Text($0)
                            }
                        }
                        .frame(height: 25)
                        .pickerStyle(.menu)
                        .accentColor(.black)
                        .background(Color("MyPrimaryColor"))
                        .cornerRadius(10)
                        .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("MyPrimaryColor"), lineWidth: 2)
                            )
                    }
                    .padding([.leading, .trailing], 10)
                HStack{
                    Menu {
                        Picker("category", selection: $selected_cat) {
                            ForEach(cat_options, id: \.self) {
                                Text($0)
                            }
                        }
                    } label: {
                        Text(selected_cat)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("MyPrimaryColor"), lineWidth: 2)
                                    .padding([.leading, .trailing], -5)
                            )
                            .accentColor(Color("TextColor"))
                    }
                    Spacer()
                    Menu {
                        Picker("cuisine", selection: $selected_cuisine) {
                            ForEach(cuisine_options, id: \.self) {
                                Text($0)
                            }
                        }
                    } label: {
                        Text(selected_cuisine)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("MyPrimaryColor"), lineWidth: 2)
                                    .padding([.leading, .trailing], -5)
                            )
                            .accentColor(Color("TextColor"))
                    }
                    Spacer()
                    Menu {
                        Picker("country", selection: $selected_country) {
                            ForEach(country_options, id: \.self) {
                                Text($0)
                            }
                        }
                    } label: {
                        Text(selected_country)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("MyPrimaryColor"), lineWidth: 2)
                                    .padding([.leading, .trailing], -5)
                            )
                            .accentColor(Color("TextColor"))
                    }
                    Spacer()
                    Menu {
                        Picker("author", selection: $selected_author) {
                            ForEach(author_options, id: \.self) {
                                Text($0)
                            }
                        }
                    } label: {
                        Text(selected_author)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("MyPrimaryColor"), lineWidth: 2)
                                    .padding([.leading, .trailing], -5)
                            )
                            .accentColor(Color("TextColor"))

                    }
                }
                .padding([.leading, .trailing], 20)
                .padding([.bottom], 10)
            }
        }
    }
        
        
}


#Preview {
    RecipesView(recipes: .constant(Recipe.sampleData))
}
