//
//  LoginView.swift
//  Chef Book
//
//  Created by David Grunsted on 7/3/24.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var network: Network
    @State var username = ""
    @State var password = ""
    var body: some View {
        VStack {
            Spacer()
            Form {
                TextField("username", text: $username)
                    .frame(width: 300)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled()
                SecureField("password", text: $password)
                    .frame(width: 300)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    network.sign_in(username: username, password: password)
                }, label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .accentColor(Color("MyPrimaryColor"))
                        Text("log in")
                            .foregroundColor(.black)
                            .bold()
                    }
                })
            }
            VStack {
                NavigationLink(destination: RegisterView().environmentObject(network)) {
                    Text("Don't have an account? Register")
                        .foregroundColor(Color("MyPrimaryColor"))
                }
                .padding()
            }
        }
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(Network())
    }
}
