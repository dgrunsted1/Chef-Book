//
//  CreateMenuView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI

struct CreateMenuView: View {
    @EnvironmentObject var network: Network
    @State private var searchText = ""
    @State private var selectedRecipeIds: Set<String> = []
    @State private var showMenuSheet = false

    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return network.recipes
        }
        return network.recipes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedRecipes: [Recipe] {
        network.recipes.filter { selectedRecipeIds.contains($0.id) }
    }

    var body: some View {
        if network.user != nil {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search recipes...", text: $searchText)
                        .autocorrectionDisabled()
                }
                .padding(10)
                .background(Color("Base200Color"))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)

                // Recipe list
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredRecipes) { recipe in
                            HStack {
                                Button(action: {
                                    if selectedRecipeIds.contains(recipe.id) {
                                        selectedRecipeIds.remove(recipe.id)
                                    } else {
                                        selectedRecipeIds.insert(recipe.id)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: selectedRecipeIds.contains(recipe.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedRecipeIds.contains(recipe.id) ? Color("MyPrimaryColor") : .gray)
                                            .font(.title3)

                                        if recipe.image != "" {
                                            AsyncImage(url: URL(string: recipe.image)) { image in
                                                image.resizable()
                                                    .scaledToFill()
                                                    .frame(width: 50, height: 50)
                                                    .clipped()
                                                    .cornerRadius(8)
                                            } placeholder: {
                                                ProgressView()
                                                    .frame(width: 50, height: 50)
                                            }
                                        }

                                        VStack(alignment: .leading) {
                                            Text(recipe.title)
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(Color("TextColor"))
                                            Text("\(recipe.ingredients.count) ingredients")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Bottom bar
                if !selectedRecipeIds.isEmpty {
                    HStack {
                        Text("\(selectedRecipeIds.count) recipes selected")
                            .bold()
                        Spacer()
                        Button(action: { showMenuSheet = true }) {
                            Text("Create Menu")
                                .bold()
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color("MyPrimaryColor"))
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color("Base200Color"))
                }
            }
            .onAppear {
                if network.recipes.isEmpty {
                    network.getRecipes()
                }
            }
            .sheet(isPresented: $showMenuSheet) {
                MenuDetailSheet(isPresented: $showMenuSheet, selectedRecipes: selectedRecipes)
                    .environmentObject(network)
            }
        } else {
            LoginView()
                .environmentObject(network)
        }
    }
}

#Preview {
    CreateMenuView()
        .environmentObject(Network())
}
