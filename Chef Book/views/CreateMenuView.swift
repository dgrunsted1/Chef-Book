//
//  CreateMenuView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI

struct CreateMenuView: View {
    @EnvironmentObject var network: Network
    @Binding var selectedTab: AppTab
    @State private var search_val: String = ""
    @State private var sort_val: String = "Most Recent"
    @State private var selectedCats: [String] = []
    @State private var selectedCuisines: [String] = []
    @State private var selectedCountries: [String] = []
    @State private var selectedAuthors: [String] = []
    @State private var expandedFilter: String? = nil
    @State private var selectedRecipeIds: Set<String> = []
    @State private var activeMenuId: String? = nil
    @State private var showMenuPanel = false
    @State private var isAddingToMenu = false
    @State private var menuTitle: String = ""
    @State private var menuServings: [String: String] = [:]
    @State private var isSavingMenu = false
    #if os(iOS)
    @State private var menuPanelExpanded = false
    @State private var createMenuTab = 0
    @State private var menuAlertMessage = ""
    @State private var showMenuAlert = false
    #endif
    #if os(macOS)
    @State private var macosMenuTab = 0
    @State private var macosMenuAlert = ""
    @State private var showMacosMenuAlert = false
    #endif
    @State private var filterMade: Bool = false
    @State private var filterFavorite: Bool = false
    @State private var recipeToPreview: Recipe? = nil
    @State private var recipeToDelete: Recipe? = nil
    @FocusState private var search_field_is_focused: Bool
    private let sort_options: [String] = ["Least Ingredients", "Most Ingredients", "Least Servings", "Most Servings", "Least Time", "Most Time", "Least Recent", "Most Recent"]

    private func fetchRecipes() {
        network.getRecipes(categories: selectedCats, cuisines: selectedCuisines, countries: selectedCountries, authors: selectedAuthors, sort: sort_val, search: search_val, userId: network.user?.record.id ?? "")
    }

    private func loadMore() {
        network.loadMoreRecipes(categories: selectedCats, cuisines: selectedCuisines, countries: selectedCountries, authors: selectedAuthors, sort: sort_val, search: search_val, userId: network.user?.record.id ?? "")
    }

    private func toggle(_ value: String, in array: inout [String]) {
        if let idx = array.firstIndex(of: value) {
            array.remove(at: idx)
        } else {
            array.append(value)
        }
    }

    var userRecipes: [Recipe] {
        let userId = network.user?.record.id ?? ""
        return network.recipes.filter { recipe in
            guard recipe.user == userId else { return false }
            if filterMade && !recipe.made { return false }
            if filterFavorite && !recipe.favorite { return false }
            return true
        }
    }

    var selectedRecipes: [Recipe] {
        network.recipes.filter { selectedRecipeIds.contains($0.id) }
    }

    var body: some View {
        if network.user != nil {
            #if os(macOS)
            macOSLayout
            #else
            iOSLayout
            #endif
        } else {
            LoginView()
                .environmentObject(network)
        }
    }

    // MARK: - macOS Layout

    #if os(macOS)
    private var macOSLayout: some View {
        HStack(spacing: 0) {
            macosMenuPanel
                .frame(minWidth: 300, idealWidth: 350)

            Divider()

            recipeListContent
        }
        .onAppear {
            fetchRecipes()
        }
        .onChange(of: selectedCats) { fetchRecipes() }
        .onChange(of: selectedCuisines) { fetchRecipes() }
        .onChange(of: selectedCountries) { fetchRecipes() }
        .onChange(of: selectedAuthors) { fetchRecipes() }
        .onChange(of: network.menus.map(\.id)) {
            if let id = activeMenuId, !network.menus.contains(where: { $0.id == id }) {
                activeMenuId = nil
            }
        }
        .onChange(of: selectedRecipeIds) {
            if !selectedRecipeIds.isEmpty && activeMenuId == nil {
                network.loadRecipeDetailsIfNeeded(for: Array(selectedRecipeIds))
            }
        }
        .alert(macosMenuAlert, isPresented: $showMacosMenuAlert) {
            Button("OK") {}
        }
    }

