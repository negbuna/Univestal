import SwiftUI
import Combine

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

// Make a protocol to consolidate assets
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
    @State private var tradeMode: TradeMode = .quantity
    @State private var dollarAmount: String = ""
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var environment: TradingEnvironment
    
    private var isValidQuantity: Bool {
        guard let qty = Double(quantity), qty > 0 else {
            return false
        }
        return true
    }
    
    private var effectiveQuantity: Double {
        if tradeMode == .quantity {
            return Double(quantity) ?? 0
        } else {
            let amount = Double(dollarAmount) ?? 0
            return environment.calculateQuantityFromAmount(dollars: amount, price: asset.currentPrice)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("\(type.title) \(asset.tradeName)")
                        .font(.headline)
                    
                    if type == .sell {
                        if let currentHolding = getCurrentHolding() {
                            HoldingSummaryView(
                                asset: asset,
                                currentHolding: currentHolding,
                                sellingAmount: effectiveQuantity
                            )
                        }
                    }
                    
                    VStack(spacing: 10) {
                        Text("Available Balance: \(environment.portfolioBalance, specifier: "$%.2f")")
                            .font(.subheadline)
                        
                        Picker("Trade Mode", selection: $tradeMode) {
                            Text("Quantity").tag(TradeMode.quantity)
                            Text("Amount ($)").tag(TradeMode.amount)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if tradeMode == .quantity {
                            TextField("Quantity", text: $quantity)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        } else {
                            TextField("Amount in USD", text: $dollarAmount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                        }
                        
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
    
    private func getCurrentHolding() -> Double? {
        let holdings = environment.holdings
        return holdings.first { 
            $0.id == asset.assetId && 
            ((asset is Coin && $0.type == .crypto) || 
             (asset is Stock && $0.type == .stock))
        }?.quantity
    }
    
    private func executeTrade() {
        let qty: Double
        if tradeMode == .quantity {
            guard let inputQty = Double(quantity), inputQty > 0 else { return }
            qty = inputQty
        } else {
            guard let amount = Double(dollarAmount), amount > 0 else { return }
            qty = environment.calculateQuantityFromAmount(dollars: amount, price: asset.currentPrice)
        }
        
        // Clear any existing alert first
        alertType = nil
        
        do {
            switch type {
            case .buy:
                if asset is Coin {
                    try environment.executeTrade(
                        coinId: asset.assetId,
                        symbol: asset.tradeSymbol,
                        name: asset.tradeName,
                        quantity: qty,
                        currentPrice: asset.currentPrice
                    )
                } else if asset is Stock {
                    try environment.executeStockTrade(
                        symbol: asset.tradeSymbol,
                        name: asset.tradeName,
                        quantity: qty,
                        currentPrice: asset.currentPrice
                    )
                }
            case .sell:
                if asset is Coin {
                    try environment.executeSell(
                        coinId: asset.assetId,
                        symbol: asset.tradeSymbol,
                        name: asset.tradeName,
                        quantity: qty,
                        currentPrice: asset.currentPrice
                    )
                } else if asset is Stock {
                    try environment.executeStockSell(
                        symbol: asset.tradeSymbol,
                        name: asset.tradeName,
                        quantity: qty,
                        currentPrice: asset.currentPrice
                    )
                }
            }
            dismiss()
        } catch {
            print("DEBUG: Trade error: \(error)")
            alertType = .tradeError
        }
    }
}
