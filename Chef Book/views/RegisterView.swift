//
//  RegisterView.swift
//  Chef Book
//
//  Created by David Grunsted on 7/3/24.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var network: Network
    @State var username = ""
    @State var password = ""
    @State var confirmPassword = ""
    @State var email = ""
    @State var name = ""
    @State var errorMessage: String?
    @State var isRegistering = false

    var body: some View {
        VStack {
            Spacer()
            Form {
                TextField("username", text: $username)
                    .frame(width: 300)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled()
                TextField("email", text: $email)
                    .frame(width: 300)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled()
                TextField("name", text: $name)
                    .frame(width: 300)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SecureField("password", text: $password)
                    .frame(width: 300)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SecureField("confirm password", text: $confirmPassword)
                    .frame(width: 300)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    guard password == confirmPassword else {
                        errorMessage = "Passwords do not match"
                        return
                    }
                    guard !username.isEmpty, !password.isEmpty, !email.isEmpty else {
                        errorMessage = "Please fill in all required fields"
                        return
                    }
                    isRegistering = true
                    errorMessage = nil
                    network.register(username: username, password: password, passwordConfirm: confirmPassword, email: email, name: name) { success, error in
                        isRegistering = false
                        if !success {
                            errorMessage = error ?? "Registration failed"
                        }
                    }
                }, label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .accentColor(Color("MyPrimaryColor"))
                        if isRegistering {
                            ProgressView()
                        } else {
                            Text("register")
                                .foregroundColor(.black)
                                .bold()
                        }
                    }
                })
                .disabled(isRegistering)
            }
            Spacer()
        }
        .navigationTitle("Register")
    }
}

#Preview {
    RegisterView()
        .environmentObject(Network())
}