    private var macosMenuPanel: some View {
        Group {
            if let menuId = activeMenuId {
                MenuDetailPanel(menuId: menuId, onDismiss: {
                    activeMenuId = nil
                })
                .environmentObject(network)
            } else {
                macosCreateMenuPanel
            }
        }
    }

    private var macosCreateMenuPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("New Menu")
                    .font(.headline)
                    .bold()
                Spacer()
            }
            .padding()

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
                    Text(macosTotalTime > 0 ? Network.formatTime(macosTotalTime) : "—")
                        .font(.headline)
                    Text("Time")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                VStack(spacing: 2) {
                    Text("\(macosTotalServings)")
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

                if isSavingMenu {
                    ProgressView()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                } else {
                    Button(action: { macosSaveMenu(today: false) }) {
                        Text("Save").bold().foregroundColor(.black)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(macosSaveDisabled ? Color.gray.opacity(0.3) : Color("MyPrimaryColor"))
                    .cornerRadius(8)
                    .disabled(macosSaveDisabled)
                    Button(action: { macosSaveMenu(today: true) }) {
                        Text("+ Today").bold().foregroundColor(.black)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(macosSaveDisabled ? Color.gray.opacity(0.3) : Color("MyPrimaryColor").opacity(0.7))
                    .cornerRadius(8)
                    .disabled(macosSaveDisabled)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Segmented picker
            Picker("", selection: $macosMenuTab) {
                Text("Recipes").tag(0)
                Text("Grocery List").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Tab content
            if macosMenuTab == 0 {
                macosRecipesTab
            } else {
                macosGroceryTab
            }
        }
    }

    private var macosSaveDisabled: Bool {
        menuTitle.isEmpty || selectedRecipes.isEmpty
    }

    private var macosTotalServings: Int {
        selectedRecipes.reduce(0) { sum, recipe in
            let srv = menuServings[recipe.id] ?? recipe.servings
            return sum + (Int(srv) ?? 0)
        }
    }

    private var macosTotalTime: Int {
        selectedRecipes.reduce(0) { $0 + $1.time_in_seconds }
    }

    private var macosGroceryPreview: [GroceryListGenerator.GroceryItem] {
        var effectiveServings = menuServings
        for recipe in selectedRecipes {
            if effectiveServings[recipe.id] == nil {
                effectiveServings[recipe.id] = recipe.servings
            }
        }
        return GroceryListGenerator.generate(recipes: selectedRecipes, servings: effectiveServings)
    }

    private var macosRecipesTab: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if selectedRecipes.isEmpty {
                    Text("Select recipes to add to your menu")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity)
                } else {
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
                                    get: { menuServings[recipe.id] ?? recipe.servings },
                                    set: { menuServings[recipe.id] = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 50)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private var macosGroceryTab: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                if macosGroceryPreview.isEmpty {
                    Text("No ingredients")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(macosGroceryPreview) { item in
                        HStack(spacing: 4) {
                            if item.qty > 0 {
                                Text(macosFormatQuantity(item.qty))
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

    private func macosFormatQuantity(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%g", value)
    }

    private func macosSaveMenu(today: Bool) {
        guard !menuTitle.isEmpty else { return }
        isSavingMenu = true

        for recipe in selectedRecipes {
            if menuServings[recipe.id] == nil {
                menuServings[recipe.id] = recipe.servings
            }
        }

        let recipeIds = selectedRecipes.map { $0.id }
        network.create_menu(title: menuTitle, recipeIds: recipeIds, servings: menuServings, today: today) { menuId in
            isSavingMenu = false
            if menuId != nil {
                selectedRecipeIds.removeAll()
                menuTitle = ""
                menuServings = [:]
                macosMenuTab = 0
                activeMenuId = nil
                if today {
                    selectedTab = .today
                }
            } else {
                macosMenuAlert = "Failed to save menu"
                showMacosMenuAlert = true
            }
        }
    }
    #endif

    // MARK: - iOS Layout

    #if os(iOS)
    private var showCreatePanel: Bool {
        !selectedRecipeIds.isEmpty && activeMenuId == nil
    }

    private var totalServings: Int {
        selectedRecipes.reduce(0) { sum, recipe in
            let srv = menuServings[recipe.id] ?? recipe.servings
            return sum + (Int(srv) ?? 0)
        }
    }

    private var totalTimeSeconds: Int {
        selectedRecipes.reduce(0) { $0 + $1.time_in_seconds }
    }

    private var groceryPreview: [GroceryListGenerator.GroceryItem] {
        var effectiveServings = menuServings
        for recipe in selectedRecipes {
            if effectiveServings[recipe.id] == nil {
                effectiveServings[recipe.id] = recipe.servings
            }
        }
        return GroceryListGenerator.generate(recipes: selectedRecipes, servings: effectiveServings)
    }

    private var iOSLayout: some View {
        VStack(spacing: 0) {
            // Top pull-down panel
            if showCreatePanel {
                topMenuPanel
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            recipeListContent
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showCreatePanel)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: menuPanelExpanded)
        .onAppear {
            fetchRecipes()
        }
        .onChange(of: selectedCats) { fetchRecipes() }
        .onChange(of: selectedCuisines) { fetchRecipes() }
        .onChange(of: selectedCountries) { fetchRecipes() }
        .onChange(of: selectedAuthors) { fetchRecipes() }
        .onChange(of: network.menus.map(\.id)) {
            if let id = activeMenuId, !network.menus.contains(where: { $0.id == id }) {
                activeMenuId = nil
                showMenuPanel = false
            }
        }
        .onChange(of: selectedRecipeIds) {
            if !selectedRecipeIds.isEmpty && activeMenuId == nil {
                network.loadRecipeDetailsIfNeeded(for: Array(selectedRecipeIds))
            }
        }
        .alert(menuAlertMessage, isPresented: $showMenuAlert) {
            Button("OK") {}
        }
        .sheet(isPresented: $showMenuPanel) {
            MenuDetailPanel(menuId: activeMenuId ?? "", onDismiss: {
                showMenuPanel = false
                activeMenuId = nil
            })
            .environmentObject(network)
            .presentationDetents([.fraction(0.3), .medium, .large])
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .interactiveDismissDisabled()
        }
    }

    private var topMenuPanel: some View {
        VStack(spacing: 0) {
            // Summary stats bar (always visible) — tap to toggle
            Button(action: {
                withAnimation {
                    menuPanelExpanded.toggle()
                }
            }) {
                VStack(spacing: 4) {
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
                    .padding(.top, 8)

                    Image(systemName: menuPanelExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expanded content
            if menuPanelExpanded {
                Divider()

                // Title field + Save button
                HStack {
                    TextField("Menu Title", text: $menuTitle)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)

                    if isSavingMenu {
                        ProgressView()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    } else {
                        Menu {
                            Button("Save") { saveNewMenu(today: false) }
                            Button("Save as Today") { saveNewMenu(today: true) }
                        } label: {
                            Text("Save")
                                .bold()
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(menuTitle.isEmpty ? Color.gray.opacity(0.3) : Color("MyPrimaryColor"))
                                .cornerRadius(8)
                        }
                        .disabled(menuTitle.isEmpty)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Segmented picker
                Picker("", selection: $createMenuTab) {
                    Text("Recipes").tag(0)
                    Text("Grocery List").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Tab content
                if createMenuTab == 0 {
                    createRecipesTab
                } else {
                    createGroceryTab
                }
            }

            Divider()
        }
        .background(Color(UIColor.systemBackground))
    }

    private var createRecipesTab: some View {
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
                                get: { menuServings[recipe.id] ?? recipe.servings },
                                set: { menuServings[recipe.id] = $0 }
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
        .frame(maxHeight: 250)
    }

    private var createGroceryTab: some View {
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
        .frame(maxHeight: 250)
    }

    private func formatQuantity(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%g", value)
    }

    private func saveNewMenu(today: Bool) {
        guard !menuTitle.isEmpty else { return }
        isSavingMenu = true

        for recipe in selectedRecipes {
            if menuServings[recipe.id] == nil {
                menuServings[recipe.id] = recipe.servings
            }
        }

        let recipeIds = selectedRecipes.map { $0.id }
        network.create_menu(title: menuTitle, recipeIds: recipeIds, servings: menuServings, today: today) { menuId in
            isSavingMenu = false
            if menuId != nil {
                selectedRecipeIds.removeAll()
                menuTitle = ""
                menuServings = [:]
                menuPanelExpanded = false
                createMenuTab = 0
                activeMenuId = nil
                showMenuPanel = false
                if today {
                    selectedTab = .today
                }
            } else {
                menuAlertMessage = "Failed to save menu"
                showMenuAlert = true
            }
        }
    }
    #endif

    // MARK: - Shared Recipe List

    private var recipeListContent: some View {
        VStack(spacing: 0) {
            if userRecipes.isEmpty && !network.isLoading {
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
                    LazyVStack {
                        if network.isLoading {
                            ProgressView()
                                .padding()
                        }
                        ForEach(userRecipes) { recipe in
                            recipeCard(recipe)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                                .onAppear {
                                    if recipe.id == network.recipes.last?.id {
                                        loadMore()
                                    }
                                }
                        }
                        if network.isLoadingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                }
                .refreshable {
                    fetchRecipes()
                }
                .sheet(item: $recipeToPreview) { recipe in
                    recipePreviewSheet(recipe)
                        #if os(macOS)
                        .frame(minWidth: 500, minHeight: 600)
                        #endif
                }
                .alert("Delete Recipe", isPresented: Binding(
                    get: { recipeToDelete != nil },
                    set: { if !$0 { recipeToDelete = nil } }
                )) {
                    Button("Cancel", role: .cancel) { recipeToDelete = nil }
                    Button("Delete", role: .destructive) {
                        if let recipe = recipeToDelete {
                            network.delete_recipe(id: recipe.id) { _ in }
                            recipeToDelete = nil
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete \"\(recipeToDelete?.title ?? "")\"? This cannot be undone.")
                }
            }

            // Bottom bar — "Add to Menu" (when editing an active menu)
            if !selectedRecipeIds.isEmpty && activeMenuId != nil {
                HStack {
                    Text("\(selectedRecipeIds.count) recipes selected")
                        .bold()
                    Spacer()
                    Button(action: addSelectedRecipesToMenu) {
                        if isAddingToMenu {
                            ProgressView()
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        } else {
                            Text("Add to Menu")
                                .bold()
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color("MyPrimaryColor"))
                                .cornerRadius(10)
                        }
                    }
                    .disabled(isAddingToMenu)
                }
                .padding()
                .background(Color("Base200Color"))
            }


            filterBar
        }
    }

    // MARK: - Recipe Card

    private func recipeCard(_ recipe: Recipe) -> some View {
        HStack(spacing: 0) {
            // Card body
            HStack {
                if recipe.image != "" {
                    AsyncImage(url: URL(string: recipe.image)) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 75, height: 80)
                            .clipped()
                    } placeholder: {
                        ProgressView()
                            .frame(width: 75, height: 80)
                    }
                }

                VStack(alignment: .leading) {
                    Text(recipe.title)
                        .font(.headline)
                        .foregroundColor(Color("TextColor"))
                        .lineLimit(2)
                    Spacer()
                    HStack {
                        Text("\(recipe.ingredientCount) ingredients")
                        Spacer()
                        Text("\(recipe.servings) servings")
                        Spacer()
                        Text(recipe.time_display.isEmpty ? "\(recipe.time_in_seconds/60)m" : recipe.time_display)
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                }
                .frame(height: 70)
                .padding(.vertical, 5)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                recipeToPreview = recipe
                network.loadRecipeDetailsIfNeeded(for: [recipe.id])
            }

            // Action buttons 2x2 grid
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Button(action: {
                        let newVal = !recipe.made
                        if let idx = network.recipes.firstIndex(where: { $0.id == recipe.id }) {
                            network.recipes[idx].made = newVal
                        }
                        network.toggle_made(recipeId: recipe.id, value: newVal) { _ in }
                    }) {
                        Image(systemName: recipe.made ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .foregroundColor(recipe.made ? Color("MyPrimaryColor") : Color("NeutralColor"))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 35, height: 35)

                    Button(action: {
                        let newVal = !recipe.favorite
                        if let idx = network.recipes.firstIndex(where: { $0.id == recipe.id }) {
                            network.recipes[idx].favorite = newVal
                        }
                        network.toggle_favorite(recipeId: recipe.id, value: newVal) { _ in }
                    }) {
                        Image(systemName: recipe.favorite ? "heart.fill" : "heart")
                            .foregroundColor(recipe.favorite ? Color("MyPrimaryColor") : Color("NeutralColor"))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 35, height: 35)
                }
                HStack(spacing: 4) {
                    Button(action: {
                        if selectedRecipeIds.contains(recipe.id) {
                            selectedRecipeIds.remove(recipe.id)
                        } else {
                            selectedRecipeIds.insert(recipe.id)
                        }
                    }) {
                        Image(systemName: selectedRecipeIds.contains(recipe.id) ? "checkmark.square.fill" : "square")
                            .foregroundColor(selectedRecipeIds.contains(recipe.id) ? Color("MyPrimaryColor") : Color("NeutralColor"))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 35, height: 35)

                    Button(action: {
                        recipeToDelete = recipe
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(Color("NeutralColor"))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 35, height: 35)
                }
            }
            #if os(macOS)
            .font(.title)
            .frame(width: 90, height: 76)
            .padding(.trailing, 0)
            #else
            .font(.title)
            .frame(width: 90, height: 76)
            .padding(.trailing, 0)
            #endif
        }
        .background(Color("Base200Color"))
        .cornerRadius(10)
        .frame(height: 80)
    }

    // MARK: - Recipe Preview Sheet

    private func recipePreviewSheet(_ recipe: Recipe) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if recipe.image != "" {
                        AsyncImage(url: URL(string: recipe.image)) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipped()
                        } placeholder: {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        let detail = network.recipes.first(where: { $0.id == recipe.id }) ?? recipe

                        Text(detail.title)
                            .font(.title2)
                            .bold()

                        if !detail.desc.isEmpty {
                            Text(detail.desc)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        // Metadata row
                        HStack(spacing: 16) {
                            if !detail.category.isEmpty {
                                Label(detail.category, systemImage: "square.grid.2x2")
                            }
                            if !detail.servings.isEmpty {
                                Label(detail.servings + " servings", systemImage: "person.2")
                            }
                            if !detail.country.isEmpty {
                                Label(detail.country, systemImage: "flag")
                            }
                            if !detail.cuisine.isEmpty {
                                Label(detail.cuisine, systemImage: "globe")
                            }
                            if detail.time_in_seconds > 0 {
                                Label(detail.time_display.isEmpty ? "\(detail.time_in_seconds/60)m" : detail.time_display, systemImage: "clock")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        // Ingredients
                        if let loadedRecipe = network.recipes.first(where: { $0.id == recipe.id }),
                           !loadedRecipe.ingredients.isEmpty {
                            Divider()
                            Text("Ingredients")
                                .font(.headline)
                            ForEach(loadedRecipe.ingredients) { ingredient in
                                Text(ingredient.toString())
                                    .font(.body)
                            }
                        }

                        // Directions
                        if let loadedRecipe = network.recipes.first(where: { $0.id == recipe.id }),
                           !loadedRecipe.directions.isEmpty {
                            Divider()
                            Text("Directions")
                                .font(.headline)
                            ForEach(Array(loadedRecipe.directions.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .bold()
                                        .foregroundColor(Color("MyPrimaryColor"))
                                    Text(step)
                                }
                                .font(.body)
                            }
                        }

                        // Notes
                        if let loadedRecipe = network.recipes.first(where: { $0.id == recipe.id }),
                           !loadedRecipe.notes.isEmpty {
                            Divider()
                            Text("Notes")
                                .font(.headline)
                            ForEach(loadedRecipe.notes) { note in
                                Text(note.content)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Recipe Preview")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        recipeToPreview = nil
                    }
                }
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 6) {
            Spacer().frame(height: 4)
            HStack(spacing: 6) {
                FilterHeaderButton(title: "Category", icon: "square.grid.2x2", count: selectedCats.count, isExpanded: expandedFilter == "Category") {
                    expandedFilter = expandedFilter == "Category" ? nil : "Category"
                }
                FilterHeaderButton(title: "Cuisine", icon: "globe", count: selectedCuisines.count, isExpanded: expandedFilter == "Cuisine") {
                    expandedFilter = expandedFilter == "Cuisine" ? nil : "Cuisine"
                }
                FilterHeaderButton(title: "Author", icon: "person", count: selectedAuthors.count, isExpanded: expandedFilter == "Author") {
                    expandedFilter = expandedFilter == "Author" ? nil : "Author"
                }
                FilterHeaderButton(title: "Country", icon: "flag", count: selectedCountries.count, isExpanded: expandedFilter == "Country") {
                    expandedFilter = expandedFilter == "Country" ? nil : "Country"
                }

                Button(action: {
                    filterMade.toggle()
                }) {
                    Image(systemName: filterMade ? "hand.thumbsup.fill" : "hand.thumbsup")
                        .font(.caption)
                        .foregroundColor(filterMade ? .black : Color("TextColor"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(filterMade ? Color("MyPrimaryColor") : Color("Base200Color"))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: {
                    filterFavorite.toggle()
                }) {
                    Image(systemName: filterFavorite ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundColor(filterFavorite ? .black : Color("TextColor"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(filterFavorite ? Color("MyPrimaryColor") : Color("Base200Color"))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)

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

                Text("\(userRecipes.count)")
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

    // MARK: - Add to Menu

    private func addSelectedRecipesToMenu() {
        guard let menuId = activeMenuId,
              let menu = network.menus.first(where: { $0.id == menuId }) else { return }

        isAddingToMenu = true

        let existingIds = Set(menu.recipes.map(\.id))
        let newIds = selectedRecipeIds.filter { !existingIds.contains($0) }

        guard !newIds.isEmpty else {
            selectedRecipeIds.removeAll()
            isAddingToMenu = false
            return
        }

        let mergedIds = menu.recipes.map(\.id) + Array(newIds)

        var mergedServings = menu.servings
        for id in newIds {
            if mergedServings[id] == nil {
                let recipe = network.recipes.first(where: { $0.id == id })
                mergedServings[id] = recipe?.servings ?? "1"
            }
        }

        let fields: [String: Any] = [
            "recipes": mergedIds,
            "servings": mergedServings
        ]

        network.update_menu(id: menuId, fields: fields) { success in
            isAddingToMenu = false
            if success {
                network.get_menus()
            }
            selectedRecipeIds.removeAll()
        }
    }
}

#Preview {
    CreateMenuView(selectedTab: .constant(.create))
        .environmentObject(Network())
}
