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
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var network: Network
    @State private var selectedTab: AppTab = .recipes
    @State private var recipesPath = NavigationPath()
    @State private var todayPath = NavigationPath()
    private var recipes: [Recipe] = []

    private func badge(for tab: AppTab) -> Int {
        network.activeSessions.filter { $0.sourceTab == tab }.count
    }

    private func navigate(to session: ActiveCookingSession) {
        let recipe = session.recipe
        selectedTab = session.sourceTab
        if session.sourceTab == .recipes {
            recipesPath = NavigationPath([recipe])
        } else if session.sourceTab == .today {
            todayPath = NavigationPath([recipe])
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ProfileView()
                    .environmentObject(network)
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(AppTab.profile)

            NavigationStack(path: $recipesPath) {
                RecipesView()
                    .environmentObject(network)
                    .navigationDestination(for: Recipe.self) { recipe in
                        CookView(recipe: recipe, sourceTab: .recipes)
                            .environmentObject(network)
                    }
            }
            .tabItem { Label("Recipes", systemImage: "globe.americas") }
            .tag(AppTab.recipes)
            .badge(badge(for: .recipes))

            NavigationStack(path: $todayPath) {
                TodayView()
                    .environmentObject(network)
                    .navigationDestination(for: Recipe.self) { recipe in
                        CookView(recipe: recipe, menuMade: network.today?.made[recipe.id] ?? false, menuServings: network.today?.servings[recipe.id] ?? recipe.servings, sourceTab: .today)
                            .environmentObject(network)
                    }
            }
            .tabItem {
                Label("Today", systemImage: "house.fill")
                    .font(.title2)
            }
            .tag(AppTab.today)
            .badge(badge(for: .today))

            NavigationStack {
                CreateMenuView(selectedTab: $selectedTab)
                    .environmentObject(network)
            }
            .tabItem { Label("Create", systemImage: "flame") }
            .tag(AppTab.create)

            NavigationStack {
                AddRecipeView()
                    .environmentObject(network)
            }
            .tabItem { Label("Add", systemImage: "plus.circle") }
            .tag(AppTab.add)
        }
        .accentColor(Color("MyPrimaryColor"))
        .background(Color("BaseColor"))
        .onChange(of: network.user != nil, initial: true) { _, isLoggedIn in
            selectedTab = isLoggedIn ? .today : .recipes
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active, let session = network.activeSessions.first {
                navigate(to: session)
            }
        }
        .onOpenURL { url in
            guard url.scheme == "chefbook",
                  url.host == "cook",
                  let recipeId = url.pathComponents.dropFirst().first,
                  let session = network.activeSessions.first(where: { $0.id == recipeId }) else { return }
            navigate(to: session)
        }
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
        .environmentObject(Network())
}
