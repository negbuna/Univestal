//
//  News.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/28/24.
//

import Foundation
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

    private var lastSearchTime: Date?
    private let cooldownInterval: TimeInterval = 600 // 10 minutes
    private var isUserInitiatedSearch = false

    private func handleError(_ error: Error) {
    DispatchQueue.main.async {
        self.showAlert = true
        
        // API Limit Error
        if let urlError = error as? URLError, 
           urlError.errorCode == 429 {
            self.alertMessage = "Daily article limit reached. Please try again tomorrow."
            return
        }
        
        // Network Error
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                self.alertMessage = "No internet connection. Please check your connection and try again."
            case .timedOut:
                self.alertMessage = "Request timed out. Please try again."
            default:
                self.alertMessage = "Network error. Please try again later."
            }
            return
        }
        
        // Decoding Error
        if error is DecodingError {
            self.alertMessage = "Unable to load articles. Please try again later."
            return
        }
        
        // Generic Error
        self.alertMessage = "Something went wrong. Please try again later."
    }
}

    func fetchArticles(query: String, page: Int = 1, isUserSearch: Bool = false, completion: @escaping ([Article]) -> Void = { _ in }) {
        // Update flag
        isUserInitiatedSearch = isUserSearch
        
        let _ = query.isEmpty && page == 1 && !isUserInitiatedSearch // isInitialLoad, Might use this later
        
        // Only show alerts for user-initiated searches
        if isUserInitiatedSearch {
            if let lastSearch = lastSearchTime {
                let timeSinceLastSearch = Date().timeIntervalSince(lastSearch)
                if timeSinceLastSearch < cooldownInterval {
                    let remainingTime = Int(cooldownInterval - timeSinceLastSearch)
                    self.showAlert = true 
                    self.alertMessage = "Due to API constraints, please wait \(remainingTime) seconds before searching again."
                    return
                }
            }
            lastSearchTime = Date()
        }
        
        // Reset alert state for non-user searches
        if !isUserInitiatedSearch {
            showAlert = false
            alertMessage = ""
        }
        
        performFetch(query: query, page: page, showAlerts: isUserInitiatedSearch, completion: completion)
    }

    private func performFetch(query: String, page: Int, showAlerts: Bool, completion: @escaping ([Article]) -> Void) {
        guard !isLoading else { return }
        
        isLoading = true
        if showAlerts {
            lastSearchTime = Date()
        }
        
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
                    self.handleError(error)
                    completion([])
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "No data received from the server."
                    completion([])
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
                        completion(decodedResponse.data)
                    } else {
                        self.articles.append(contentsOf: decodedResponse.data)
                        completion(self.articles)
                    }
                    
                    self.totalArticlesFound = decodedResponse.meta.found
                    self.currentPage = page
                    
                    if decodedResponse.data.isEmpty {
                        self.showAlert = true
                        self.alertMessage = "No articles found for this search."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.handleError(error)
                    completion([])
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
    
    @MainActor
    func searchArticles(query: String) async throws -> Bool {  // Remove userId parameter
        // Check global rate limit
        guard await NewsRequestManager.shared.canMakeRequest() else {  // Remove for parameter
            if let timeLeft = await NewsRequestManager.shared.timeUntilNextSearch() {
                let minutes = Int(ceil(timeLeft / 60))
                throw NewsError.rateLimitExceeded(minutesLeft: minutes)
            }
            throw NewsError.rateLimitExceeded(minutesLeft: 60)
        }
        
        // Make API request
        // ...existing code...
        
        await NewsRequestManager.shared.trackRequest()  // Remove for parameter
        return true
    }
    
    enum NewsError: LocalizedError {
        case rateLimitExceeded(minutesLeft: Int)
        
        var errorDescription: String? {
            switch self {
            case .rateLimitExceeded(let minutes):
                return "Due to API constraints, please try searching again in \(minutes) minute\(minutes == 1 ? "" : "s"). This helps us maintain service for all users."
            }
        }
    }
}
