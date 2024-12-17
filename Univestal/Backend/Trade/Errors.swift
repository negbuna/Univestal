//
//  Errors.swift
//  Univestal
//
//  Created by Nathan Egbuna on 12/9/24.
//

import Foundation
import CoreData

// Custom Error Types
enum PaperTradingError: Error {
    case insufficientBalance
    case tradeNotFound
    case invalidQuantity
    case apiError(String)
    case storageError(String)
    case insufficientHoldings
    case generalError
    
    var localizedDescription: String {
        switch self {
        case .insufficientBalance:
            return "Insufficient balance to complete the transaction"
        case .tradeNotFound:
            return "The specified trade could not be found"
        case .invalidQuantity:
            return "Invalid trading quantity"
        case .apiError(let message):
            return "API Error: \(message)"
        case .storageError(let message):
            return "Storage Error: \(message)"
        case .insufficientHoldings:
            return "You don't have enough holdings to complete this trade."
        default:
            return "Something went wrong."
        }
    }
}
