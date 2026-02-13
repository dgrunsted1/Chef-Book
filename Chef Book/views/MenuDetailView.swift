//
//  MenuDetailView.swift
//  Chef Book
//

import SwiftUI

struct MenuDetailView: View {
    @EnvironmentObject var network: Network
    let menu: MyMenu
    @State private var selectedTab = 0
    @State private var isSettingToday = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Menu header
            VStack(spacing: 4) {
                Text(menu.title)
                    .font(.title2)
                    .bold()
                Text(formatDate(menu.created))
                    .font(.caption)
                    .foregroundColor(.gray)
                if menu.today {
                    Text("Today's Menu")
                        .font(.caption)
                        .bold()
                        .foregroundColor(Color("MyPrimaryColor"))
                }
            }
            .padding()

            // Segmented control
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

            Spacer()

            // Set as Today button
            if !menu.today {
                Button(action: setAsToday) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color("MyPrimaryColor"))
                            .frame(height: 50)
                        if isSettingToday {
                            ProgressView()
                        } else {
                            Text("Set as Today's Menu")
                                .foregroundColor(.black)
                                .bold()
                        }
                    }
                }
                .disabled(isSettingToday)
                .padding()
            }
        }
    }

    private var recipesTab: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(menu.recipes) { recipe in
                    NavigationLink(destination: CookView(recipe: recipe)) {
                        HStack {
                            if recipe.image != "" {
                                AsyncImage(url: URL(string: recipe.image)) { image in
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipped()
                                        .cornerRadius(8)
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 60, height: 60)
                                }
                            }
                            VStack(alignment: .leading) {
                                Text(recipe.title)
                                    .font(.subheadline)
                                    .bold()
                                HStack {
                                    Text("\(recipe.ingredients.count) ingredients")
                                    Text(Network.formatTime(recipe.time_in_seconds))
                                }
                                .font(.caption)
                                .foregroundColor(.gray)
                            }
                            Spacer()
                            if let servingCount = menu.servings[recipe.id] {
                                Text("\(servingCount) srv")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
        }
    }

    private var groceryTab: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                if menu.grocery_list.isEmpty {
                    Text("No grocery list generated yet")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                } else {
                    ForEach(menu.grocery_list) { item in
                        GroceryItemRow(item: item)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private func setAsToday() {
        isSettingToday = true
        network.set_today_menu(menuId: menu.id) { success in
            isSettingToday = false
            if success {
                dismiss()
            }
        }
    }

    private func formatDate(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: " ")
        return parts.first.map(String.init) ?? dateStr
    }
}
