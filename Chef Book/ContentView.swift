//
//  ContentView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case profile, recipes, today, create, add
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var network: Network
    @State private var selectedTab: AppTab = .recipes
    private var recipes: [Recipe] = []

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                    .tag(AppTab.profile)
                    .environmentObject(network)

                RecipesView()
                    .tabItem { Label("Recipes", systemImage: "globe.americas") }
                    .tag(AppTab.recipes)
                    .environmentObject(network)

                TodayView()
                    .tabItem {
                        Label("Today", systemImage: "house.fill")
                            .font(.title2)
                    }
                    .tag(AppTab.today)
                    .environmentObject(network)

                CreateMenuView(selectedTab: $selectedTab)
                    .tabItem { Label("Create", systemImage: "flame") }
                    .tag(AppTab.create)
                    .environmentObject(network)

                AddRecipeView()
                    .tabItem { Label("Add", systemImage: "plus.circle") }
                    .tag(AppTab.add)
                    .environmentObject(network)
            }
            .accentColor(Color("MyPrimaryColor"))
            .background(Color("BaseColor"))
            .onChange(of: network.user != nil, initial: true) { _, isLoggedIn in
                selectedTab = isLoggedIn ? .today : .recipes
            }
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(Network())
}
