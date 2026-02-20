//
//  CookView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/30/24.
//

import SwiftUI
import AudioToolbox
import UserNotifications

// MARK: - EditSheet

private struct EditSheetField {
    let label: String
    let placeholder: String
    var value: String
    var isMultiline: Bool = false
    var isNumberKeyboard: Bool = false
}

private struct EditSheet: View {
    let title: String
    @State var fields: [EditSheetField]
    let onSave: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Int?

    var body: some View {
        #if os(macOS)
        macOSBody
        #else
        iOSBody
        #endif
    }

    #if os(iOS)
    private var iOSBody: some View {
        NavigationStack {
            Form {
                ForEach(fields.indices, id: \.self) { i in
                    Section(fields[i].label) {
                        if fields[i].isMultiline {
                            TextField(fields[i].placeholder, text: $fields[i].value, axis: .vertical)
                                .lineLimit(5...15)
                                .focused($focusedField, equals: i)
                        } else {
                            TextField(fields[i].placeholder, text: $fields[i].value)
                                .keyboardType(fields[i].isNumberKeyboard ? .decimalPad : .default)
                                .focused($focusedField, equals: i)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(fields.map { $0.value })
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("MyPrimaryColor"))
                }
            }
            .onAppear { focusedField = 0 }
        }
    }
    #endif

    #if os(macOS)
    private var macOSBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 16)

            ForEach(fields.indices, id: \.self) { i in
                Text(fields[i].label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)

                if fields[i].isMultiline {
                    TextField(fields[i].placeholder, text: $fields[i].value, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(5...15)
                        .padding(8)
                        .background(Color("Base200Color").opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .focused($focusedField, equals: i)
                } else {
                    TextField(fields[i].placeholder, text: $fields[i].value)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color("Base200Color").opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .focused($focusedField, equals: i)
                        .onSubmit { save() }
                }

                if i < fields.count - 1 {
                    Spacer().frame(height: 12)
                }
            }

            Spacer().frame(height: 20)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(Color("MyPrimaryColor"))
            }
        }
        .padding(24)
        .frame(minWidth: 360)
        .onAppear { focusedField = 0 }
    }
    #endif

    private func save() {
        onSave(fields.map { $0.value })
        dismiss()
    }
}

// MARK: - EditableField

private struct EditableField: View {
    let label: String
    let systemImage: String?
    let font: Font
    let color: Color
    let isBold: Bool
    let sheetTitle: String
    let onSave: (String) -> Void

    @State private var showSheet = false

    init(_ label: String, systemImage: String? = nil, font: Font = .body, color: Color = Color("TextColor"), isBold: Bool = false, sheetTitle: String = "Edit", onSave: @escaping (String) -> Void) {
        self.label = label
        self.systemImage = systemImage
        self.font = font
        self.color = color
        self.isBold = isBold
        self.sheetTitle = sheetTitle
        self.onSave = onSave
    }

    var body: some View {
        Group {
            if let systemImage {
                Label(label, systemImage: systemImage)
                    .font(font)
            } else {
                Text(label)
                    .font(font)
                    .bold(isBold)
            }
        }
        .foregroundColor(color)
        .contentShape(Rectangle())
        .onTapGesture { showSheet = true }
        .sheet(isPresented: $showSheet) {
            EditSheet(
                title: sheetTitle,
                fields: [EditSheetField(label: sheetTitle, placeholder: sheetTitle, value: label)],
                onSave: { values in
                    let trimmed = values[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty && trimmed != label {
                        onSave(trimmed)
                    }
                }
            )
        }
    }
}

// MARK: - EditableTagPill

private struct EditableTagPill: View {
    let text: String
    let placeholder: String
    let onSave: (String) -> Void

    @State private var showSheet = false

    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color("MyPrimaryColor").opacity(0.2))
            .foregroundColor(Color("TextColor"))
            .clipShape(Capsule())
            .contentShape(Rectangle())
            .onTapGesture { showSheet = true }
            .sheet(isPresented: $showSheet) {
                EditSheet(
                    title: "Edit \(placeholder)",
                    fields: [EditSheetField(label: placeholder, placeholder: placeholder, value: text)],
                    onSave: { values in
                        let trimmed = values[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty && trimmed != text {
                            onSave(trimmed)
                        }
                    }
                )
            }
    }
}

