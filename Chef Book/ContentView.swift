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
    @Query private var items: [Item]
    @State private var recipes = Recipe.sampleData

    
    var body: some View {
            TabView {
                TodayView()
                    .tabItem { Label("today", systemImage: "house") }
                
                CreateMenuView()
                    .tabItem { Label("Create", systemImage: "flame") }
                
                MyMenusView()
                    .tabItem { Label("My Menus", systemImage: "drop") }
                
                AddRecipeView()
                    .tabItem { Label("Add", systemImage: "plus.circle") }
                
                RecipesView(recipes: $recipes)
                    .tabItem { Label("Recipes", systemImage: "globe.americas") }
            }
            .accentColor(Color("MyPrimaryColor"))
    }
        
        private func addItem() {
            withAnimation {
                let newItem = Item(timestamp: Date())
                modelContext.insert(newItem)
            }
        }
        
        private func deleteItems(offsets: IndexSet) {
            withAnimation {
                for index in offsets {
                    modelContext.delete(items[index])
                }
            }
        }
    }


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
