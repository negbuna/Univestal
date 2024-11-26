//
//  Config.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/12/24.
//

//import Foundation
//
//struct Config {
//    static var apiKey: String {
//        guard let key = Bundle.main.infoDictionary?["APIKey"] as? String else {
//            fatalError("APIKey not found in Config.plist")
//        }
//        return key
//    }
//
//    static var secretKey: String {
//        guard let key = Bundle.main.infoDictionary?["SecretKey"] as? String else {
//            fatalError("SecretKey not found in Config.plist")
//        }
//        return key
//    }
//}

import Foundation

struct Config {
    static var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["APCA-API-KEY-ID"] as? String else {
            fatalError("APIKey not found in Config.plist")
        }
        print("APIKey: \(key)")
        return key
    }

    static var secretKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let key = config["APCA-API-SECRET-KEY"] as? String else {
            fatalError("SecretKey not found in Config.plist")
        }
        print("SecretKey: \(key)")
        return key
    }
}