// MARK: - ServingsField

private struct ServingsField: View {
    @Binding var menuServings: String
    @State private var showSheet = false

    var body: some View {
        HStack(spacing: 4) {
            Label("\(menuServings) servings", systemImage: "person.2")
                .font(.caption)
                .foregroundColor(Color("TextColor").opacity(0.7))
        }
        .contentShape(Rectangle())
        .onTapGesture { showSheet = true }
        .sheet(isPresented: $showSheet) {
            EditSheet(
                title: "Edit Servings",
                fields: [EditSheetField(label: "Servings", placeholder: "Servings", value: menuServings, isNumberKeyboard: true)],
                onSave: { values in
                    let trimmed = values[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        menuServings = trimmed
                    }
                }
            )
        }
    }
}

// MARK: - CookView

struct CookView: View {
    @EnvironmentObject var network: Network
    @State var recipe: Recipe
    @State var is_made: Bool
    @State var is_menu_made: Bool
    @State var is_favorite: Bool
    @State var menuServings: String
    let hasMenuContext: Bool
    @State var isLoadingDetail: Bool = false
    @State private var blurredIngredients: Set<Int> = []
    @State private var blurredDirections: Set<Int> = []
    @State private var timers: [Int: CookTimer] = [:]
    @State private var viewportHeight: CGFloat = 600

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    init(recipe: Recipe, menuMade: Bool = false, menuServings: String = "") {
        _recipe = State(initialValue: recipe)
        _is_made = State(initialValue: recipe.made)
        _is_menu_made = State(initialValue: menuMade)
        _is_favorite = State(initialValue: recipe.favorite)
        _menuServings = State(initialValue: menuServings)
        self.hasMenuContext = !menuServings.isEmpty
    }

    private var servingMultiplier: Double {
        guard let target = Double(menuServings),
              let original = Double(recipe.servings),
              original > 0 else { return 1.0 }
        return target / original
    }

    private var useSplitLayout: Bool {
        #if os(macOS)
        return true
        #else
        return horizontalSizeClass == .regular
        #endif
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                CookHeaderView(recipe: $recipe, menuServings: $menuServings, hasMenuContext: hasMenuContext, network: network)

                CookActionBar(
                    recipe: recipe,
                    is_made: $is_made,
                    is_menu_made: $is_menu_made,
                    is_favorite: $is_favorite,
                    network: network
                )
                .padding(.horizontal)
                .padding(.vertical, 12)

                if useSplitLayout {
                    let paneHeight = viewportHeight - 60 // leave room for padding
                    GeometryReader { geo in
                        let availableWidth = geo.size.width - 32 - 16 // 32 for horizontal padding, 16 for spacing
                        HStack(alignment: .top, spacing: 16) {
                            CookIngredientsPane(
                                recipe: $recipe,
                                network: network,
                                blurred: $blurredIngredients,
                                servingMultiplier: servingMultiplier
                            )
                            .frame(width: availableWidth * 2 / 5)

                            CookDirectionsPane(
                                recipe: $recipe,
                                network: network,
                                blurred: $blurredDirections,
                                timers: $timers
                            )
                            .frame(width: availableWidth * 3 / 5)
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: paneHeight)
                } else {
                    let paneHeight = viewportHeight - 60
                    GeometryReader { geo in
                        VStack(spacing: 16) {
                            CookIngredientsPane(
                                recipe: $recipe,
                                network: network,
                                blurred: $blurredIngredients,
                                servingMultiplier: servingMultiplier
                            )
                            .frame(height: min(CGFloat(recipe.ingredients.count * 38 + 40), paneHeight * 0.35))

                            CookDirectionsPane(
                                recipe: $recipe,
                                network: network,
                                blurred: $blurredDirections,
                                timers: $timers
                            )
                            .frame(height: paneHeight * 0.6)
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: paneHeight)
                }

                CookNotesSection(
                    recipe: $recipe,
                    network: network
                )
                .padding(.horizontal)
                .padding(.top, 20)
            }
        }
        .background(
            GeometryReader { proxy in
                Color("BaseColor")
                    .onAppear { viewportHeight = proxy.size.height }
                    .onChange(of: proxy.size.height) { _, newHeight in
                        viewportHeight = newHeight
                    }
            }
        )
        .overlay {
            if isLoadingDetail {
                ProgressView()
            }
        }
        .refreshable {
            await withCheckedContinuation { continuation in
                network.getRecipeDetail(urlId: recipe.url_id) { detail in
                    if let detail = detail {
                        recipe = detail
                        is_made = detail.made
                        is_menu_made = network.today?.made[detail.id] ?? false
                        is_favorite = detail.favorite
                    }
                    continuation.resume()
                }
            }
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
            if !recipe.isDetailLoaded {
                isLoadingDetail = true
            }
            network.getRecipeDetail(urlId: recipe.url_id) { detail in
                isLoadingDetail = false
                if let detail = detail {
                    recipe = detail
                    is_made = detail.made
                    is_menu_made = network.today?.made[detail.id] ?? false
                    is_favorite = detail.favorite
                }
            }
        }
        .onDisappear {
            timers.values.forEach { $0.pause() }
            recipe.made = is_made
            recipe.favorite = is_favorite
            if let idx = network.recipes.firstIndex(where: { $0.id == recipe.id }) {
                network.recipes[idx] = recipe
            }
            if let idx = network.today?.recipes.firstIndex(where: { $0.id == recipe.id }) {
                network.today?.recipes[idx] = recipe
            }
            network.today?.made[recipe.id] = is_menu_made
            // Persist menu servings if changed
            if !menuServings.isEmpty, let today = network.today {
                let originalMenuServings = today.servings[recipe.id] ?? recipe.servings
                if menuServings != originalMenuServings {
                    network.today?.servings[recipe.id] = menuServings
                    if var updatedServings = network.today?.servings {
                        updatedServings[recipe.id] = menuServings
                        network.update_menu(id: today.id, fields: ["servings": updatedServings]) { _ in }
                    }
                }
            }
        }
        .ignoresSafeArea(.container, edges: .top)
        #if os(iOS)
        .toolbarBackground(.hidden, for: .navigationBar)
        #endif
    }
}

