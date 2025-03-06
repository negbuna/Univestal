//
//  Polygon.swift
//  Univestal
//
//  Created by Nathan Egbuna on 1/21/25.
//

//import SwiftUI
//
//class PolygonAPI {
//    private let apiKey = Config.polygonKey
//    @ObservedObject var shared: APIRateLimiter
//    
//    init(shared: APIRateLimiter) {
//        self.shared = shared
//    }
//    
//    // Fetch stock data for the given ticker and date range
//    func fetchStockData(
//        ticker: String,
//        from: String? = nil,
//        to: String? = nil,
//        completion: @escaping (Result<[StockData], Error>) -> Void
//    ) throws {
//        // Use default date range if none is provided
//        let dateRange = getLastWeekDateRange()
//        let fromDate = dateRange.from
//        let toDate = dateRange.to
//        
//        // Build the request URL
//        let urlString = "https://api.polygon.io/v2/aggs/ticker/\(ticker)/range/1/day/\(fromDate)/\(toDate)?adjusted=true&sort=desc&apiKey=\(apiKey)"
//        
//        guard let url = URL(string: urlString) else {
//            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
//            return
//        }
//        
//        // Create the request
//        let task = URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let data = data else {
//                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
//                return
//            }
//            
//            do {
//                // Decode the JSON response
//                let polygonResponse = try JSONDecoder().decode(PolygonResponse.self, from: data)
//                if let results = polygonResponse.results {
//                    completion(.success(results))
//                } else {
//                    completion(.failure(NSError(domain: "No results found", code: 0, userInfo: nil)))
//                }
//            } catch {
//                completion(.failure(error))
//            }
//        }
//        
//        // Start the network request
//        task.resume()
//    }
//    
//    private func handleAPIError(_ response: PolygonResponse) throws {
//        if response.status == "ERROR" {
//            if response.error?.contains("429") == true {
//                throw PaperTradingError.apiLimitExceeded
//            }
//            throw PaperTradingError.apiError(response.error ?? "Unknown error")
//        }
//    }
//}
//
//extension PolygonAPI {
//    func getLastWeekDateRange() -> (from: Date, to: Date) {
//        let today = Date()
//        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!
//        return (from: sevenDaysAgo, to: today)
//    }
//    
//    func fetchQuote(for symbol: String, completion: @escaping (Result<StockQuote, Error>) -> Void) {
//        guard shared.canMakeRequest() else {
//            return
//        }
//        
//        let urlString = "https://api.polygon.io/v2/aggs/ticker/\(symbol)/prev?adjusted=true&apiKey=\(apiKey)"
//        
//        guard let url = URL(string: urlString) else {
//            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
//            return
//        }
//        
//        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let data = data else {
//                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
//                return
//            }
//            
//            // Debugging
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Raw JSON for \(symbol): \(jsonString)")
//            }
//            
//            do {
//                let response = try JSONDecoder().decode(PolygonResponse.self, from: data)
//                try self?.handleAPIError(response)
//                
//                if let result = response.results?.first {
//                    let quote = StockQuote(
//                        close: result.c,
//                        change: result.c - result.o,
//                        percentChange: ((result.c - result.o) / result.o) * 100,
//                        name: response.ticker
//                    )
//                    completion(.success(quote))
//                }
//            } catch {
//                completion(.failure(error))
//            }
//        }.resume()
//    }
//    
//    func fetchStocks() async {
//        let symbols = ["AAPL", "GOOGL", "MSFT", "AMZN", "META"]
//        for symbol in symbols {
//            fetchQuote(for: symbol) { result in
//                switch result {
//                case .success(let quote):
//                    print("Fetched quote for \(symbol): \(quote)")
//                case .failure(let error):
//                    print("Error fetching quote for \(symbol): \(error)")
//                }
//            }
//        }
//    }
//    
//    func fetchHistoricalData(for symbol: String, from: Date, to: Date, completion: @escaping (Result<[PolygonBar], Error>) -> Void) {
//        let dateRange = getLastWeekDateRange()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//        
//        let fromStr = dateFormatter.string(from: dateRange.from)
//        let toStr = dateFormatter.string(from: dateRange.to)
//        
//        let urlString = "https://api.polygon.io/v2/aggs/ticker/\(symbol)/range/1/day/\(fromStr)/\(toStr)?adjusted=true&sort=desc&apiKey=\(apiKey)"
//        
//        guard let url = URL(string: urlString) else {
//            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
//            return
//        }
//        
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let data = data else {
//                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
//                return
//            }
//            
//            do {
//                let response = try JSONDecoder().decode(PolygonResponse.self, from: data)
//                if let results = response.results {
//                    let bars = results.map { self.mapToPolygonBar($0) } // First value in returned object
//                    completion(.success(bars))
//                } else {
//                    completion(.failure(NSError(domain: "No results", code: 0, userInfo: nil)))
//                }
//            } catch {
//                completion(.failure(error))
//            }
//        }.resume()
//    }
//    
//    func mapToPolygonBar(_ data: StockData) -> PolygonBar {
//        PolygonBar(
//            close: data.c,
//            high: data.h,
//            low: data.l,
//            open: data.o,
//            timestamp: data.t,
//            volume: data.v
//        )
//    }
//}
//
//class APIRateLimiter: ObservableObject {
//    private let limit = 5
//    private let timeWindow: TimeInterval = 60 // 60 seconds
//    private var requestTimestamps: [Date] = []
//    
//    static let shared = APIRateLimiter()
//    
//    private init() {}
//    
//    func canMakeRequest() -> Bool {
//        cleanUpOldRequests()
//        return requestTimestamps.count < limit
//    }
//    
//    func logRequest() {
//        cleanUpOldRequests()
//        requestTimestamps.append(Date())
//    }
//    
//    private func cleanUpOldRequests() {
//        let now = Date()
//        requestTimestamps = requestTimestamps.filter { now.timeIntervalSince($0) < timeWindow }
//    }
//}
