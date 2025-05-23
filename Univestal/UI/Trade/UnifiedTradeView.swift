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
    
    private var isValidInput: Bool {
        switch tradeMode {
        case .quantity:
            guard let qty = Double(quantity), qty > 0 else { return false }
            return true
        case .amount:
            guard let amount = Double(dollarAmount), amount > 0 else { return false }
            // Check if amount exceeds available balance for buys
            if type == .buy && amount > environment.portfolioBalance {
                return false
            }
            return true
        }
    }
    
    private var effectiveQuantity: Double {
        switch tradeMode {
        case .quantity:
            return Double(quantity) ?? 0
        case .amount:
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
                                .onChange(of: quantity) {
                                    updatePreview()
                                }
                        } else {
                            TextField("Amount in USD", text: $dollarAmount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 200)
                                .onChange(of: dollarAmount) {
                                    updatePreview()
                                }
                        }
                        
                        // Show preview of the trade
                        if let preview = tradePreview {
                            VStack(spacing: 4) {
                                Text("You will \(type.title.lowercased()):")
                                    .font(.subheadline)
                                Text("\(AssetFormatter.format(quantity: preview.quantity)) \(asset.tradeSymbol)")
                                    .bold()
                                Text("Total: \(preview.total, specifier: "$%.2f")")
                                    .foregroundColor(.secondary)
                            }
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
                    .disabled(!isValidInput)
                    .opacity(isValidInput ? 1.0 : 0.5)
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
    
    @State private var tradePreview: (quantity: Double, total: Double)?
    
    private func updatePreview() {
        switch tradeMode {
        case .quantity:
            guard let qty = Double(quantity), qty > 0 else {
                tradePreview = nil
                return
            }
            tradePreview = (qty, qty * asset.currentPrice)
            
        case .amount:
            guard let amount = Double(dollarAmount), amount > 0 else {
                tradePreview = nil
                return
            }
            let qty = environment.calculateQuantityFromAmount(dollars: amount, price: asset.currentPrice)
            tradePreview = (qty, amount)
        }
    }
    
    private func executeTrade() {
        guard let preview = tradePreview else { return }
        alertType = nil
        
        do {
            switch type {
            case .buy:
                if asset is Coin {
                    try environment.executeTrade(
                        coinId: asset.assetId,
                        symbol: asset.tradeSymbol,
                        name: asset.tradeName,
                        quantity: preview.quantity,
                        currentPrice: asset.currentPrice
                    )
                } else if asset is Stock {
                    try environment.executeStockTrade(
                        symbol: asset.tradeSymbol,
                        name: asset.tradeName,
                        quantity: preview.quantity,
                        currentPrice: asset.currentPrice
                    )
                }
            case .sell:
                if asset is Coin {
                    try environment.executeSell(
                        coinId: asset.assetId,
                        symbol: asset.tradeSymbol,
                        name: asset.tradeName,
                        quantity: preview.quantity,
                        currentPrice: asset.currentPrice
                    )
                } else if asset is Stock {
                    try environment.executeStockSell(
                        symbol: asset.tradeSymbol,
                        name: asset.tradeName,
                        quantity: preview.quantity,
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
