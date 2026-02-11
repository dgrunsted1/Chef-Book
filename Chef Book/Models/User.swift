//
//  User.swift
//  Chef Book
//
//  Created by David Grunsted on 7/4/24.
//

import Foundation

struct User: Codable {
    var id: String
    var collectionId: String
    var collectionName: String
    var created: String
    var updated: String
    var username: String
    var email: String
    var verified: Bool
    var emailVisibility: Bool
    var avatar: String
    var name: String
}
