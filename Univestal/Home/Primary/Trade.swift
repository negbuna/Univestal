//
//  Trade.swift
//  Univestal
//
//  Created by Nathan Egbuna on 12/9/24.
//

import SwiftUI

struct TradingView: View {
    @ObservedObject var crypto: Crypto
    @ObservedObject var tradingManager: PaperTradingManager
    @ObservedObject var simulator: PaperTradingSimulator
    @State private var showMenu: Bool = false
    @State private var showAlert: Bool = false
    @State private var showMockAlert: Bool = false
    @State private var insufficientFundsAlert: Bool = false
    @State private var selectedCoin: Coin?
    @State private var tradeErrorAlert: Bool = false
    @Binding var tradeUUID: UUID?

    var filteredCoins: [Coin] {
        if tradingManager.tradedCoin.isEmpty {
            return crypto.coins
        } else {
            return crypto.coins.filter { $0.name.lowercased().contains(tradingManager.tradedCoin.lowercased()) }
        }
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
                }
                .onAppear {
                    startPeriodicFetching()
                }
                .navigationTitle("Trading Simulator")
                .navigationBarTitleDisplayMode(.inline)
                .globeOverlay()
            }
        }
    }

    private var portfolioView: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 15)
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .foregroundStyle(Color(UIColor.secondarySystemBackground))
                .ignoresSafeArea()

            VStack {
                Text("Your Portfolio: \(tradingManager.portfolioValue.balance, specifier: "$%.2f")")
                    .bold()

                tradeButtons
            }
        }
    }

    private var tradeMenuView: some View {
        Group {
            if showMenu {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            showMenu = false
                        }
                    }

                VStack {
                    Text("Trade")
                        .foregroundStyle(.secondary)
                        .bold()

                    Divider()

                    TradeMenuView(
                        crypto: crypto,
                        tradingManager: tradingManager,
                        tradeUUID: $tradeUUID,
                        selectedCoin: $selectedCoin
                    )

                    Divider()

                    buttons
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 300)
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
                // Perform trade action here
                withAnimation(.easeInOut) {
                    showAlert = true
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Confirm Trade?"),
                    message: Text("This cannot be undone!"),
                    primaryButton: .destructive(Text("Cancel")),
                    secondaryButton: .default(Text("Confirm"), action: {
                        showMenu = false
                        if let coin = selectedCoin, let uuid = tradeUUID {
                            do {
                                try simulator.sellCoin(tradeId: uuid, currentPrice: coin.current_price)
                            } catch {
                                tradeErrorAlert = true
                            }
                        } else {
                            print("No coin selected")
                            tradeErrorAlert = true
                        }
                    })
                )
            }
            .alert(isPresented: $tradeErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text("An error occurred with the trade."),
                    primaryButton: .default(Text("OK")) {
                        tradeErrorAlert = false
                    },
                    secondaryButton: .cancel() // Dismisses the alert without any action
                )
            }
            .foregroundStyle(.green)
            .bold()
        }
        .padding(.horizontal)
    }

    private func startPeriodicFetching() {
        tradingManager.startTradingSimulation()
        Timer.publish(every: 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                tradingManager.startTradingSimulation()
            }
            .store(in: &crypto.cancellables)
    }
}

#Preview {
    @Previewable @State var tradeUUID: UUID? = UUID() // UUID for the preview
    
    TradingView(
        crypto: Crypto(),
        tradingManager: PaperTradingManager(crypto: Crypto(), simulator: PaperTradingSimulator(initialBalance: 100_000.0)),
        simulator: PaperTradingSimulator(initialBalance: 100_000.0),
        tradeUUID: $tradeUUID)
}

extension TradingView {
    private var tradeButtons: some View {
        HStack {
            Button("Start Trade") {
                withAnimation(.easeInOut) {
                    showMenu = true
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Trade Bitcoin") {
                tradingManager.performAutomaticTrade(coinId: "bitcoin")
                showMockAlert = true
            }
            .buttonStyle(.bordered)
            .alert("Error: Insufficient funds", isPresented: $showMockAlert) {
                Button("OK", role: .cancel) { }
            }
        }
        .padding(.vertical)
    }
}

struct TradeMenuView: View {
    @ObservedObject var crypto: Crypto
    @ObservedObject var tradingManager: PaperTradingManager
    @State private var hasFetchedCoins = false
    @Binding var tradeUUID: UUID?
    @Binding var selectedCoin: Coin? // Bind to the selected coin
    
    var filteredCoins: [Coin] {
        if tradingManager.tradedCoin.isEmpty {
            return crypto.coins
        } else {
            return crypto.coins.filter {
                $0.name.lowercased().contains(tradingManager.tradedCoin.lowercased())
            }
        }
    }

    var body: some View {
        VStack {
            TextField("Enter Coin", text: $tradingManager.tradedCoin)
                .padding(.horizontal)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: tradingManager.tradedCoin) {
                    // This automatically updates the `filteredCoins` dynamically
                    print("All Coins: \(crypto.coins.map { $0.name })")
                }
            TextField("Quantity", text: $tradingManager.tradedQuantity)
                .padding(.horizontal)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if !tradingManager.tradedCoin.isEmpty {
                Picker("Select a Coin", selection: $selectedCoin) {
                    ForEach(filteredCoins, id: \.id) { coin in
                        Text(coin.name)
                            .tag(coin as Coin?)
                    }
                }
                .pickerStyle(MenuPickerStyle()) // Use MenuPickerStyle for a dropdown-like interface
                
                if let coin = selectedCoin,
                   let quantity = Double(tradingManager.tradedQuantity), quantity > 0 {
                    // Coin is valid and quantity is a valid number
                    let tradeSummary = coin.current_price * quantity
                    VStack(spacing: 8) {
                        Text("Trade Summary")
                            .font(.headline)
                        Text("\(quantity) \(coin.symbol.uppercased()) = \(String(format: "$%.2f", tradeSummary))")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(UIColor.systemGroupedBackground))
                            .shadow(radius: 5)
                    )
                    .padding(.horizontal)
                } else if !tradingManager.tradedCoin.isEmpty && !tradingManager.tradedQuantity.isEmpty {
                    // Invalid coin or quantity
                    Text("Invalid coin or quantity")
                }
            }
        }
        .padding()
        .onAppear {
            tradeUUID = UUID()
            if !hasFetchedCoins {
                crypto.fetchCoins()
                hasFetchedCoins = true
            }
        }
    }
}
