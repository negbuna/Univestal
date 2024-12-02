//
//  News.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/28/24.
//

import Foundation
import Combine
import SwiftUI

class News: ObservableObject {
    @Published var articles: [Article] = []
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    let baseUrl = "https://api.thenewsapi.com/v1/news/all"
    let apiKey = Config.newsKey

    func fetchArticles(query: String) {
        let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? {
            print("Warning: Query string could not be encoded properly.")
            return ""
        }()
        guard let url = URL(string: "\(baseUrl)?api_token=\(apiKey)&search=\(queryEncoded)&categories=business,tech&published_after=\(oneWeekBack())&language=en") else {
            print("Invalid URL")
            return
        }

        print("Generated URL: \(url)") // Verifying URL is formatted correctly

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Network error: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "No data received from the server."
                }
                return
            }

            print(String(data: data, encoding: .utf8) ?? "Invalid JSON")

//            do {
//                let decoder = JSONDecoder()
//                decoder.dateDecodingStrategy = .iso8601
//                let decodedResponse = try decoder.decode(NewsResponse.self, from: data)
//
//                DispatchQueue.main.async {
//                    self.articles = decodedResponse.data
//                    print("Fetched articles: \(self.articles)")  // Add this line for debugging
//                    if decodedResponse.meta.found == 0 {
//                        self.showAlert = true
//                        self.alertMessage = "No articles found."
//                    }
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    self.showAlert = true
//                    self.alertMessage = "Decoding error: \(error.localizedDescription)"
//                    return
//                }
//            }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decodedResponse = try decoder.decode(NewsResponse.self, from: data)

                DispatchQueue.main.async {
                    self.articles = []  // Clear previous articles
                    for articleData in decodedResponse.data {
                        let article = Article(
                            id: articleData.id,
                            title: articleData.title,
                            description: articleData.description,
                            keywords: articleData.keywords,
                            snippet: articleData.snippet,
                            url: articleData.url,
                            image_url: articleData.image_url,
                            language: articleData.language,
                            published_at: articleData.published_at,
                            source: articleData.source,
                            categories: articleData.categories,
                            relevance_score: articleData.relevance_score
                        )
                        self.articles.append(article)
                    }
                    if decodedResponse.meta.found == 0 {
                        self.showAlert = true
                        self.alertMessage = "No articles found."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Decoding error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    private func oneWeekBack() -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func loadMockData() {
        self.articles = [
            Article(
                id: "1",
                title: "Trump's Election Brings Crypto Bros to Power",
                description: "This is a mock description for article 1.",
                keywords: "mock, test, example",
                snippet: "New crypto friendly legislators are in town to bring new legislation with hands-free government.",
                url: "https://example.com",
                image_url: "https://african.business/wp-content/uploads/2024/11/000_36m4738-1024x683.jpg",
                language: "en",
                published_at: Date(),
                source: "NBC Finance",
                categories: ["Finance"],
                relevance_score: 20.03
            ),
            Article(
                id: "2",
                title: "Bitcoin Raises $99K HKD at Close",
                description: "This is a mock description for article 2.",
                keywords: "mock, test, example",
                snippet: "Mock snippet for article 2.",
                url: "https://example.com",
                image_url: "https://www.google.com/url?sa=i&url=https%3A%2F%2Fninjapromo.io%2Fbest-crypto-news-websites&psig=AOvVaw3RyPjgFRHiNPp5KAdkc61D&ust=1733188409004000&source=images&cd=vfe&opi=89978449&ved=0CBMQjRxqFwoTCKCF16T0h4oDFQAAAAAdAAAAABAJ",
                language: "en",
                published_at: Date(),
                source: "HK Times",
                categories: ["Finance"],
                relevance_score: 19.2234
            ),
            Article(
                id: "3",
                title: "Ethereum and Litecoin among new approved coins in El Salvador",
                description: "This is a mock description for article 3.",
                keywords: "mock, test, example",
                snippet: "Mock snippet for article 2.",
                url: "https://example.com",
                image_url: "https://www.google.com/url?sa=i&url=https%3A%2F%2Fninjapromo.io%2Fbest-crypto-news-websites&psig=AOvVaw3RyPjgFRHiNPp5KAdkc61D&ust=1733188409004000&source=images&cd=vfe&opi=89978449&ved=0CBMQjRxqFwoTCKCF16T0h4oDFQAAAAAdAAAAABAJ",
                language: "en",
                published_at: Date(),
                source: "Mock Source",
                categories: ["Finance"],
                relevance_score: 17.492
            )
        ]
    }
}
