//
//  CreateMenuView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI

struct CreateMenuView: View {
    @EnvironmentObject var network: Network

    var body: some View {
        if (network.user != nil){
            Text("reate Menu and signed in")
        }else {
            LoginView()
                .environmentObject(network)
        }
    }
}

#Preview {
    CreateMenuView()
        .environmentObject(Network())
}