// MARK: - CookHeaderView

private struct CookHeaderView: View {
    @Binding var recipe: Recipe
    @Binding var menuServings: String
    let hasMenuContext: Bool
    let network: Network

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if !recipe.image.isEmpty {
                AsyncImage(url: URL(string: recipe.image)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(height: 280)
                            .clipped()
                    case .failure:
                        Color("Base200Color")
                            .frame(height: 280)
                    default:
                        ZStack {
                            Color("Base200Color")
                            ProgressView()
                        }
                        .frame(height: 280)
                    }
                }
            }

            // Gradient overlay — only covers bottom third
            VStack(spacing: 0) {
                Color.clear
                LinearGradient(
                    colors: [.clear, Color("BaseColor").opacity(0.8), Color("BaseColor")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)
            }
            .frame(height: 280)

            // Text overlay
            VStack(alignment: .leading, spacing: 4) {
                EditableField(recipe.title, font: .title, isBold: true, sheetTitle: "Edit Title") { newValue in
                    recipe.title = newValue
                    network.update_recipe(id: recipe.id, fields: ["title": newValue]) { _ in }
                }

                if !recipe.desc.isEmpty {
                    EditableField(recipe.desc, font: .subheadline, color: Color("TextColor").opacity(0.8), sheetTitle: "Edit Description") { newValue in
                        recipe.desc = newValue
                        network.update_recipe(id: recipe.id, fields: ["description": newValue]) { _ in }
                    }
                }

                HStack(spacing: 12) {
                    if !recipe.author.isEmpty {
                        EditableField(recipe.author, systemImage: "person", font: .caption, color: Color("TextColor").opacity(0.7), sheetTitle: "Edit Author") { newValue in
                            recipe.author = newValue
                            network.update_recipe(id: recipe.id, fields: ["author": newValue]) { _ in }
                        }
                    }
                    if recipe.time_in_seconds > 0 {
                        EditableField(Network.formatTime(recipe.time_in_seconds), systemImage: "clock", font: .caption, color: Color("TextColor").opacity(0.7), sheetTitle: "Edit Time (minutes)") { newValue in
                            if let minutes = Int(newValue) {
                                recipe.time_in_seconds = minutes * 60
                                network.update_recipe(id: recipe.id, fields: ["time_new": minutes]) { _ in }
                            }
                        }
                    } else if !recipe.time_display.isEmpty {
                        EditableField(recipe.time_display, systemImage: "clock", font: .caption, color: Color("TextColor").opacity(0.7), sheetTitle: "Edit Time (minutes)") { newValue in
                            if let minutes = Int(newValue) {
                                recipe.time_in_seconds = minutes * 60
                                network.update_recipe(id: recipe.id, fields: ["time_new": minutes]) { _ in }
                            }
                        }
                    }
                    if !recipe.servings.isEmpty {
                        if hasMenuContext {
                            ServingsField(menuServings: $menuServings)
                        } else {
                            EditableField("\(recipe.servings) servings", systemImage: "person.2", font: .caption, color: Color("TextColor").opacity(0.7), sheetTitle: "Edit Servings") { newValue in
                                let cleaned = newValue.replacingOccurrences(of: " servings", with: "")
                                recipe.servings = cleaned
                                network.update_recipe(id: recipe.id, fields: ["servings": cleaned]) { _ in }
                            }
                        }
                    }
                }

                HStack(spacing: 8) {
                    if !recipe.category.isEmpty {
                        EditableTagPill(text: recipe.category, placeholder: "Category") { newValue in
                            recipe.category = newValue
                            network.update_recipe(id: recipe.id, fields: ["category": newValue]) { _ in }
                        }
                    }
                    if !recipe.cuisine.isEmpty {
                        EditableTagPill(text: recipe.cuisine, placeholder: "Cuisine") { newValue in
                            recipe.cuisine = newValue
                            network.update_recipe(id: recipe.id, fields: ["cuisine": newValue]) { _ in }
                        }
                    }
                    if !recipe.country.isEmpty {
                        EditableTagPill(text: recipe.country, placeholder: "Country") { newValue in
                            recipe.country = newValue
                            network.update_recipe(id: recipe.id, fields: ["country": newValue]) { _ in }
                        }
                    }
                }
                .padding(.top, 2)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }
}

