//
//  MyMenusView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI

struct MyMenusView: View {
    @EnvironmentObject var network: Network

    var body: some View {
        if (network.user != nil){
            Text("My Menus and signed in")
        }else {
            LoginView()
                .environmentObject(network)
        }
    }
}

#Preview {
    MyMenusView()
        .environmentObject(Network())
}

