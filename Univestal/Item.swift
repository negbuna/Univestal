//
//  Item.swift
//  Univestal
//
//  Created by Nathan Egbuna on 6/18/24.
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
