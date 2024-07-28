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
        if (network.user != nil){
            VStack {
                if (network.today != nil) {
                    Text(network.today!.title)
                    Text(network.today!.created)
                    TabView {
                        ScrollView {
                            ForEach(network.today!.recipes) { recipe in
                                @State var made = network.today!.made[recipe.id];
                                NavigationLink(destination: CookView(recipe: recipe)) {
                                    TodayCardView(recipe: recipe, made: Binding(get: { made ?? false }, set: { newValue in made = newValue }))
                                        .padding(.horizontal, 5)
                                }
                                .accentColor(Color("TextColor"))
                            }
                            .listStyle(.inset)
                        }
                        .tabItem { Label("recipes", systemImage: "") }
                        VStack {
                            HStack {
                                Text("grocery list")
                                Spacer()
                            }
                            ScrollView {
                                ForEach(network.today!.grocery_list) { curr in
                                    @State var checked = curr.checked
                                    HStack {
                                        Text(curr.ingredient.toString())
                                        Spacer()
                                        Toggle("", isOn: $checked)
                                            .toggleStyle(.switch)
                                            .labelsHidden()
                                    }
                                    .padding(.trailing, 5)
                                    
                                }
                                .listStyle(.inset)
                            }
                        }
                        .tabItem { Label("groceries", systemImage: "") }
                        .padding(.horizontal, 5)
                    }
                    .accentColor(Color("MyPrimaryColor"))
                }
            }
            .onAppear {
                network.get_todays_menu()
            }
        }else {
            LoginView()
                .environmentObject(network)
        }
    }
        
}

#Preview {
    TodayView()
        .environmentObject(Network())
}
