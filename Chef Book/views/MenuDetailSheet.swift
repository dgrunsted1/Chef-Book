//
//  MenuDetailSheet.swift
//  Chef Book
//

import SwiftUI

struct MenuDetailSheet: View {
    @EnvironmentObject var network: Network
    @Binding var isPresented: Bool
    let selectedRecipes: [Recipe]
    var onMenuCreated: ((String) -> Void)? = nil
    @State var menuTitle: String = ""
    @State var servings: [String: String] = [:]
    @State var isSaving = false
    @State var alertMessage = ""
    @State var showAlert = false
    @State private var selectedTab = 0

    private var totalServings: Int {
        selectedRecipes.reduce(0) { sum, recipe in
            let srv = servings[recipe.id] ?? recipe.servings
            return sum + (Int(srv) ?? 0)
        }
    }

    private var totalTimeSeconds: Int {
        selectedRecipes.reduce(0) { $0 + $1.time_in_seconds }
    }

    private var groceryPreview: [GroceryListGenerator.GroceryItem] {
        var effectiveServings = servings
        for recipe in selectedRecipes {
            if effectiveServings[recipe.id] == nil {
                effectiveServings[recipe.id] = recipe.servings
            }
        }
        return GroceryListGenerator.generate(recipes: selectedRecipes, servings: effectiveServings)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Pull-up handle
            Image(systemName: "chevron.up")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 10)

            // Summary stats
            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("\(selectedRecipes.count)")
                        .font(.headline)
                    Text("Recipes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                VStack(spacing: 2) {
                    Text(totalTimeSeconds > 0 ? Network.formatTime(totalTimeSeconds) : "—")
                        .font(.headline)
                    Text("Time")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                VStack(spacing: 2) {
                    Text("\(totalServings)")
                        .font(.headline)
                    Text("Servings")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)

            Divider()

            // Title field + Save button
            HStack {
                TextField("Menu Title", text: $menuTitle)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)

                Button(action: saveMenu) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .bold()
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(menuTitle.isEmpty ? Color.gray.opacity(0.3) : Color("MyPrimaryColor"))
                            .cornerRadius(8)
                    }
                }
                .disabled(menuTitle.isEmpty || isSaving)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

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
        .alert(alertMessage, isPresented: $showAlert) {
            Button("OK") {}
        }
        .onAppear {
            network.loadRecipeDetailsIfNeeded(for: selectedRecipes.map(\.id))
        }
        .onChange(of: selectedRecipes.map(\.id)) {
            network.loadRecipeDetailsIfNeeded(for: selectedRecipes.map(\.id))
        }
    }

    private var recipesTab: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(selectedRecipes) { recipe in
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
                            Text("Original: \(recipe.servings) servings")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        HStack {
                            Text("Servings:")
                                .font(.caption)
                            TextField("", text: Binding(
                                get: { servings[recipe.id] ?? recipe.servings },
                                set: { servings[recipe.id] = $0 }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
            .padding(.top, 8)
        }
    }

    private var groceryTab: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                if groceryPreview.isEmpty {
                    Text("No ingredients")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(groceryPreview) { item in
                        HStack(spacing: 4) {
                            if item.qty > 0 {
                                Text(formatQuantity(item.qty))
                                    .font(.callout)
                                    .bold()
                            }
                            if !item.unit.isEmpty {
                                Text(item.unit)
                                    .font(.callout)
                            }
                            Text(item.name)
                                .font(.callout)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private func formatQuantity(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%g", value)
    }

    private func saveMenu() {
        guard !menuTitle.isEmpty else { return }
        isSaving = true

        for recipe in selectedRecipes {
            if servings[recipe.id] == nil {
                servings[recipe.id] = recipe.servings
            }
        }

        let recipeIds = selectedRecipes.map { $0.id }
        network.create_menu(title: menuTitle, recipeIds: recipeIds, servings: servings) { menuId in
            isSaving = false
            if let menuId = menuId {
                isPresented = false
                onMenuCreated?(menuId)
            } else {
                alertMessage = "Failed to save menu"
                showAlert = true
            }
        }
    }
}
