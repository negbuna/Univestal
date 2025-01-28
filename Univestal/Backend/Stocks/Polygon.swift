//
//  Polygon.swift
//  Univestal
//
//  Created by Nathan Egbuna on 1/21/25.
//

import Foundation

class PolygonAPI {
    private let apiKey = Config.polygonKey
    
    // Fetch stock data for the given ticker and date range
    func fetchStockData(
        ticker: String,
        from: String? = nil,
        to: String? = nil,
        completion: @escaping (Result<[StockData], Error>) -> Void
    ) throws {
        // Use default date range if none is provided
        let dateRange = getDefaultDateRange()
        let fromDate = from ?? dateRange.from
        let toDate = to ?? dateRange.to
        
        // Build the request URL
        let urlString = "https://api.polygon.io/v2/aggs/ticker/\(ticker)/range/1/day/\(fromDate)/\(toDate)?adjusted=true&sort=desc&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        // Create the request
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                // Decode the JSON response
                let polygonResponse = try JSONDecoder().decode(PolygonResponse.self, from: data)
                if let results = polygonResponse.results {
                    completion(.success(results))
                } else {
                    completion(.failure(NSError(domain: "No results found", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        // Start the network request
        task.resume()
    }
    
    private func handleAPIError(_ response: PolygonResponse) throws {
        if response.status == "ERROR" {
            if response.error?.contains("429") == true {
                throw PaperTradingError.apiLimitExceeded
            }
            throw PaperTradingError.apiError(response.error ?? "Unknown error")
        }
    }
}

extension PolygonAPI {
    // Get today's date in "yyyy-MM-dd" format
    private func getToday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // Get the default date range (last 3 months to today)
    private func getDefaultDateRange() -> (from: String, to: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: today)!
        
        let fromDate = dateFormatter.string(from: threeMonthsAgo)
        let toDate = dateFormatter.string(from: today)
        
        return (from: fromDate, to: toDate)
    }
    
    func fetchQuote(for symbol: String, completion: @escaping (Result<StockQuote, Error>) -> Void) {
        let urlString = "https://api.polygon.io/v2/aggs/ticker/\(symbol)/prev?adjusted=true&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            // Debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON for \(symbol): \(jsonString)")
            }
            
            do {
                let response = try JSONDecoder().decode(PolygonResponse.self, from: data)
                try self?.handleAPIError(response)
                
                if let result = response.results?.first {
                    let quote = StockQuote(
                        close: result.close,
                        change: result.close - result.open,
                        percentChange: ((result.close - result.open) / result.open) * 100,
                        name: response.ticker
                    )
                    completion(.success(quote))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchStocks() async {
        let symbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "META"]
        for symbol in symbols {
            fetchQuote(for: symbol) { result in
                switch result {
                case .success(let quote):
                    print("Fetched quote for \(symbol): \(quote)")
                case .failure(let error):
                    print("Error fetching quote for \(symbol): \(error)")
                }
            }
        }
    }
    
    func fetchHistoricalData(for symbol: String, from: Date, to: Date, completion: @escaping (Result<[PolygonBar], Error>) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let fromStr = dateFormatter.string(from: from)
        let toStr = dateFormatter.string(from: to)
        
        let urlString = "https://api.polygon.io/v2/aggs/ticker/\(symbol)/range/1/day/\(fromStr)/\(toStr)?adjusted=true&sort=desc&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(PolygonResponse.self, from: data)
                if let results = response.results {
                    let bars = results.map { PolygonBar(c: $0.close, h: $0.high, l: $0.low, o: $0.open, t: $0.timestamp, v: $0.volume) } // First value in returned object
                    completion(.success(bars))
                } else {
                    completion(.failure(NSError(domain: "No results", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
