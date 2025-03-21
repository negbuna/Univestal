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
                                news.loadMoreArticlesIfNeeded(currentArticle: article, query: searchText.isEmpty ? "usa finance" : searchText)
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
                .refreshable { // Might not need this
                    news.fetchArticles(query: searchText.isEmpty ? "usa finance" : searchText)
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
                            news.fetchArticles(
                                query: searchText.isEmpty ? "usa finance" : searchText,
                                isUserSearch: true
                            )
                        }
                    }
                }
            }
            .onAppear {
                if news.articles.isEmpty {
                    // Mark as system load
                    news.fetchArticles(query: "usa finance", isUserSearch: false)
                }
                news.showAlert = false
            }
            .alert("Error", isPresented: $news.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(news.alertMessage)
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
