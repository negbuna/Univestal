//
//  NewsAPI.swift
//  UV
//
//  Created by Nathan Egbuna on 8/8/24.
//

import Foundation

struct NewsArticle: Identifiable {
    let id = UUID()
    let title: String
    let source: String
    let image_url: String?
    let published_at: String
    let author: String
}

class NewsAPI {
    static let shared = NewsAPI()
    
    private init() {}
    
    func fetchArticles(completion: @escaping ([NewsArticle]) -> Void) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let currentDate = dateFormatter.string(from: Date())
        
        // Calculate the date for one week ago
        let calendar = Calendar.current
        let oneWeekAgoDate = calendar.date(byAdding: .weekOfYear, value: -1, to: Date())!
        let oneWeekAgoDateString = dateFormatter.string(from: oneWeekAgoDate)
        
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let apiKey = config["NEWS_API_KEY"] as? String,
              let url = URL(string: "https://api.thenewsapi.com/v1/news/all?api_token=\(apiKey)&search=forex+(usd|gbp)-cad&language=en&categories=business,tech&exclude_categories=travel&published_after=\(oneWeekAgoDateString)&published_before=\(currentDate)") else {
            print("Failed to load News API key from Config.plist or construct URL")
            return
        }

        print("URL: \(url)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                if let error = error {
                    print("Network error: \(error)")
                }
                return
            }

            do {
                let result = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
                print("Successfully decoded data: \(result)")
                let articles = result.data.map { article in
                    NewsArticle(
                        title: article.title,
                        source: article.source,
                        image_url: article.image_url,
                        published_at: article.published_at,
                        author: article.author ?? "Unknown"
                    )
                }
                DispatchQueue.main.async {
                    completion(articles)
                }
            } catch {
                print("Failed to decode JSON: \(error)\nRaw JSON: \(String(data: data, encoding: .utf8) ?? "No Data")")
            }
        }.resume()
    }
}

struct NewsAPIResponse: Codable {
    let meta: Meta
    let data: [Article]
    
    struct Meta: Codable {
        let found: Int
        let returned: Int
        let limit: Int
        let page: Int
    }
    
    struct Article: Codable {
        let title: String
        let source: String
        let url: String
        let image_url: String?
        let published_at: String 
        let author: String?
    }
}