// MARK: - CookActionBar

private struct CookActionBar: View {
    let recipe: Recipe
    @Binding var is_made: Bool
    @Binding var is_menu_made: Bool
    @Binding var is_favorite: Bool
    let network: Network

    var body: some View {
        HStack(spacing: 16) {
            if !recipe.link_to_original_web_page.isEmpty,
               let url = URL(string: recipe.link_to_original_web_page) {
                Link(destination: url) {
                    Label("Original", systemImage: "link")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("Base200Color"))
                        .clipShape(Capsule())
                }
                .foregroundColor(Color("TextColor"))
            }

            Spacer()

            HStack(spacing: 12) {
                Toggle("", isOn: $is_menu_made)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .onChange(of: is_menu_made) {
                        network.toggle_menu_made(recipeId: recipe.id, value: is_menu_made) { _ in }
                        if is_menu_made {
                            is_made = true
                        }
                    }

                Button {
                    is_made.toggle()
                    network.toggle_made(recipeId: recipe.id, value: is_made) { _ in }
                } label: {
                    Image(systemName: is_made ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.title3)
                        .foregroundColor(is_made ? Color("MyPrimaryColor") : Color("NeutralColor"))
                }
                .buttonStyle(.plain)

                Button {
                    is_favorite.toggle()
                    network.toggle_favorite(recipeId: recipe.id, value: is_favorite) { _ in }
                } label: {
                    Image(systemName: is_favorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(is_favorite ? Color("MyPrimaryColor") : Color("NeutralColor"))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - IngredientEditState

private struct IngredientEditState: Identifiable, Equatable {
    let id = UUID()
    let index: Int
    let isNew: Bool
    var qty: String
    var unit: String
    var name: String
}

// MARK: - CookIngredientsPane

private struct CookIngredientsPane: View {
    @Binding var recipe: Recipe
    let network: Network
    @Binding var blurred: Set<Int>
    let servingMultiplier: Double
    @State private var sheetIngredient: IngredientEditState?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Ingredients")
                    .font(.headline)
                Spacer()
                Button {
                    let blank = Ingredient(id: "", quantity: 0, unit: "", name: "")
                    recipe.ingredients.append(blank)
                    let newIndex = recipe.ingredients.count - 1
                    sheetIngredient = IngredientEditState(index: newIndex, isNew: true, qty: "", unit: "", name: "")
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(Color("MyPrimaryColor"))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 8)

            List {
                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { index, ingredient in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if blurred.contains(index) {
                                blurred.remove(index)
                            } else {
                                blurred.insert(index)
                            }
                        }
                    } label: {
                        IngredientRowView(
                            ingredient: ingredient,
                            servingMultiplier: servingMultiplier,
                            isBlurred: blurred.contains(index)
                        )
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if recipe.ingredients.count > 1 {
                            Button(role: .destructive) {
                                let ingrId = recipe.ingredients[index].id
                                recipe.ingredients.remove(at: index)
                                blurred = Set(blurred.compactMap { $0 > index ? $0 - 1 : ($0 == index ? nil : $0) })
                                network.delete_ingredient(id: ingrId, recipeId: recipe.id) { _ in }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        Button {
                            sheetIngredient = IngredientEditState(
                                index: index,
                                isNew: false,
                                qty: ingredient.quantity == 0 ? "" : String(format: "%g", ingredient.quantity),
                                unit: ingredient.unit,
                                name: ingredient.name
                            )
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Color("MyPrimaryColor"))
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .sheet(item: $sheetIngredient) { state in
            EditSheet(
                title: state.isNew ? "Add Ingredient" : "Edit Ingredient",
                fields: [
                    EditSheetField(label: "Quantity", placeholder: "e.g. 2", value: state.qty, isNumberKeyboard: true),
                    EditSheetField(label: "Unit", placeholder: "e.g. cups", value: state.unit),
                    EditSheetField(label: "Ingredient", placeholder: "e.g. flour", value: state.name)
                ],
                onSave: { values in
                    saveIngredient(at: state.index, isNew: state.isNew, qtyStr: values[0], unit: values[1], name: values[2])
                }
            )
        }
        .onChange(of: sheetIngredient) { oldVal, newVal in
            // If sheet dismissed without saving and it was a new ingredient, remove placeholder
            if oldVal != nil && newVal == nil {
                if let old = oldVal, old.isNew {
                    let idx = old.index
                    if idx < recipe.ingredients.count && recipe.ingredients[idx].id.isEmpty && recipe.ingredients[idx].name.isEmpty {
                        recipe.ingredients.remove(at: idx)
                    }
                }
            }
        }
    }

    private func saveIngredient(at index: Int, isNew: Bool, qtyStr: String, unit: String, name: String) {
        let qty = Double(qtyStr) ?? 0
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            if isNew && index < recipe.ingredients.count {
                recipe.ingredients.remove(at: index)
            }
            return
        }
        let trimmedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.ingredients[index].quantity = qty
        recipe.ingredients[index].unit = trimmedUnit
        recipe.ingredients[index].name = trimmedName
        let fields: [String: Any] = ["quantity": qty, "unit": trimmedUnit, "ingredient": trimmedName]

        if isNew {
            network.create_ingredient(recipeId: recipe.id, fields: fields) { newId in
                if let newId {
                    recipe.ingredients[index] = Ingredient(id: newId, quantity: qty, unit: trimmedUnit, name: trimmedName)
                }
            }
        } else {
            let ingrId = recipe.ingredients[index].id
            network.update_ingredient(id: ingrId, fields: fields) { _ in }
        }
    }
}

// MARK: - IngredientRowView

private struct IngredientRowView: View {
    let ingredient: Ingredient
    let servingMultiplier: Double
    let isBlurred: Bool

    private var displayText: String {
        if servingMultiplier == 1.0 || ingredient.quantity == 0 {
            return ingredient.toString()
        }
        let scaled = ingredient.quantity * servingMultiplier
        var text = String(format: "%g", scaled)
        if !ingredient.unit.isEmpty { text += " \(ingredient.unit)" }
        text += " \(ingredient.name)"
        return text
    }

    var body: some View {
        HStack {
            if isBlurred {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
            Text(displayText)
                .strikethrough(isBlurred)
                .opacity(isBlurred ? 0.3 : 1.0)
            Spacer()
        }
    }
}

// MARK: - DirectionEditState

private struct DirectionEditState: Identifiable, Equatable {
    let id = UUID()
    let index: Int
    let isNew: Bool
    var text: String
}

// MARK: - CookDirectionsPane

private struct CookDirectionsPane: View {
    @Binding var recipe: Recipe
    let network: Network
    @Binding var blurred: Set<Int>
    @Binding var timers: [Int: CookTimer]
    @State private var sheetDirection: DirectionEditState?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Directions")
                    .font(.headline)
                Spacer()
                Button {
                    recipe.directions.append("")
                    let newIndex = recipe.directions.count - 1
                    sheetDirection = DirectionEditState(index: newIndex, isNew: true, text: "")
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(Color("MyPrimaryColor"))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 8)

            List {
                ForEach(Array(recipe.directions.enumerated()), id: \.offset) { index, direction in
                    DirectionRowView(
                        index: index,
                        direction: direction,
                        isBlurred: blurred.contains(index),
                        timer: timers[index],
                        onToggleBlur: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if blurred.contains(index) {
                                    blurred.remove(index)
                                } else {
                                    blurred.insert(index)
                                    // Reset timer to mini state when crossing off
                                    if let timer = timers[index] {
                                        timer.reset()
                                        timers.removeValue(forKey: index)
                                    }
                                }
                            }
                        },
                        onTimerStart: { parsed in
                            if timers[index] == nil {
                                let t = CookTimer(
                                    totalSeconds: parsed.totalSeconds,
                                    displayLabel: parsed.displayLabel,
                                    stepNumber: index + 1,
                                    stepSnippet: direction,
                                    recipeName: recipe.title,
                                    recipeImageURL: recipe.image
                                )
                                timers[index] = t
                                t.start()
                            }
                        },
                        onTimerDismiss: {
                            if let timer = timers[index] {
                                timer.reset()
                                timers.removeValue(forKey: index)
                            }
                        }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if recipe.directions.count > 1 {
                            Button(role: .destructive) {
                                recipe.directions.remove(at: index)
                                blurred = Set(blurred.compactMap { $0 > index ? $0 - 1 : ($0 == index ? nil : $0) })
                                var newTimers: [Int: CookTimer] = [:]
                                for (k, v) in timers {
                                    if k < index { newTimers[k] = v }
                                    else if k > index { newTimers[k - 1] = v }
                                }
                                timers = newTimers
                                pushDirections()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        Button {
                            sheetDirection = DirectionEditState(index: index, isNew: false, text: direction)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(Color("MyPrimaryColor"))
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .sheet(item: $sheetDirection) { state in
            EditSheet(
                title: state.isNew ? "Add Direction" : "Edit Direction",
                fields: [
                    EditSheetField(label: "Step \(state.index + 1)", placeholder: "Direction step...", value: state.text, isMultiline: true)
                ],
                onSave: { values in
                    saveDirection(at: state.index, isNew: state.isNew, text: values[0])
                }
            )
        }
        .onChange(of: sheetDirection) { oldVal, newVal in
            if oldVal != nil && newVal == nil {
                if let old = oldVal, old.isNew {
                    let idx = old.index
                    if idx < recipe.directions.count && recipe.directions[idx].isEmpty {
                        recipe.directions.remove(at: idx)
                    }
                }
            }
        }
    }

    private func saveDirection(at index: Int, isNew: Bool, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            if isNew && index < recipe.directions.count {
                recipe.directions.remove(at: index)
            }
            return
        }
        recipe.directions[index] = trimmed
        pushDirections()
    }

    private func pushDirections() {
        network.update_recipe(id: recipe.id, fields: ["directions": recipe.directions]) { _ in }
    }
}

// MARK: - DirectionRowView

private struct DirectionRowView: View {
    let index: Int
    let direction: String
    let isBlurred: Bool
    let timer: CookTimer?
    let onToggleBlur: () -> Void
    let onTimerStart: (ParsedTimer) -> Void
    let onTimerDismiss: () -> Void

    private var parsedTimers: [ParsedTimer] {
        TimerParser.parse(direction: direction)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Direction text — tapping crosses off/un-crosses the direction
            Button {
                onToggleBlur()
            } label: {
                HStack(alignment: .top) {
                    if isBlurred {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    Text("\(index + 1).")
                        .bold()
                        .foregroundColor(Color("MyPrimaryColor"))
                    Text(direction)
                        .strikethrough(isBlurred)
                        .opacity(isBlurred ? 0.3 : 1.0)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            // Timer buttons — only when no active timer and not crossed out
            if !isBlurred, timer == nil, !parsedTimers.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(parsedTimers.enumerated()), id: \.offset) { _, parsed in
                        Button {
                            onTimerStart(parsed)
                        } label: {
                            Label(parsed.displayLabel, systemImage: "timer")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color("MyPrimaryColor").opacity(0.15))
                                .foregroundColor(Color("MyPrimaryColor"))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Active timer display — tapping dismisses back to mini state
            if !isBlurred, let timer {
                CookTimerView(timer: timer, onDismiss: onTimerDismiss)
                    .padding(.top, 2)
            }
        }
    }
}

// MARK: - CookTimerView

private struct CookTimerView: View {
    @Bindable var timer: CookTimer
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(Color("NeutralColor").opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: timer.progress)
                    .stroke(
                        timer.isComplete ? Color.green : Color("MyPrimaryColor"),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timer.progress)

                if timer.isComplete {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text(timer.timeString)
                        .font(.system(size: 9, design: .monospaced))
                }
            }

            // Step label + time display
            VStack(alignment: .leading, spacing: 2) {
                Text(timer.stepLabel)
                    .font(.caption)
                    .foregroundColor(Color("NeutralColor"))
                Text(timer.timeString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(timer.isComplete ? .green : Color("TextColor"))
            }

            if timer.isComplete {
                Text("Done!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .bold()
            }

            Spacer()

            // Controls
            if !timer.isComplete {
                Button {
                    if timer.isRunning {
                        timer.pause()
                    } else {
                        timer.start()
                    }
                } label: {
                    Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(Color("MyPrimaryColor"))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(Color("NeutralColor"))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color("Base200Color").opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - NoteEditState

private struct NoteEditState: Identifiable {
    let id = UUID()
    let index: Int? // nil = new note
    var text: String
}

// MARK: - CookNotesSection

private struct CookNotesSection: View {
    @Binding var recipe: Recipe
    let network: Network
    @State private var editingNote: NoteEditState?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Notes")
                    .font(.headline)
                Spacer()
                Button("Add Note") {
                    editingNote = NoteEditState(index: nil, text: "")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("MyPrimaryColor"))
                .foregroundColor(.black)
            }

            if !recipe.notes.isEmpty {
                List {
                    ForEach(Array(recipe.notes.enumerated()), id: \.element.id) { index, note in
                        Text(note.content)
                            .padding(.vertical, 2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                let noteId = recipe.notes[index].id
                                recipe.notes.remove(at: index)
                                network.delete_note(id: noteId) { _ in }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                editingNote = NoteEditState(index: index, text: note.content)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Color("MyPrimaryColor"))
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(minHeight: CGFloat(recipe.notes.count * 44))
            }
        }
        .padding(.bottom, 20)
        .sheet(item: $editingNote) { state in
            EditSheet(
                title: state.index == nil ? "Add Note" : "Edit Note",
                fields: [
                    EditSheetField(label: "Note", placeholder: "Write a note...", value: state.text, isMultiline: true)
                ],
                onSave: { values in
                    let text = values[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    if let index = state.index {
                        // Edit existing note
                        let noteId = recipe.notes[index].id
                        recipe.notes[index].content = text
                        network.update_note(id: noteId, content: text) { _ in }
                    } else {
                        // New note
                        network.create_note(content: text, recipeId: recipe.id) { noteId in
                            if let noteId {
                                recipe.notes.append(RecipeNote(id: noteId, content: text))
                            }
                        }
                    }
                }
            )
        }
    }
}

// MARK: - Preview

#Preview {
    CookView(recipe: Recipe.sampleData[0])
        .environmentObject(Network())
}
