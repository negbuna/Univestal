//
//  Config.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/12/24.
//

import Foundation

struct Config {
    static var alpacaKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["APCA-API-KEY-ID"] as? String else {
            fatalError("Alpaca API key not found in Config.plist")
        }
        return key
    }

    static var alpacaSecret: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["APCA-API-SECRET-KEY"] as? String else {
            fatalError("Alpaca secret not found in Config.plist")
        }
        return key
    }
    
    static var cryptoKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["CRYPTO-API"] as? String else {
            fatalError("CoinGecko API key not found in Config.plist")
        }
        return key
    }
    
    static var newsKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["NEWS-API"] as? String else {
            fatalError("CoinGecko API key not found in Config.plist")
        }
        return key
    }
    
    static var polygonKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["POLYGON-KEY"] as? String else {
            fatalError("Polygon key not found in Config.plist")
        }
        return key
    }
    
    static var finnhubKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["FINNHUB-KEY"] as? String else {
            fatalError("Finnhub key not found in Config.plist")
        }
        return key
    }
    
    static var finnhubSecret: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["FINNHUB-SECRET"] as? String else {
            fatalError("Finnhub secret not found in Config.plist")
        }
        return key
    }
}
