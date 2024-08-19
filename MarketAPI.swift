import Foundation

// Define the Market struct
struct Market: Decodable {
    let country: String
    let mic: String
    let name: String
}

func fetchMarkets(completion: @escaping ([Market]?, Error?) -> Void) {
    guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
          let config = NSDictionary(contentsOfFile: path),
          let apiKey = config["API_KEY"] as? String else {
        print("Failed to load API key from Config.plist")
        completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load API key"]))
        return
    }
    
    let headers = ["Authorization": "apikey \(apiKey)"]
    
    let url = URL(string: "https://api.finazon.io/latest/datasets?page_size=1000")!
    var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers
    
    let session = URLSession.shared
    
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
        
        do {
            // json > markets
            let marketResponse = try JSONDecoder().decode([String: [Market]].self, from: data)
            if let markets = marketResponse["data"] {
                completion(markets, nil)
            } else {
                completion(nil, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid data format"]))
            }
        } catch {
            print("Failed to parse JSON: \(error)")
            completion(nil, error)
        }
    }
    
    dataTask.resume()
}
