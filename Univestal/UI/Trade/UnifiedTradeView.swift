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

enum TradeInputType {
    case dollars
    case quantity
    
    var placeholder: String {
        switch self {
        case .dollars: return "Enter amount in USD"
        case .quantity: return "Enter quantity"
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

enum TradeError: LocalizedError {
    case invalidInput
    case numberFormatError
    case excessiveDecimals
    case negativeValue
    case zeroValue
    case amountTooLarge
    
    var errorDescription: String? {
        switch self {
        case .invalidInput: return "Please enter a valid number"
        case .numberFormatError: return "Invalid number format"
        case .excessiveDecimals: return "Too many decimal places"
        case .negativeValue: return "Amount cannot be negative"
        case .zeroValue: return "Amount must be greater than zero"
        case .amountTooLarge: return "Amount exceeds available balance"
        }
    }
}

struct UnifiedTradeView: View {
    let asset: Tradeable
    let type: TradeType
    @State private var quantity: String = ""
    @State private var showAlert = false
    @State private var alertType: TradeAlertType?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var environment: TradingEnvironment
    @State private var inputType: TradeInputType = .dollars
    @State private var input: String = ""
    @State private var tradeError: TradeInputError?
    @State private var showErrorAlert = false
    @State private var showConfirmation = false
    @State private var priceAtConfirmation: Double = 0
    @State private var confirmationTimer: Timer?
    
    private var isValidInput: Bool {
        guard let value = Double(input.replacingOccurrences(of: "$", with: "")) else {
            return false
        }
        
        switch inputType {
        case .dollars:
            return value > 0 && value <= environment.portfolioBalance
        case .quantity:
            return value > 0 && (value * asset.currentPrice) <= environment.portfolioBalance
        }
    }
    
    private func calculateQuantity() -> Double? {
        guard let value = Double(input.replacingOccurrences(of: "$", with: "")) else {
            return nil
        }
        
        switch inputType {
        case .dollars:
            return value / asset.currentPrice
        case .quantity:
            return value
        }
    }
    
    private func validateTradeInput(_ input: String) -> Result<Double, TradeInputError> {
        // Remove dollar sign and whitespace
        let cleanInput = input.replacingOccurrences(of: "$", with: "").trimmingCharacters(in: .whitespaces)
        
        // Check for empty input
        guard !cleanInput.isEmpty else {
            return .failure(.invalidInput)
        }
        
        // Check number format
        guard let value = Double(cleanInput) else {
            return .failure(.numberFormatError)
        }
        
        // Check for negative values
        guard value >= 0 else {
            return .failure(.negativeValue)
        }
        
        // Check for zero value
        guard value > 0 else {
            return .failure(.zeroValue)
        }
        
        // Check decimal places (max 8)
        let components = cleanInput.components(separatedBy: ".")
        if components.count > 1 && components[1].count > 8 {
            return .failure(.excessiveDecimals(limit: 8))
        }
        
        // Check if amount exceeds balance
        let totalCost = inputType == .dollars ? value : value * asset.currentPrice
        guard totalCost <= environment.portfolioBalance else {
            return .failure(.amountTooLarge(availableBalance: environment.portfolioBalance))
        }
        
        // For sell orders, check holdings
        if type == .sell {
            if let holdings = environment.holdings.first(where: { $0.symbol == asset.tradeSymbol }) {
                guard value <= holdings.quantity else {
                    return .failure(.insufficientHoldings(available: holdings.quantity))
                }
            } else {
                return .failure(.insufficientHoldings(available: 0))
            }
        }
        
        return .success(value)
    }
    
    private var inputValidation: (isValid: Bool, errorMessage: String?) {
        switch validateTradeInput(input) {
        case .success(_):
            return (true, nil)
        case .failure(let error):
            return (false, error.localizedDescription)
        }
    }

    private var currentHolding: AssetHolding? {
        environment.holdings.first { $0.symbol == asset.tradeSymbol }
    }
    
    private var tradeSummary: some View {
        VStack(spacing: 12) {
            // Show current holdings info for both buy and sell
            if let holding = currentHolding {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Holdings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(holding.quantity, specifier: "%.4f") \(asset.tradeSymbol)")
                            .font(.headline)
                        Text("≈ \(holding.totalValue, specifier: "$%.2f")")
                            .foregroundColor(.secondary)
                    }
                    
                    // Show P/L for holdings
                    HStack {
                        Text("Avg. Cost:")
                        Text("\(holding.purchasePrice, specifier: "$%.2f")")
                            .foregroundColor(.secondary)
                        Text("P/L:")
                        Text("\(holding.profitLoss >= 0 ? "+" : "")\(holding.profitLoss, specifier: "$%.2f")")
                            .foregroundColor(holding.profitLoss >= 0 ? .green : .red)
                    }
                    .font(.caption)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }

            // Trade preview
            if let quantity = calculateQuantity() {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trade Preview")
                        .font(.headline)
                    
                    HStack {
                        Text("Amount:")
                        Spacer()
                        Text("\(quantity, specifier: "%.4f") \(asset.tradeSymbol)")
                    }
                    
                    HStack {
                        Text("Price:")
                        Spacer()
                        Text("\(asset.currentPrice, specifier: "$%.2f")")
                    }
                    
                    HStack {
                        Text("Total:")
                        Spacer()
                        Text("\(quantity * asset.currentPrice, specifier: "$%.2f")")
                            .bold()
                    }
                    
                    // Show remaining balance after trade
                    if type == .buy {
                        HStack {
                            Text("Remaining Balance:")
                            Spacer()
                            Text("\(environment.portfolioBalance - (quantity * asset.currentPrice), specifier: "$%.2f")")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private var confirmationView: some View {
        VStack(spacing: 16) {
            Text("Confirm \(type.title) Order")
                .font(.headline)
            
            if priceAtConfirmation != asset.currentPrice {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text("Price has changed")
                        .foregroundColor(.secondary)
                }
                Text("New price: \(asset.currentPrice, specifier: "$%.2f")")
                Text("Old price: \(priceAtConfirmation, specifier: "$%.2f")")
            }
            
            // ...rest of confirmation details...
            
            HStack {
                Button("Cancel") {
                    showConfirmation = false
                }
                .buttonStyle(.bordered)
                
                Button("Confirm") {
                    executeTradeWithConfirmation()
                }
                .buttonStyle(.borderedProminent)
                .disabled(confirmationTimer == nil)
            }
        }
        .padding()
        .onAppear {
            priceAtConfirmation = asset.currentPrice
            startConfirmationTimer()
        }
        .onDisappear {
            confirmationTimer?.invalidate()
        }
    }
    
    private func startConfirmationTimer() {
        confirmationTimer?.invalidate()
        confirmationTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { _ in
            showConfirmation = false
        }
    }
    
    private func executeTradeWithConfirmation() {
        guard let quantity = calculateQuantity() else { return }
        
        do {
            if type == .buy {
                try environment.executeTrade(
                    coinId: asset.assetId,
                    symbol: asset.tradeSymbol,
                    name: asset.tradeName,
                    quantity: quantity,
                    currentPrice: asset.currentPrice
                )
            } else {
                try environment.executeSell(
                    coinId: asset.assetId,
                    symbol: asset.tradeSymbol,
                    name: asset.tradeName,
                    quantity: quantity,
                    currentPrice: asset.currentPrice
                )
            }
            dismiss()
        } catch {
            if let tradeError = error as? TradeInputError {
                self.tradeError = tradeError
                showErrorAlert = true
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("\(type.title) \(asset.tradeName)")
                        .font(.headline)
                    
                    VStack(spacing: 10) {
                        Text("Available Balance: \(environment.portfolioBalance, specifier: "$%.2f")")
                            .font(.subheadline)
                        
                        Picker("Input Type", selection: $inputType) {
                            Text("USD").tag(TradeInputType.dollars)
                            Text("Quantity").tag(TradeInputType.quantity)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        TextField(inputType.placeholder, text: $input)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                            .onChange(of: input) {
                                // Clean the input
                                input = input.filter { "0123456789.$".contains($0) }
                                
                                // Handle dollar sign prefix for dollar input
                                if inputType == .dollars && !input.isEmpty && !input.hasPrefix("$") {
                                    input = "$" + input
                                }
                                
                                // Ensure only one decimal point
                                let decimals = input.filter { $0 == "." }.count
                                if decimals > 1 {
                                    input = String(input.prefix(while: { $0 != "." })) + "." + 
                                           input.suffix(from: input.index(after: input.firstIndex(of: ".")!))
                                }
                            }
                        
                        if let quantity = calculateQuantity() {
                            switch inputType {
                            case .dollars:
                                Text("Quantity: \(quantity, specifier: "%.4f") \(asset.tradeSymbol.uppercased())")
                                    .foregroundColor(.secondary)
                            case .quantity:
                                Text("Total: \(quantity * asset.currentPrice, specifier: "$%.2f")")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    
                    tradeSummary
                    
                    if let errorMessage = inputValidation.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Button("Confirm \(type.title)") {
                        showConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValidInput) // Disable button when input is invalid
                    .opacity(isValidInput ? 1.0 : 0.5) // Visual feedback
                }
                .padding()
            }
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
        .alert("Trade Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(tradeError?.localizedDescription ?? "An unknown error occurred")
        }
        .sheet(isPresented: $showConfirmation) {
            confirmationView
        }
    }
    
    private func executeTrade() {
        switch validateTradeInput(input) {
        case .success(let value):
            do {
                let quantity = inputType == .dollars ? value / asset.currentPrice : value
                switch type {
                case .buy:
                    try environment.executeTrade(
                        coinId: asset.assetId,
                        symbol: asset.tradeSymbol,
                        name: asset.tradeName,
                        quantity: quantity,
                        currentPrice: asset.currentPrice
                    )
                case .sell:
                    try environment.executeSell(
                        coinId: asset.assetId,
                        symbol: asset.tradeSymbol,
                        name: asset.tradeName,
                        quantity: quantity,
                        currentPrice: asset.currentPrice
                    )
                }
                dismiss()
            } catch {
                tradeError = .quoteFetchError
                showErrorAlert = true
            }
        case .failure(let error):
            tradeError = error
            showErrorAlert = true
        }
    }
}
