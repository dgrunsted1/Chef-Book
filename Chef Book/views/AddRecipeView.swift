//
//  AddRecipeView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI
import PhotosUI

struct AddRecipeView: View {
    @EnvironmentObject var network: Network

    @State private var showUrlImport = true
    @State private var importUrl = ""
    @State private var isImporting = false
    @State private var isSaving = false

    // Form fields
    @State private var title = ""
    @State private var desc = ""
    @State private var author = ""
    @State private var category = ""
    @State private var cuisine = ""
    @State private var country = ""
    @State private var timeMinutes = ""
    @State private var servings = ""
    @State private var sourceUrl = ""
    @State private var imageUrl = ""

    // Ingredients & Directions
    @State private var ingredients: [EditableIngredient] = [EditableIngredient()]
    @State private var directions: [String] = [""]

    // Image
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?

    // Alerts
    @State private var alertMessage = ""
    @State private var showAlert = false

    var body: some View {
        if network.user != nil {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if showUrlImport {
                        urlImportSection
                    } else {
                        recipeFormSection
                    }
                }
                .padding()
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
        } else {
            LoginView()
                .environmentObject(network)
        }
    }

    // MARK: - URL Import Section

    private var urlImportSection: some View {
        VStack(spacing: 16) {
            Text("Add a Recipe")
                .font(.title2)
                .bold()

            TextField("Paste recipe URL...", text: $importUrl)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocorrectionDisabled()
            Button(action: importFromUrl) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("MyPrimaryColor"))
                        .frame(height: 44)
                    if isImporting {
                        ProgressView()
                    } else {
                        Text("Import from URL")
                            .foregroundColor(.black)
                            .bold()
                    }
                }
            }
            .disabled(importUrl.isEmpty || isImporting)

            Text("or")
                .foregroundColor(.gray)

            Button(action: {
                showUrlImport = false
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color("MyPrimaryColor"), lineWidth: 2)
                        .frame(height: 44)
                    Text("Input Manually")
                        .foregroundColor(Color("TextColor"))
                        .bold()
                }
            }
        }
    }

    // MARK: - Recipe Form

    private var recipeFormSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: { showUrlImport = true }) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("Back to import")
                }
            }

            Group {
                TextField("Title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.title3)

                TextField("Description", text: $desc, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)

                HStack {
                    TextField("Author", text: $author)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Category", text: $category)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                HStack {
                    TextField("Cuisine", text: $cuisine)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Country", text: $country)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                HStack {
                    TextField("Time (min)", text: $timeMinutes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Servings", text: $servings)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                TextField("Source URL", text: $sourceUrl)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled()

                TextField("Image URL", text: $imageUrl)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled()
            }

            // Image preview
            if !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(10)
                } placeholder: {
                    ProgressView()
                }
            }

            // Photo picker
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack {
                    Image(systemName: "photo")
                    Text("Choose from Photos")
                }
            }
            .onChange(of: selectedPhoto) {
                Task {
                    if let data = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }

            if selectedImageData != nil {
                Text("Photo selected")
                    .foregroundColor(.green)
                    .font(.caption)
            }

            // Ingredients
            ingredientEditor

            // Directions
            directionEditor

            // Save button
            Button(action: saveRecipe) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color("MyPrimaryColor"))
                        .frame(height: 50)
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save Recipe")
                            .foregroundColor(.black)
                            .bold()
                            .font(.title3)
                    }
                }
            }
            .disabled(title.isEmpty || isSaving)
        }
    }

    // MARK: - Ingredient Editor

    private var ingredientEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Ingredients")
                    .font(.headline)
                Spacer()
                Button(action: {
                    ingredients.append(EditableIngredient())
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color("MyPrimaryColor"))
                }
            }

            ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, ingredient in
                HStack {
                    TextField("Qty", text: $ingredients[index].quantity)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 50)
                    TextField("Unit", text: $ingredients[index].unit)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 70)
                    TextField("Ingredient name", text: $ingredients[index].name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    if ingredients.count > 1 {
                        Button(action: {
                            ingredients.remove(at: index)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Direction Editor

    private var directionEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Directions")
                    .font(.headline)
                Spacer()
                Button(action: {
                    directions.append("")
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color("MyPrimaryColor"))
                }
            }

            ForEach(Array(directions.enumerated()), id: \.offset) { index, _ in
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .bold()
                        .padding(.top, 8)
                    TextField("Step \(index + 1)", text: $directions[index], axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...5)
                    if directions.count > 1 {
                        Button(action: {
                            directions.remove(at: index)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func importFromUrl() {
        guard !importUrl.isEmpty else { return }
        isImporting = true
        network.scrape_recipe(url: importUrl) { result in
            isImporting = false
            if let result = result {
                title = result["title"] as? String ?? ""
                desc = result["description"] as? String ?? ""
                author = result["author"] as? String ?? ""
                category = result["category"] as? String ?? ""
                cuisine = result["cuisine"] as? String ?? ""
                country = result["country"] as? String ?? ""
                sourceUrl = importUrl
                imageUrl = result["image"] as? String ?? ""

                if let timeVal = result["time"] as? Int {
                    timeMinutes = String(timeVal)
                }
                if let servingsVal = result["servings"] as? String {
                    servings = servingsVal
                } else if let servingsVal = result["servings"] as? Int {
                    servings = String(servingsVal)
                }

                if let ingrList = result["ingredients"] as? [String] {
                    ingredients = ingrList.map { IngredientParser.parse($0) }
                    if ingredients.isEmpty { ingredients = [EditableIngredient()] }
                }

                if let dirList = result["directions"] as? [String] {
                    directions = dirList
                    if directions.isEmpty { directions = [""] }
                }

                showUrlImport = false
            } else {
                alertMessage = "Could not import recipe from URL"
                showAlert = true
            }
        }
    }

    private func saveRecipe() {
        guard !title.isEmpty else { return }
        isSaving = true

        let saveBlock: (String?) -> Void = { uploadedImageUrl in
            let finalImage = uploadedImageUrl ?? imageUrl
            let ingrDicts = ingredients
                .filter { !$0.name.isEmpty }
                .map { $0.toDict() }
            let filteredDirections = directions.filter { !$0.isEmpty }
            let timeVal = Int(timeMinutes) ?? 0

            let recipe: [String: Any] = [
                "title": title,
                "description": desc,
                "author": author,
                "category": category,
                "cuisine": cuisine,
                "country": country,
                "time_new": timeVal,
                "servings": servings,
                "url": sourceUrl,
                "image": finalImage,
                "directions": filteredDirections,
                "ingredients": ingrDicts,
                "user": network.user?.record.id ?? ""
            ]

            network.save_recipe(recipe: recipe) { success, error in
                isSaving = false
                if success {
                    // Reset form
                    title = ""
                    desc = ""
                    author = ""
                    category = ""
                    cuisine = ""
                    country = ""
                    timeMinutes = ""
                    servings = ""
                    sourceUrl = ""
                    imageUrl = ""
                    ingredients = [EditableIngredient()]
                    directions = [""]
                    selectedImageData = nil
                    selectedPhoto = nil
                    showUrlImport = true
                    alertMessage = "Recipe saved!"
                    showAlert = true
                } else {
                    alertMessage = error ?? "Failed to save recipe"
                    showAlert = true
                }
            }
        }

        // Upload image if selected from photos
        if let imageData = selectedImageData {
            network.upload_image(imageData: imageData) { photoUrl in
                saveBlock(photoUrl)
            }
        } else {
            saveBlock(nil)
        }
    }
}

#Preview {
    AddRecipeView()
        .environmentObject(Network())
}
