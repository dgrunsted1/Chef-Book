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

                    Picker("", selection: $selectedTab) {
                        Text("Recipes").tag(0)
                        Text("Groceries").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if selectedTab == 0 {
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
                    } else {
                        GroceryListView(
                            today: today,
                            showAddItem: $showAddItem,
                            showResetConfirm: $showResetConfirm,
                            showCopyConfirm: $showCopyConfirm
                        )
                        .environmentObject(network)
                    }
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
                let key = ingredient.name.lowercased()
                map[key, default: []].append(recipe.title)
            }
        }
        return map
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
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

            // List
            if today.grocery_list.isEmpty {
                Spacer()
                Text("No grocery items")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                List {
                    ForEach(sortedItems) { item in
                        GroceryItemRow(item: item, groceryListId: today.grocery_list_id, recipeNames: recipeNamesForItem[item.ingredient.name.lowercased()] ?? [])
                            .environmentObject(network)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = sortedItems[index]
                            network.delete_grocery_item(itemId: item.id, groceryListId: today.grocery_list_id) { _ in }
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
    @State private var checked: Bool
    @State private var isEditing = false
    @State private var editQty: String
    @State private var editUnit: String
    @State private var editName: String

    init(item: GroceryItem, groceryListId: String, recipeNames: [String] = []) {
        self.item = item
        self.groceryListId = groceryListId
        self.recipeNames = recipeNames
        _checked = State(initialValue: item.checked)
        _editQty = State(initialValue: item.ingredient.quantity == 0 ? "" : String(format: "%g", item.ingredient.quantity))
        _editUnit = State(initialValue: item.ingredient.unit)
        _editName = State(initialValue: item.ingredient.name)
    }

    var body: some View {
        HStack {
            if isEditing {
                HStack(spacing: 4) {
                    TextField("Qty", text: $editQty)
                        .frame(width: 45)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Unit", text: $editUnit)
                        .frame(width: 55)
                    TextField("Name", text: $editName)
                }
                .textFieldStyle(.roundedBorder)
                .font(.callout)

                Button {
                    let qty = Double(editQty) ?? 0
                    network.edit_grocery_item(itemId: item.id, name: editName, qty: qty, unit: editUnit) { _ in }
                    isEditing = false
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                Button {
                    // Reset fields
                    editQty = item.ingredient.quantity == 0 ? "" : String(format: "%g", item.ingredient.quantity)
                    editUnit = item.ingredient.unit
                    editName = item.ingredient.name
                    isEditing = false
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.ingredient.toString())
                        .strikethrough(checked)
                        .foregroundColor(checked ? .gray : Color("TextColor"))
                    if !recipeNames.isEmpty {
                        Text(recipeNames.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .onTapGesture {
                    isEditing = true
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
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                network.delete_grocery_item(itemId: item.id, groceryListId: groceryListId) { _ in }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onChange(of: item.checked) { _, newValue in
            checked = newValue
        }
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
                TextField("Unit (e.g. cups, lbs)", text: $unit)
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
