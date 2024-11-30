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
        guard let url = URL(string: "\(baseUrl)?api_token=\(apiKey)&search=\(query)&published_after=\(oneWeekBack())&language=en") else {
            print("Invalid URL")
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            // Handle networking error
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
                // Decode with custom date handling
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
                decoder.dateDecodingStrategy = .formatted(formatter)
                
                let decodedResponse = try decoder.decode(NewsResponse.self, from: data)

                DispatchQueue.main.async {
                    if decodedResponse.data.isEmpty {
                        self.showAlert = true
                        self.alertMessage = "No articles were found for your query."
                    } else {
                        self.articles = decodedResponse.data
                    }
                }
            } catch let DecodingError.dataCorrupted(context) {
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Data corrupted: \(context.debugDescription)"
                }
            } catch let DecodingError.keyNotFound(key, context) {
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Key '\(key.stringValue)' not found: \(context.debugDescription)"
                }
            } catch let DecodingError.typeMismatch(type, context) {
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Type mismatch for \(type): \(context.debugDescription)"
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Unexpected error: \(error.localizedDescription)"
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
}
