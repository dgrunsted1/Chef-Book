//
//  AddRecipeView.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import SwiftUI

struct AddRecipeView: View {
    @EnvironmentObject var network: Network

    var body: some View {
        if (network.user != nil){
            Text("Add a recipe and signed in")
        }else {
            LoginView()
                .environmentObject(network)
        }
    }
}

#Preview {
    AddRecipeView()
        .environmentObject(Network())
}
