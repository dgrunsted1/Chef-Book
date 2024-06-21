//
//  Item.swift
//  Chef Book
//
//  Created by David Grunsted on 6/21/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
