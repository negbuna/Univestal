//
//  Trade.swift
//  Univestal
//
//  Created by Nathan Egbuna on 12/9/24.
//

import SwiftUI

struct TradingView: View {
    @EnvironmentObject var environment: TradingEnvironment
    @State private var showMenu: Bool = false
    @State private var activeAlert: TradeAlertType?
    @State private var selectedCoin: Coin?
    @State private var tradeErrorAlert: Bool = false
    @Binding var tradeUUID: UUID?
    
    var filteredCoins: [Coin] {
        if tradedCoin.isEmpty {
            return environment.crypto.coins
        } else {
            return environment.crypto.coins.filter { $0.name.lowercased().contains(tradedCoin.lowercased()) }
        }
    }
    
    @State private var tradedCoin: String = ""
    @State private var tradedQuantity: String = ""
    
    enum TradeAlertType: Identifiable {
        var id: String { UUID().uuidString }
        case confirmTrade, insufficientFunds, tradeError
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    if !showMenu {
                        portfolioView
                    }
                    tradeMenuView
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .onAppear {
                    startPeriodicFetching()
                }
                .navigationTitle("Trading Simulator")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        NavigationLink("History") {
                            PastTrades()
                        }
                    }
                }
                .globeOverlay()
            }
        }
    }

    private var portfolioView: some View {
        VStack {
            Text("Your Portfolio: \(environment.portfolioBalance, specifier: "$%.2f")")
                .bold()
            tradeButtons
        }
    }

    private var tradeMenuView: some View {
        Group {
            if showMenu {
                VStack {
                    Text("Trade")
                        .foregroundStyle(.secondary)
                        .bold()

                    Divider()

                    TradeMenuView(
                        selectedCoin: $selectedCoin,
                        tradedCoin: $tradedCoin,
                        tradedQuantity: $tradedQuantity
                    )

                    Divider()

                    buttons
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(radius: 10)
                )
                .transition(.move(edge: .bottom))
            }
        }
    }

    private var buttons: some View {
        HStack {
            Button("Cancel") {
                withAnimation(.easeInOut) {
                    showMenu = false
                }
            }
            .foregroundStyle(.red)
            .bold()

            Spacer()

            Button("Confirm") {
                executeTrade()
            }
            .foregroundStyle(.green)
            .bold()
        }
        .padding(.horizontal)
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .confirmTrade:
                return Alert(
                    title: Text("Confirm Trade"),
                    message: Text("Are you sure you want to execute this trade?"),
                    primaryButton: .default(Text("Confirm")) {
                        executeTrade()
                    },
                    secondaryButton: .cancel()
                )
            case .insufficientFunds:
                return Alert(
                    title: Text("Insufficient Funds"),
                    message: Text("You don't have enough funds to complete this trade."),
                    dismissButton: .default(Text("OK"))
                )
            case .tradeError:
                return Alert(
                    title: Text("Trade Error"),
                    message: Text("An error occurred while executing the trade."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func executeTrade() {
        guard let coin = selectedCoin,
              let quantity = Double(tradedQuantity) else {
            activeAlert = .tradeError
            return
        }

        do {
            try environment.executeTrade(
                coinId: coin.id,
                symbol: coin.symbol,
                name: coin.name,
                quantity: quantity,
                currentPrice: coin.current_price
            )
            withAnimation(.easeInOut) {
                showMenu = false
            }
        } catch PaperTradingError.insufficientFunds {
            activeAlert = .insufficientFunds
        } catch {
            activeAlert = .tradeError
        }
    }

    private func startPeriodicFetching() {
        environment.crypto.fetchCoins()
        
        Timer.publish(every: 20.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                environment.crypto.fetchCoins()
                
                // Update trade prices with latest coin prices
                let prices = Dictionary(
                    uniqueKeysWithValues: environment.crypto.coins.map { 
                        ($0.id, $0.current_price) 
                    }
                )
                environment.updatePrices(with: prices)
            }
            .store(in: &environment.crypto.cancellables)
    }
}

struct TradeMenuView: View {
    @EnvironmentObject var environment: TradingEnvironment
    @Binding var selectedCoin: Coin?
    @Binding var tradedCoin: String
    @Binding var tradedQuantity: String
    
    var filteredCoins: [Coin] {
        if tradedCoin.isEmpty {
            return environment.crypto.coins
        } else {
            return environment.crypto.coins.filter {
                $0.name.lowercased().contains(tradedCoin.lowercased())
            }
        }
    }

    var body: some View {
        VStack {
            TextField("Enter Coin", text: $tradedCoin)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Quantity", text: $tradedQuantity)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !tradedCoin.isEmpty {
                Picker("Select a Coin", selection: $selectedCoin) {
                    ForEach(filteredCoins, id: \.id) { coin in
                        Text(coin.name)
                            .tag(coin as Coin?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                if let coin = selectedCoin,
                   let quantity = Double(tradedQuantity),
                   quantity > 0 {
                    VStack(spacing: 8) {
                        Text("Trade Summary")
                            .font(.headline)
                        Text("\(quantity) \(coin.symbol.uppercased()) = \(String(format: "$%.2f", coin.current_price * quantity))")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.systemGroupedBackground))
                    )
                }
            }
        }
        .padding()
    }
}

#Preview {
    TradingView(tradeUUID: .constant(UUID()))
        .environmentObject(TradingEnvironment.shared)
}
