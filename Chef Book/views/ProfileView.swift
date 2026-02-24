//
//  ProfileView.swift
//  Chef Book
//
//  Created by David Grunsted on 2/23/26.
//

import SwiftUI

struct ProfileView: View {
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
                // User info header
                VStack(spacing: 4) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color("MyPrimaryColor"))
                    Text(network.user!.record.name.isEmpty ? network.user!.record.username : network.user!.record.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(network.user!.record.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 12)

                Divider()

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

                // Logout button
                Button(action: {
                    network.sign_out()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Log Out")
                    }
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 8)
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
    ProfileView()
        .environmentObject(Network())
}
