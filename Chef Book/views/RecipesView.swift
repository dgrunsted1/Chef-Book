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
    @State private var sort_val: String = "Most Recent"
    @State private var selectedCats: [String] = []
    @State private var selectedCuisines: [String] = []
    @State private var selectedCountries: [String] = []
    @State private var selectedAuthors: [String] = []
    @FocusState private var search_field_is_focused: Bool
    private let sort_options: [String] = ["Least Ingredients", "Most Ingredients", "Least Servings", "Most Servings", "Least Time", "Most Time", "Least Recent", "Most Recent"]

    private func fetchRecipes() {
        network.getRecipes(categories: selectedCats, cuisines: selectedCuisines, countries: selectedCountries, authors: selectedAuthors, sort: sort_val, search: search_val)
    }

    private func toggle(_ value: String, in array: inout [String]) {
        if let idx = array.firstIndex(of: value) {
            array.remove(at: idx)
        } else {
            array.append(value)
        }
        fetchRecipes()
    }

    var body: some View {
        VStack(spacing: 0) {
            if network.recipes.isEmpty && !network.isLoading {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No recipes found")
                        .foregroundColor(.gray)
                }
                Spacer()
            } else {
                ScrollView {
                    if network.isLoading {
                        ProgressView()
                            .padding()
                    }
                    ForEach(network.recipes) { recipe in
                        NavigationLink(destination: CookView(recipe: recipe).environmentObject(network)) {
                            RecipeCardView(recipe: recipe, edit: false)
                                .padding(.horizontal, 5)
                        }
                        .accentColor(Color("TextColor"))
                    }
                    .listStyle(.inset)
                }
                .refreshable {
                    fetchRecipes()
                }
            }

            VStack(spacing: 6) {
                // Filter carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(network.categories.sorted(), id: \.self) { cat in
                            FilterChip(label: cat, isSelected: selectedCats.contains(cat)) {
                                toggle(cat, in: &selectedCats)
                            }
                        }
                        ForEach(network.cuisines.sorted(), id: \.self) { cuisine in
                            FilterChip(label: cuisine, isSelected: selectedCuisines.contains(cuisine)) {
                                toggle(cuisine, in: &selectedCuisines)
                            }
                        }
                        ForEach(network.authors.sorted(), id: \.self) { author in
                            FilterChip(label: author, isSelected: selectedAuthors.contains(author)) {
                                toggle(author, in: &selectedAuthors)
                            }
                        }
                        ForEach(network.countries.sorted(), id: \.self) { country in
                            FilterChip(label: country, isSelected: selectedCountries.contains(country)) {
                                toggle(country, in: &selectedCountries)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .frame(minHeight: 32)

                // Search + sort + count
                HStack {
                    TextField("search", text: $search_val)
                        .padding([.leading, .trailing])
                        .focused($search_field_is_focused)
                        .onChange(of: search_val) {
                            fetchRecipes()
                        }
                        .autocorrectionDisabled()
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color("MyPrimaryColor"), lineWidth: 2)
                        )
                    Text("\(network.recipes.count) recipes")
                        .font(.caption)
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
                    .onChange(of: sort_val) {
                        fetchRecipes()
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            fetchRecipes()
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color("MyPrimaryColor") : Color("Base200Color"))
                .foregroundColor(isSelected ? .black : Color("TextColor"))
                .cornerRadius(12)
        }
    }
}

#Preview {
    RecipesView()
        .environmentObject(Network())
}
