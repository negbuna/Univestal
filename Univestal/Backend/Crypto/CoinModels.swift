//
//  CoinModels.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/25/24.
//

import Foundation
import Combine

struct Coin: Codable, Identifiable, Hashable {
    let name: String
    let symbol: String
    let id: String
    let current_price: Double
    let market_cap: Double
    let total_volume: Double
    
    // Optional detailed coin data
    let high_24h: Double?
    let low_24h: Double?
    let price_change_24h: Double?
    let price_change_percentage_24h: Double?
    let image: String?
    let sparkline_in_7d: SparklineData? // Optional sparkline data
    
    struct SparklineData: Codable, Hashable {
        let price: [Double]? // Historical prices for sparkline
    }
}

struct CoinResponse: Codable { // List of fetched Coins
    let coins: [Coin]
}
