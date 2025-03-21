import Foundation

enum TradeInputError: LocalizedError {
    case invalidInput
    case numberFormatError
    case excessiveDecimals(limit: Int)
    case negativeValue
    case zeroValue
    case amountTooLarge(availableBalance: Double)
    case insufficientHoldings(available: Double)
    case invalidSymbol
    case quoteFetchError
    case marketClosed
    case minimumTradeAmount(minimum: Double)
    case maximumTradeAmount(maximum: Double)
    case invalidIncrement(increment: Double)
    case priceChanged(newPrice: Double)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Please enter a valid number"
        case .numberFormatError:
            return "Invalid number format"
        case .excessiveDecimals(let limit):
            return "Maximum \(limit) decimal places allowed"
        case .negativeValue:
            return "Amount cannot be negative"
        case .zeroValue:
            return "Amount must be greater than zero"
        case .amountTooLarge(let balance):
            return "Amount exceeds available balance ($\(String(format: "%.2f", balance)))"
        case .insufficientHoldings(let available):
            return "Insufficient holdings (Available: \(available))"
        case .invalidSymbol:
            return "Invalid trading symbol"
        case .quoteFetchError:
            return "Unable to fetch current price"
        case .marketClosed:
            return "Market is currently closed"
        case .minimumTradeAmount(let min):
            return "Minimum trade amount is $\(String(format: "%.2f", min))"
        case .maximumTradeAmount(let max):
            return "Maximum trade amount is $\(String(format: "%.2f", max))"
        case .invalidIncrement(let inc):
            return "Quantity must be in increments of \(inc)"
        case .priceChanged(let price):
            return "Price has changed to $\(String(format: "%.2f", price)). Please confirm the new price."
        }
    }
}
