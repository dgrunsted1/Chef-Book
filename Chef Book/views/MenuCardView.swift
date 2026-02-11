//
//  MenuCardView.swift
//  Chef Book
//

import SwiftUI

struct MenuCardView: View {
    let menu: MyMenu

    var body: some View {
        HStack {
            if let firstRecipe = menu.recipes.first, firstRecipe.image != "" {
                AsyncImage(url: URL(string: firstRecipe.image)) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 75, height: 75)
                        .clipped()
                        .cornerRadius(8)
                } placeholder: {
                    ProgressView()
                        .frame(width: 75, height: 75)
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("NeutralColor").opacity(0.3))
                    .frame(width: 75, height: 75)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .foregroundColor(.gray)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(menu.title)
                    .font(.headline)
                Text("\(menu.recipes.count) recipes")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(formatDate(menu.created))
                    .font(.caption2)
                    .foregroundColor(.gray)
                if menu.today {
                    Text("Today's Menu")
                        .font(.caption)
                        .bold()
                        .foregroundColor(Color("MyPrimaryColor"))
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(8)
        .background(Color("Base200Color"))
        .cornerRadius(10)
    }

    private func formatDate(_ dateStr: String) -> String {
        // PocketBase dates come as "2024-07-08 12:00:00.000Z"
        let parts = dateStr.split(separator: " ")
        return parts.first.map(String.init) ?? dateStr
    }
}
