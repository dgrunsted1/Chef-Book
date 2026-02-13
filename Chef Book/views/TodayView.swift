//
//  TodayView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var network: Network
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
                    TabView {
                        ScrollView {
                            ForEach(today.recipes) { recipe in
                                NavigationLink(destination: CookView(recipe: recipe).environmentObject(network)) {
                                    TodayCardView(recipe: recipe, made: today.made[recipe.id] ?? false)
                                        .environmentObject(network)
                                        .padding(.horizontal, 5)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .refreshable {
                            network.get_todays_menu()
                        }
                        .tabItem { Label("recipes", systemImage: "fork.knife") }
                        VStack {
                            HStack {
                                Text("grocery list")
                                    .font(.headline)
                                Spacer()
                            }
                            ScrollView {
                                if today.grocery_list.isEmpty {
                                    Text("No grocery items")
                                        .foregroundColor(.gray)
                                        .padding(.top, 40)
                                } else {
                                    ForEach(today.grocery_list) { curr in
                                        GroceryItemRow(item: curr)
                                    }
                                }
                            }
                        }
                        .tabItem { Label("groceries", systemImage: "cart") }
                        .padding(.horizontal, 5)
                    }
                    .accentColor(Color("MyPrimaryColor"))
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

struct GroceryItemRow: View {
    let item: GroceryItem
    @State var checked: Bool

    init(item: GroceryItem) {
        self.item = item
        _checked = State(initialValue: item.checked)
    }

    var body: some View {
        HStack {
            Text(item.ingredient.toString())
                .strikethrough(checked)
                .foregroundColor(checked ? .gray : Color("TextColor"))
            Spacer()
            Toggle("", isOn: $checked)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.trailing, 5)
    }
}

#Preview {
    TodayView()
        .environmentObject(Network())
}
