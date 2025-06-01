//
//  UVHubView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/7/24.
//

import Combine
import SwiftUI

struct UVHubView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @EnvironmentObject var news: News
    @EnvironmentObject var finnhub: Finnhub
    @State private var searchText = ""
    @State private var searchDebounceTask: Task<Void, Never>?
    @State private var showRateLimitAlert = false
    @State private var rateLimitMessage = ""
    
    private func handleSearch(query: String) {
        Task {
            do {
                let canSearch = try await news.searchArticles(query: query)
                if !canSearch {
                    showRateLimitAlert = true
                }
            } catch News.NewsError.rateLimitExceeded(let minutesLeft) {
                rateLimitMessage = "Due to API constraints, please try searching again in \(minutesLeft) minute\(minutesLeft == 1 ? "" : "s")."
                showRateLimitAlert = true
            } catch {
                print("Search error: \(error)")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorManager.bkgColor
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack {
                        ForEach(news.articles.indices, id: \.self) { index in
                            let article = news.articles[index]
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                ArticleCard(article: article)
                            }
                            .onAppear {
                                news.loadMoreArticlesIfNeeded(currentArticle: article, query: searchText.isEmpty ? "us markets" : searchText)
                            }
                        }
                        
                        if news.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                        }
                    }
                    .padding()
                }
                .refreshable {
                    news.fetchArticles(query: searchText.isEmpty ? "us markets" : searchText)
                }
            }
            .searchable(text: $searchText, prompt: "Search")
            .onChange(of: searchText) {
                // Cancel any existing debounce task
                searchDebounceTask?.cancel()
                
                // Create new debounce task
                searchDebounceTask = Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
                    if !Task.isCancelled {
                        await MainActor.run {
                            news.articles = [] // Clear current articles
                            news.currentPage = 1 // Reset pagination
                            // Mark as user search
                            handleSearch(query: searchText.isEmpty ? "us markets" : searchText)
                        }
                    }
                }
            }
            .onAppear {
                if news.articles.isEmpty {
                    // Mark as system load
                    news.fetchArticles(query: "us markets", isUserSearch: false)
                }
                news.showAlert = false
            }
            .alert("Error", isPresented: $news.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(news.alertMessage)
            }
            .alert("Search Limit", isPresented: $showRateLimitAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(rateLimitMessage)
            }
            .navigationTitle("Top Stories")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    UVHubView()
        .environmentObject(AppData())
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(News())
        .environmentObject(Finnhub())
}
