import Foundation

enum TradeAlertType: Identifiable {
    case confirmTrade, insufficientFunds, insufficientHoldings, tradeError, tradeSuccess
    
    var id: String { UUID().uuidString }
    
    var title: String {
        switch self {
        case .confirmTrade: return "Confirm Trade"
        case .insufficientFunds: return "Insufficient Funds"
        case .insufficientHoldings: return "Insufficient Holdings"
        case .tradeError: return "Trade Error"
        case .tradeSuccess: return "Trade Successful"
        }
    }
    
    var message: String {
        switch self {
        case .confirmTrade: return "Are you sure you want to execute this trade?"
        case .insufficientFunds: return "You don't have enough funds to complete this trade."
        case .insufficientHoldings: return "You don't have enough holdings to complete this trade."
        case .tradeError: return "An error occurred while executing the trade."
        case .tradeSuccess: return "Your trade has been executed successfully."
        }
    }
}

enum TradeAction {
    case buy, sell
}

enum TradeMode {
    case quantity, amount
}

enum TimeFrame: String, CaseIterable {
    case day = "24H"
    case week = "7D"
    case month = "30D"
    case year = "1Y"
    
    // Custom initializer for UserDefaults string
    init?(userDefaultsString: String) {
        self.init(rawValue: userDefaultsString)
    }
}