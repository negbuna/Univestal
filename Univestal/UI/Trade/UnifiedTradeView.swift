import SwiftUI

enum TradeType {
    case buy, sell
    
    var title: String {
        switch self {
        case .buy: return "Buy"
        case .sell: return "Sell"
        }
    }
    
    var color: Color {
        switch self {
        case .buy: return .blue
        case .sell: return .gray.opacity(0.2)
        }
    }
}

// Make a protocal to consolidate the assets in buy/sell UI
protocol Tradeable {
    var tradeSymbol: String { get }
    var tradeName: String { get }
    var currentPrice: Double { get }
    var assetId: String { get }
}

extension Coin: Tradeable {
    var tradeSymbol: String { symbol }
    var tradeName: String { name }
    var currentPrice: Double { current_price }
    var assetId: String { id }
}

extension Stock: Tradeable {
    var tradeSymbol: String { symbol }
    var tradeName: String { lookup?.description ?? symbol }
    var currentPrice: Double { quote.currentPrice }
    var assetId: String { symbol }
}

struct UnifiedTradeView: View {
    let asset: Tradeable
    let type: TradeType
    @State private var quantity: String = ""
    @State private var showAlert = false
    @State private var alertType: TradeAlertType?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var environment: TradingEnvironment
    
    private var isValidQuantity: Bool {
        guard let qty = Double(quantity), qty > 0 else {
            return false
        }
        return true
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("\(type.title) \(asset.tradeName)")
                    .font(.headline)
                
                VStack(spacing: 10) {
                    Text("Available Balance: \(environment.portfolioBalance, specifier: "$%.2f")")
                        .font(.subheadline)
                    
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                    
                    if let qty = Double(quantity) {
                        let total = qty * asset.currentPrice
                        Text("Total: \(total, specifier: "$%.2f")")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.secondary.opacity(0.1))
                )
                
                Button("Confirm \(type.title)") {
                    executeTrade()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidQuantity) // Disable button when quantity is invalid
                .opacity(isValidQuantity ? 1.0 : 0.5) // Visual feedback
            }
            .padding()
            .alert(item: $alertType) { type in
                Alert(
                    title: Text(type.title),
                    message: Text(type.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private func executeTrade() {
        guard let qty = Double(quantity), qty > 0 else { return }
        
        do {
            switch type {
            case .buy:
                try environment.executeTrade(
                    coinId: asset.assetId,
                    symbol: asset.tradeSymbol,
                    name: asset.tradeName,
                    quantity: qty,
                    currentPrice: asset.currentPrice
                )
            case .sell:
                try environment.executeSell(
                    coinId: asset.assetId,
                    symbol: asset.tradeSymbol,
                    name: asset.tradeName,
                    quantity: qty,
                    currentPrice: asset.currentPrice
                )
            }
            dismiss()
        } catch PaperTradingError.insufficientBalance {
            alertType = .insufficientFunds
        } catch PaperTradingError.insufficientHoldings {
            alertType = .insufficientHoldings
        } catch {
            alertType = .tradeError
        }
    }
}
