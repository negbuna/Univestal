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
    @Published var isLoading = false
    @Published var currentPage = 1
    @Published var totalArticlesFound = 0
    
    let baseUrl = "https://api.thenewsapi.com/v1/news/all"
    let apiKey = Config.newsKey
    let articlesPerPage = 3 // Match the API's default limit

    private func handleError(_ error: Error) -> String {
        let errorMessage = error.localizedDescription.lowercased()
        
        // Check if error message contains keywords indicating API limit
        if errorMessage.contains("code=429") || 
           errorMessage.contains("too many requests") || 
           errorMessage.contains("rate limit exceeded") {
            return "The app's daily API limit has reached. Articles will refresh tomorrow. We apologize for the inconvenience."
        }
        
        return "Error: \(error.localizedDescription)"
    }

    func fetchArticles(query: String, page: Int = 1) {
        // Prevent multiple simultaneous requests
        guard !isLoading else { return }
        
        isLoading = true
        
        let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        guard let url = URL(string: "\(baseUrl)?api_token=\(apiKey)&search=\(queryEncoded)&categories=business,general&published_after=\(oneWeekBack())&language=en&page=\(page)&limit=\(articlesPerPage)") else {
            print("Invalid URL")
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            defer {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
            
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

            do {
                let decoder = JSONDecoder()
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                decoder.dateDecodingStrategy = .custom { decoder -> Date in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
                }
                
                let decodedResponse = try decoder.decode(NewsResponse.self, from: data)
                
                DispatchQueue.main.async {
                    // If it's the first page, replace articles
                    // If it's a subsequent page, append articles
                    if page == 1 {
                        self.articles = decodedResponse.data
                    } else {
                        self.articles.append(contentsOf: decodedResponse.data)
                    }
                    
                    self.totalArticlesFound = decodedResponse.meta.found
                    self.currentPage = page
                    
                    if decodedResponse.data.isEmpty {
                        self.showAlert = true
                        self.alertMessage = "No more articles found."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = self.handleError(error)
                }
            }
        }.resume()
    }
    
    func loadMoreArticlesIfNeeded(currentArticle article: Article, query: String) {
        // Check if the current article is the last one and there are more articles to load
        guard articles.count < totalArticlesFound else {
            return
        }
        
        // Load next page
        fetchArticles(query: query, page: currentPage + 1)
    }
    
    private func oneWeekBack() -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
