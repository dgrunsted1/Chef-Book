//
//  LoginView.swift
//  Chef Book
//
//  Created by David Grunsted on 7/3/24.
//

import SwiftUI

struct LoginView: View {
    @State var email = ""
    @State var password = ""
    var body: some View {
        VStack {
            Spacer()
            Form {
                TextField("email", text: $email)
                    .frame(width: 300)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SecureField("password", text: $password)
                    .frame(width: 300)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    //attempt login here
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
                
            }
        }
    }
}

#Preview {
    LoginView()
}
