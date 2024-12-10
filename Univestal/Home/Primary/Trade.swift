//
//  Trade.swift
//  Univestal
//
//  Created by Nathan Egbuna on 12/9/24.
//

import SwiftUI
import Combine

struct TradingView: View {
    @ObservedObject var crypto: Crypto
    @ObservedObject var tradingManager: PaperTradingManager
    
    var body: some View {
        VStack {
            Button("Start Trading Simulation") {
                tradingManager.startTradingSimulation()
            }
            
            Button("Trade Bitcoin") {
                tradingManager.performAutomaticTrade(coinId: "bitcoin")
            }
        }
        .onAppear {
            startPeriodicFetching()
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

