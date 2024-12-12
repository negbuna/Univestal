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
    @State private var showMenu: Bool = false // Tracks the visibility of the menu

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack { // Main Trading Interface
                    Spacer()
                    
                    VStack {
                        Button("Start Trading") {
                            withAnimation(.easeInOut) {
                                showMenu = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        Button("Trade Bitcoin") {
                            tradingManager.performAutomaticTrade(coinId: "bitcoin")
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity) // Make sure the buttons container stretches horizontally
                    .frame(maxHeight: .infinity) // Stretches vertically too, allowing for centering

                    Spacer()
                }
                .onAppear {
                    startPeriodicFetching()
                }
                .globeOverlay2()

                if showMenu {
                    // Background Dim
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                showMenu = false
                            }
                        }

                    VStack(spacing: 16) {
                        // Header
                        Text("Trade")
                            .font(.headline)
                            .padding(.top)

                        Divider()

                        // Input Fields
                        VStack(spacing: 12) {
                            TextField("Enter Coin", text: $tradingManager.tradedCoin)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)

                            TextField("Enter Quantity", text: $tradingManager.tradedQuantity)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding(.horizontal)
                        }

                        Divider()

                        // Buttons
                        HStack {
                            Button("Cancel") {
                                withAnimation(.easeInOut) {
                                    showMenu = false
                                }
                            }
                            .foregroundColor(.red)

                            Spacer()

                            Button("Confirm Trade") {
                                // Perform trade action here
                                withAnimation(.easeInOut) {
                                    showMenu = false
                                }
                            }
                            .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.2)]), startPoint: .top, endPoint: .bottom))
                            .shadow(radius: 10)
                    )
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut, value: showMenu)
                }
            }
        }
    }

    private func startPeriodicFetching() {
        // Fetch immediately
        tradingManager.startTradingSimulation()
        
        // Set up periodic fetching using Combine
        Timer.publish(every: 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                tradingManager.startTradingSimulation()
            }
            .store(in: &crypto.cancellables)
    }
}

#Preview {
    TradingView(crypto: Crypto(), tradingManager: PaperTradingManager())
}

struct GlobeOverlay2: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topLeading) {
                Image(systemName: "globe")
                    .foregroundStyle(.primary)
                    .opacity(0.07)
                    .font(.system(size: 800))
                    .offset(x: 20, y: 2)
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func globeOverlay2() -> some View {
        self.modifier(GlobeOverlay2())
    }
}
