//
//  MyMenusView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI

struct MyMenusView: View {
    @EnvironmentObject var network: Network
    @State private var searchText = ""

    var filteredMenus: [MyMenu] {
        if searchText.isEmpty {
            return network.menus
        }
        return network.menus.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        if network.user != nil {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search menus...", text: $searchText)
                        .autocorrectionDisabled()
                }
                .padding(10)
                .background(Color("Base200Color"))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)

                if network.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredMenus.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "menucard")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("No menus yet")
                            .foregroundColor(.gray)
                        Text("Create one from the Create tab")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredMenus) { menu in
                                NavigationLink(destination: MenuDetailView(menu: menu).environmentObject(network)) {
                                    MenuCardView(menu: menu)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    if !menu.today {
                                        Button {
                                            network.set_today_menu(menuId: menu.id) { _ in }
                                        } label: {
                                            Label("Set as Today", systemImage: "house")
                                        }
                                    }
                                    Button(role: .destructive) {
                                        network.delete_menu(id: menu.id) { _ in }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .refreshable {
                        network.get_menus()
                    }
                }
            }
            .onAppear {
                network.get_menus()
            }
        } else {
            LoginView()
                .environmentObject(network)
        }
    }
}

#Preview {
    MyMenusView()
        .environmentObject(Network())
}
