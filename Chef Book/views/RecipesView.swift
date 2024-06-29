//
//  RecipesView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI

struct RecipesView: View {
    @EnvironmentObject var network: Network
    @State private var search_val: String = ""
    @State private var sort_val: String = "most recent"
    @State private var selected_cat: String = "category"
    @State private var selected_cuisine: String = "cuisine"
    @State private var selected_country: String = "country"
    @State private var selected_author: String = "author"
    @FocusState private var search_field_is_focused: Bool
    private let sort_options: [String] = ["least ingredients", "most ingredients", "least servings", "most servings", "least time", "most time", "least recent", "most recent"]
    

    
    var body: some View {
        VStack {
            List(network.recipes) { recipe in
                RecipeCardView(recipe: recipe, edit: false)
            }
            .listStyle(.inset)
            
            VStack {
                    HStack {
                        TextField(
                            "search",
                            text: $search_val
                        )
                        .padding([.leading, .trailing])
                        .focused($search_field_is_focused)
                        .onChange (of: search_val) {
                            network.getRecipes(category: selected_cat, cuisine: selected_cuisine, country: selected_country, author: selected_author, sort: sort_val, made: true, search: search_val)
                        }
                        .autocorrectionDisabled()
                        .disableAutocorrection(true)
                        .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color("MyPrimaryColor"), lineWidth: 2)
                            )
                        Text("\(network.recipes.count) recipes")
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
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color("MyPrimaryColor"), lineWidth: 2)
                            )
                        .onChange(of: sort_val, initial: true) {
                            network.getRecipes(category: selected_cat, cuisine: selected_cuisine, country: selected_country, author: selected_author, sort: sort_val, made: true, search: search_val)
                                }
                        
                    }
                    .padding([.leading, .trailing], 10)
                HStack{
                    Menu {
                        Picker("category", selection: $selected_cat) {
                            ForEach(network.categories, id: \.self) {
                                Text($0)
                            }
                        }
                        .onChange(of: selected_cat, initial: true) {
                            network.getRecipes(category: selected_cat, cuisine: selected_cuisine, country: selected_country, author: selected_author, sort: sort_val, made: true, search: search_val)
                                }
                    } label: {
                        Text(selected_cat)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color("MyPrimaryColor"), lineWidth: 2)
                                    .padding([.leading, .trailing], -5)
                            )
                            .accentColor(Color("TextColor"))
                    }
                    Spacer()
                    Menu {
                        Picker("cuisine", selection: $selected_cuisine) {
                            ForEach(network.cuisines, id: \.self) {
                                Text($0)
                            }
                        }
                        .onChange(of: selected_cuisine, initial: true) {
                            network.getRecipes(category: selected_cat, cuisine: selected_cuisine, country: selected_country, author: selected_author, sort: sort_val, made: true, search: search_val)
                                }
                    } label: {
                        Text(selected_cuisine)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color("MyPrimaryColor"), lineWidth: 2)
                                    .padding([.leading, .trailing], -5)
                            )
                            .accentColor(Color("TextColor"))
                    }
                    Spacer()
                    Menu {
                        Picker("country", selection: $selected_country) {
                            ForEach(network.countries, id: \.self) {
                                Text($0)
                            }
                        }
                        .onChange(of: selected_country, initial: true) {
                            network.getRecipes(category: selected_cat, cuisine: selected_cuisine, country: selected_country, author: selected_author, sort: sort_val, made: true, search: search_val)
                                }
                    } label: {
                        Text(selected_country)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .stroke(Color("MyPrimaryColor"), lineWidth: 2)
                                    .padding([.leading, .trailing], -5)
                            )
                            .accentColor(Color("TextColor"))
                    }
                    Spacer()
                    Menu {
                        Picker("author", selection: $selected_author) {
                            ForEach(network.authors, id: \.self) {
                                Text($0)
                            }
                        }
                        .onChange(of: selected_country, initial: true) {
                            network.getRecipes(category: selected_cat, cuisine: selected_cuisine, country: selected_country, author: selected_author, sort: sort_val, made: true, search: search_val)
                                }
                    } label: {
                        Text(selected_author)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
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
        .onAppear {
            network.getRecipes(category: selected_cat, cuisine: selected_cuisine, country: selected_country, author: selected_author, sort: sort_val, made: true, search: search_val)
            network.getCategories()
            network.getCuisines()
            network.getCountries()
            network.getAuthors()
        }
    }
        
        
}


#Preview {
    RecipesView()
        .environmentObject(Network())
}
