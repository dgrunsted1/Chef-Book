//
//  MenuDetailSheet.swift
//  Chef Book
//

import SwiftUI

struct MenuDetailSheet: View {
    @EnvironmentObject var network: Network
    @Binding var isPresented: Bool
    let selectedRecipes: [Recipe]
    @State var menuTitle: String = ""
    @State var servings: [String: String] = [:]
    @State var isSaving = false
    @State var alertMessage = ""
    @State var showAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("Menu Title", text: $menuTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)

                    Text("\(selectedRecipes.count) recipes selected")
                        .font(.subheadline)
                        .foregroundColor(.gray)

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
                                .keyboardType(.numberPad)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }
            .navigationTitle("New Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveMenu) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .bold()
                        }
                    }
                    .disabled(menuTitle.isEmpty || isSaving)
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK") {
                    if alertMessage.contains("saved") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func saveMenu() {
        guard !menuTitle.isEmpty else { return }
        isSaving = true

        // Fill in default servings for recipes that weren't adjusted
        for recipe in selectedRecipes {
            if servings[recipe.id] == nil {
                servings[recipe.id] = recipe.servings
            }
        }

        let recipeIds = selectedRecipes.map { $0.id }
        network.create_menu(title: menuTitle, recipeIds: recipeIds, servings: servings) { success in
            isSaving = false
            if success {
                alertMessage = "Menu saved!"
                showAlert = true
            } else {
                alertMessage = "Failed to save menu"
                showAlert = true
            }
        }
    }
}
