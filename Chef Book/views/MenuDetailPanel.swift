//
//  MenuDetailPanel.swift
//  Chef Book
//

import SwiftUI

struct MenuDetailPanel: View {
    @EnvironmentObject var network: Network
    let menuId: String
    var onDismiss: () -> Void

    @State private var selectedTab = 0
    @State private var isRemoving: String? = nil

    private var menu: MyMenu? {
        network.menus.first(where: { $0.id == menuId })
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(menu?.title ?? "Menu")
                    .font(.headline)
                    .bold()
                Spacer()
                Button("Done") {
                    onDismiss()
                }
                .bold()
                .foregroundColor(Color("MyPrimaryColor"))
            }
            .padding()

            // Segmented picker
            Picker("", selection: $selectedTab) {
                Text("Recipes").tag(0)
                Text("Grocery List").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Tab content
            if selectedTab == 0 {
                recipesTab
            } else {
                groceryTab
            }
        }
    }

    private var recipesTab: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if let menu = menu {
                    if menu.recipes.isEmpty {
                        Text("No recipes yet")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                    } else {
                        ForEach(menu.recipes) { recipe in
                            HStack {
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
                                    if let srv = menu.servings[recipe.id] {
                                        Text("\(srv) servings")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                Spacer()
                                Button {
                                    removeRecipe(recipe.id)
                                } label: {
                                    if isRemoving == recipe.id {
                                        ProgressView()
                                            .frame(width: 20, height: 20)
                                    } else {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.title3)
                                    }
                                }
                                .buttonStyle(.plain)
                                .disabled(isRemoving != nil)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private var groceryTab: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                if let menu = menu {
                    if menu.grocery_list.isEmpty {
                        Text("No grocery list")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                    } else {
                        ForEach(menu.grocery_list) { item in
                            GroceryItemRow(item: item, groceryListId: menu.grocery_list_id)
                                .environmentObject(network)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private func removeRecipe(_ recipeId: String) {
        guard let menu = menu else { return }
        isRemoving = recipeId

        let updatedRecipeIds = menu.recipes.map(\.id).filter { $0 != recipeId }
        var updatedServings = menu.servings
        updatedServings.removeValue(forKey: recipeId)

        let fields: [String: Any] = [
            "recipes": updatedRecipeIds,
            "servings": updatedServings
        ]
        network.update_menu(id: menuId, fields: fields) { success in
            isRemoving = nil
            if success {
                network.get_menus()
            }
        }
    }
}
