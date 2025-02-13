//
//  ContentView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var network: Network
    private var recipes: [Recipe] = []

    
    var body: some View {
        NavigationStack {
            TabView {
                RecipesView()
                    .tabItem { Label("Recipes", systemImage: "globe.americas") }
                    .environmentObject(network)
                
                CreateMenuView()
                    .tabItem { Label("Create", systemImage: "flame") }
                    .environmentObject(network)
                
                MyMenusView()
                    .tabItem { Label("My Menus", systemImage: "drop") }
                    .environmentObject(network)
                
                
                AddRecipeView()
                    .tabItem { Label("Add", systemImage: "plus.circle") }
                    .environmentObject(network)
                
                TodayView()
                    .tabItem { Label("today", systemImage: "house") }
                    .environmentObject(network)
            }
            .accentColor(Color("MyPrimaryColor"))
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(Network())
}
