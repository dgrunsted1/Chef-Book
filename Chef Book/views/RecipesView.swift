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
    @State private var expandedFilter: String? = nil
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
                // Filter accordion headers
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        FilterHeaderButton(title: "Category", count: selectedCats.count, isExpanded: expandedFilter == "Category") {
                            expandedFilter = expandedFilter == "Category" ? nil : "Category"
                        }
                        FilterHeaderButton(title: "Cuisine", count: selectedCuisines.count, isExpanded: expandedFilter == "Cuisine") {
                            expandedFilter = expandedFilter == "Cuisine" ? nil : "Cuisine"
                        }
                        FilterHeaderButton(title: "Author", count: selectedAuthors.count, isExpanded: expandedFilter == "Author") {
                            expandedFilter = expandedFilter == "Author" ? nil : "Author"
                        }
                        FilterHeaderButton(title: "Country", count: selectedCountries.count, isExpanded: expandedFilter == "Country") {
                            expandedFilter = expandedFilter == "Country" ? nil : "Country"
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .frame(minHeight: 32)

                // Expanded filter chips
                if let expanded = expandedFilter {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            if expanded == "Category" {
                                ForEach(network.categories.sorted(), id: \.self) { cat in
                                    FilterChip(label: cat, isSelected: selectedCats.contains(cat)) {
                                        toggle(cat, in: &selectedCats)
                                    }
                                }
                            } else if expanded == "Cuisine" {
                                ForEach(network.cuisines.sorted(), id: \.self) { cuisine in
                                    FilterChip(label: cuisine, isSelected: selectedCuisines.contains(cuisine)) {
                                        toggle(cuisine, in: &selectedCuisines)
                                    }
                                }
                            } else if expanded == "Author" {
                                ForEach(network.authors.sorted(), id: \.self) { author in
                                    FilterChip(label: author, isSelected: selectedAuthors.contains(author)) {
                                        toggle(author, in: &selectedAuthors)
                                    }
                                }
                            } else if expanded == "Country" {
                                ForEach(network.countries.sorted(), id: \.self) { country in
                                    FilterChip(label: country, isSelected: selectedCountries.contains(country)) {
                                        toggle(country, in: &selectedCountries)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Sort + recipe count + search
                HStack(spacing: 8) {
                    Menu {
                        ForEach(sort_options, id: \.self) { option in
                            Button(action: { sort_val = option }) {
                                HStack {
                                    Text(option)
                                    if sort_val == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.caption2)
                            Text(sort_val)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color("MyPrimaryColor"))
                        .foregroundColor(.black)
                        .cornerRadius(10)
                    }
                    .onChange(of: sort_val) {
                        fetchRecipes()
                    }

                    Text("\(network.recipes.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color("TextColor"))

                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundColor(.gray)
                        TextField("Search recipes...", text: $search_val)
                            .font(.callout)
                            .focused($search_field_is_focused)
                            .onChange(of: search_val) {
                                fetchRecipes()
                            }
                            .autocorrectionDisabled()
                        if !search_val.isEmpty {
                            Button(action: { search_val = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color("Base200Color"))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(search_field_is_focused ? Color("MyPrimaryColor") : Color.clear, lineWidth: 1.5)
                    )
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            fetchRecipes()
        }
        .onChange(of: selectedCats) { fetchRecipes() }
        .onChange(of: selectedCuisines) { fetchRecipes() }
        .onChange(of: selectedCountries) { fetchRecipes() }
        .onChange(of: selectedAuthors) { fetchRecipes() }
    }
}

struct FilterHeaderButton: View {
    let title: String
    let count: Int
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        }) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.weight(.bold))
                        .frame(width: 16, height: 16)
                        .background(Color("MyPrimaryColor"))
                        .foregroundColor(.black)
                        .clipShape(Circle())
                }
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isExpanded ? Color("MyPrimaryColor") : Color("Base200Color"))
            .foregroundColor(isExpanded ? .black : Color("TextColor"))
            .cornerRadius(14)
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
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
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
