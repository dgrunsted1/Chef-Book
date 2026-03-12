//
//  TodayView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var network: Network
    @State private var selectedTab: Int = 0
    @State private var showAddItem = false
    @State private var showResetConfirm = false
    @State private var showCopyConfirm = false

    var body: some View {
        if network.user != nil {
            VStack {
                if let today = network.today {
                    Text(today.title)
                        .font(.title2)
                        .bold()
                    Text(formatDate(today.created))
                        .font(.caption)
                        .foregroundColor(.gray)

                    #if os(iOS)
                    // Content fills available space
                    if selectedTab == 0 {
                        recipeList(today: today)
                    } else {
                        GroceryListView(
                            today: today,
                            showAddItem: $showAddItem,
                            showResetConfirm: $showResetConfirm,
                            showCopyConfirm: $showCopyConfirm,
                            showToolbar: false
                        )
                        .environmentObject(network)
                    }

                    // Grocery toolbar above picker (iOS only)
                    if selectedTab == 1 {
                        HStack(spacing: 16) {
                            Button { showAddItem = true } label: {
                                Label("Add", systemImage: "plus").font(.caption)
                            }
                            Button { showResetConfirm = true } label: {
                                Label("Reset", systemImage: "arrow.counterclockwise").font(.caption)
                            }
                            Button {
                                copyGroceryList(today: today)
                                showCopyConfirm = true
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc").font(.caption)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    Picker("", selection: $selectedTab) {
                        Text("Recipes").tag(0)
                        Text("Groceries").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    #else
                    Picker("", selection: $selectedTab) {
                        Text("Recipes").tag(0)
                        Text("Groceries").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedTab == 0 {
                        recipeList(today: today)
                    } else {
                        GroceryListView(
                            today: today,
                            showAddItem: $showAddItem,
                            showResetConfirm: $showResetConfirm,
                            showCopyConfirm: $showCopyConfirm
                        )
                        .environmentObject(network)
                    }
                    #endif
                } else if network.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "house")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No menu set for today")
                            .foregroundColor(.gray)
                        Text("Set one from My Menus")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
            .background(Color("BaseColor"))
            .onAppear {
                network.get_todays_menu()
            }
        } else {
            LoginView()
                .environmentObject(network)
        }
    }

    @ViewBuilder
    private func recipeList(today: MyMenu) -> some View {
        List {
            ForEach(today.recipes) { recipe in
                ZStack(alignment: .leading) {
                    NavigationLink(destination: CookView(recipe: recipe, menuMade: today.made[recipe.id] ?? false, menuServings: today.servings[recipe.id] ?? recipe.servings).environmentObject(network)) {
                        EmptyView()
                    }
                    .opacity(0)

                    TodayCardView(recipe: recipe)
                        .environmentObject(network)
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 5, bottom: 4, trailing: 5))
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            network.get_todays_menu()
        }
    }

    #if os(iOS)
    private func copyGroceryList(today: MyMenu) {
        let uncheckedItems = today.grocery_list.filter { !$0.checked }
        let text = uncheckedItems.map { $0.ingredient.toString() }.joined(separator: "\n")
        UIPasteboard.general.string = text
    }
    #endif

    private func formatDate(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: " ")
        return parts.first.map(String.init) ?? dateStr
    }
}

// MARK: - Grocery List View

struct GroceryListView: View {
    @EnvironmentObject var network: Network
    let today: MyMenu
    @Binding var showAddItem: Bool
    @Binding var showResetConfirm: Bool
    @Binding var showCopyConfirm: Bool
    var showToolbar: Bool = true
    @State private var editingItem: GroceryItem? = nil
    @State private var mergeTarget: (GroceryItem, GroceryItem)? = nil
    @State private var draggingItem: GroceryItem? = nil
    @State private var dropTargetId: String? = nil
    @State private var showMergeSheet = false

    private var sortedItems: [GroceryItem] {
        today.grocery_list.sorted { a, b in
            if a.checked == b.checked { return false }
            return !a.checked
        }
    }

    private var recipeNamesForItem: [String: [String]] {
        var map: [String: [String]] = [:]
        for recipe in today.recipes {
            for ingredient in recipe.ingredients {
                let key = GroceryListGenerator.normalizeItemName(ingredient.name)
                map[key, default: []].append(recipe.title)
            }
        }
        return map
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            if showToolbar {
                HStack(spacing: 16) {
                    Button {
                        showAddItem = true
                    } label: {
                        Label("Add", systemImage: "plus")
                            .font(.caption)
                    }

                    Button {
                        showResetConfirm = true
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.caption)
                    }

                    Button {
                        copyGroceryList()
                        showCopyConfirm = true
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            // List
            if today.grocery_list.isEmpty {
                Spacer()
                Text("No grocery items")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                List {
                    ForEach(sortedItems) { item in
                        let isDragSource = draggingItem?.id == item.id
                        let isDropTarget = dropTargetId == item.id
                        GroceryItemRow(item: item, groceryListId: today.grocery_list_id, recipeNames: recipeNamesForItem[item.ingredient.name.lowercased()] ?? [], editingItem: $editingItem, isDragging: isDragSource)
                            .environmentObject(network)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .font(.body)
                            .opacity(isDragSource ? 0.5 : 1.0)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isDropTarget ? Color("MyPrimaryColor").opacity(0.08) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isDragSource || isDropTarget ? Color("MyPrimaryColor") : Color.clear, lineWidth: 2.5)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isDragSource)
                            .animation(.easeInOut(duration: 0.2), value: isDropTarget)
                            .onDrag {
                                draggingItem = item
                                return NSItemProvider(object: item.id as NSString)
                            }
                            .dropDestination(for: String.self) { droppedIds, _ in
                                guard let source = draggingItem, source.id != item.id else {
                                    draggingItem = nil
                                    return false
                                }
                                mergeTarget = (source, item)
                                showMergeSheet = true
                                draggingItem = nil
                                dropTargetId = nil
                                return true
                            } isTargeted: { targeted in
                                if targeted {
                                    dropTargetId = item.id
                                } else if dropTargetId == item.id {
                                    dropTargetId = nil
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .refreshable {
                    network.get_todays_menu()
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddGroceryItemSheet(groceryListId: today.grocery_list_id)
                .environmentObject(network)
        }
        .sheet(item: $editingItem) { item in
            EditGroceryItemSheet(mode: .edit(item), groceryListId: today.grocery_list_id, originalIngredients: originalIngredients(for: item.ingredient.name))
                .environmentObject(network)
        }
        .sheet(isPresented: $showMergeSheet) {
            if let (first, second) = mergeTarget {
                EditGroceryItemSheet(mode: .merge(first, second), groceryListId: today.grocery_list_id, originalIngredients: originalIngredients(for: first.ingredient.name) + originalIngredients(for: second.ingredient.name))
                    .environmentObject(network)
            }
        }
        .alert("Reset Grocery List?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                network.reset_grocery_list(menuId: today.id) { _ in }
            }
        } message: {
            Text("This will delete all current items and regenerate the list from recipes.")
        }
        .alert("Copied!", isPresented: $showCopyConfirm) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Unchecked grocery items copied to clipboard.")
        }
    }

    private func originalIngredients(for itemName: String) -> [(recipeName: String, ingredient: Ingredient)] {
        let normalized = GroceryListGenerator.normalizeItemName(itemName)
        var results: [(recipeName: String, ingredient: Ingredient)] = []
        for recipe in today.recipes {
            for ingredient in recipe.ingredients {
                if GroceryListGenerator.normalizeItemName(ingredient.name) == normalized {
                    results.append((recipeName: recipe.title, ingredient: ingredient))
                }
            }
        }
        return results
    }

    private func copyGroceryList() {
        let uncheckedItems = today.grocery_list.filter { !$0.checked }
        let text = uncheckedItems.map { $0.ingredient.toString() }.joined(separator: "\n")
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

// MARK: - Grocery Item Row

struct GroceryItemRow: View {
    @EnvironmentObject var network: Network
    let item: GroceryItem
    let groceryListId: String
    let recipeNames: [String]
    @Binding var editingItem: GroceryItem?
    @State private var checked: Bool
    var isDragging: Bool = false
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 17

    init(item: GroceryItem, groceryListId: String, recipeNames: [String] = [], editingItem: Binding<GroceryItem?> = .constant(nil), isDragging: Bool = false) {
        self.item = item
        self.groceryListId = groceryListId
        self.recipeNames = recipeNames
        _editingItem = editingItem
        _checked = State(initialValue: item.checked)
        self.isDragging = isDragging
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.ingredient.toString())
                    .strikethrough(checked)
                    .foregroundColor(checked ? .gray : Color("TextColor"))
                    .font(.system(size: isDragging ? bodySize * 1.5 : bodySize))
                if !recipeNames.isEmpty {
                    Text(recipeNames.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button {
                checked.toggle()
                network.toggle_grocery_item(itemId: item.id, checked: checked) { success in
                    if !success { checked.toggle() }
                }
            } label: {
                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(checked ? .green : .gray)
                    .font(.system(size: 28))
            }
            .buttonStyle(.plain)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                network.delete_grocery_item(itemId: item.id, groceryListId: groceryListId) { _ in }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                editingItem = item
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .onChange(of: item.checked) { _, newValue in
            checked = newValue
        }
    }
}

// MARK: - Edit Grocery Item Sheet

struct EditGroceryItemSheet: View {
    enum Mode {
        case edit(GroceryItem)
        case merge(GroceryItem, GroceryItem)
    }

    @EnvironmentObject var network: Network
    @Environment(\.dismiss) var dismiss
    let mode: Mode
    let groceryListId: String
    let originalIngredients: [(recipeName: String, ingredient: Ingredient)]
    @State private var name = ""
    @State private var qty = ""
    @State private var unit = ""

    private var title: String {
        switch mode {
        case .edit: return "Edit Item"
        case .merge: return "Merge Items"
        }
    }

    init(mode: Mode, groceryListId: String, originalIngredients: [(recipeName: String, ingredient: Ingredient)] = []) {
        self.mode = mode
        self.groceryListId = groceryListId
        self.originalIngredients = originalIngredients

        switch mode {
        case .edit(let item):
            _name = State(initialValue: item.ingredient.name)
            _qty = State(initialValue: item.ingredient.quantity == 0 ? "" : String(format: "%g", item.ingredient.quantity))
            _unit = State(initialValue: item.ingredient.unit)
        case .merge(let first, let second):
            let mergedName = first.ingredient.name.count >= second.ingredient.name.count ? first.ingredient.name : second.ingredient.name
            let mergedUnit = first.ingredient.unit
            let mergedQty: Double
            if first.ingredient.unit.lowercased() == second.ingredient.unit.lowercased() {
                mergedQty = first.ingredient.quantity + second.ingredient.quantity
            } else {
                mergedQty = first.ingredient.quantity
            }
            _name = State(initialValue: mergedName)
            _qty = State(initialValue: mergedQty == 0 ? "" : String(format: "%g", mergedQty))
            _unit = State(initialValue: mergedUnit)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if case .merge(let first, let second) = mode {
                    Section("Merging") {
                        Text(first.ingredient.toString())
                            .foregroundColor(.secondary)
                        Text(second.ingredient.toString())
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    TextField("Item name", text: $name)
                    TextField("Quantity", text: $qty)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Unit", text: $unit)
                }

                if !originalIngredients.isEmpty {
                    Section("Original Ingredients") {
                        ForEach(Array(originalIngredients.enumerated()), id: \.offset) { _, pair in
                            HStack {
                                Text(pair.ingredient.toString())
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(pair.recipeName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let qtyVal = Double(qty) ?? 0
                        switch mode {
                        case .edit(let item):
                            network.edit_grocery_item(itemId: item.id, name: name, qty: qtyVal, unit: unit) { _ in }
                        case .merge(let keepItem, let deleteItem):
                            network.edit_grocery_item(itemId: keepItem.id, name: name, qty: qtyVal, unit: unit) { _ in
                                network.delete_grocery_item(itemId: deleteItem.id, groceryListId: groceryListId) { _ in }
                            }
                        }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 300)
        .padding(.horizontal)
        #endif
    }
}

// MARK: - Add Grocery Item Sheet

struct AddGroceryItemSheet: View {
    @EnvironmentObject var network: Network
    @Environment(\.dismiss) var dismiss
    let groceryListId: String
    @State private var name = ""
    @State private var qty = ""
    @State private var unit = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Item name", text: $name)
                TextField("Quantity", text: $qty)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                TextField("Unit", text: $unit)
            }
            .navigationTitle("Add Grocery Item")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let qtyVal = Double(qty) ?? 0
                        network.add_grocery_item(groceryListId: groceryListId, name: name, qty: qtyVal, unit: unit) { _ in }
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 250)
        #endif
    }
}

#Preview {
    TodayView()
        .environmentObject(Network())
}
