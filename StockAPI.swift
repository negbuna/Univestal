//
//  StockAPI.swift
//  UV
//
//  Created by Nathan Egbuna on 7/19/24.
//

import Foundation

struct StockResponse: Decodable {
    let data: [Stock]
    let meta: Meta?
}

struct Stock: Decodable {
    let country: String
    let currency: String
    let publisher: String
    let ticker: String
}

struct Meta: Decodable {
    let pagination: Pagination
}

struct Pagination: Decodable {
    let page: Int
    let per_page: Int
}

func fetchStocks(page: Int, pageSize: Int, completion: @escaping ([Stock]?, Error?) -> Void) {
    // Load API key from Config.plist
    guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
          let config = NSDictionary(contentsOfFile: path),
          let apiKey = config["API_KEY"] as? String else {
        print("Failed to load API key from Config.plist")
        completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load API key"]))
        return
    }
    
    // Set up headers
    let headers = ["Authorization": "apikey \(apiKey)"]
    
    // Create URL request with pagination parameters
    let urlString = "https://api.finazon.io/latest/datasets?page=\(page)&page_size=\(pageSize)"
    print("Request URL: \(urlString)")
    
    guard let url = URL(string: urlString) else {
        completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
        return
    }
    
    var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    // Create URL session
    let session = URLSession.shared
    
    // Create data task
    let dataTask = session.dataTask(with: request) { (data, response, error) in
        if let error = error {
            print("Error: \(error)")
            completion(nil, error)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Invalid response")
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            return
        }
        
        guard let data = data else {
            print("No data received")
            completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
            return
        }
        
        // Debug: Print raw data
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON Response: \(jsonString)")
        }
        
        do {
            // Decode JSON response into StockResponse objects
            let stockResponse = try JSONDecoder().decode(StockResponse.self, from: data)
            let stocks = stockResponse.data
            completion(stocks, nil)
        } catch {
            print("Failed to parse JSON: \(error)")
            completion(nil, error)
        }
    }
    
    // Resume data task
    dataTask.resume()
}
