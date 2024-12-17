//
//  UVHubView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/7/24.
//

import SwiftUI
import Combine

struct UVHubView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @EnvironmentObject var news: News
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
                                news.loadMoreArticlesIfNeeded(currentArticle: article, query: searchText.isEmpty ? "crypto" : searchText)
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
                    news.fetchArticles(query: searchText.isEmpty ? "crypto" : searchText)
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
                            news.fetchArticles(query: searchText.isEmpty ? "crypto" : searchText)
                        }
                    }
                }
            }
            .onAppear {
                if news.articles.isEmpty {
                    news.fetchArticles(query: "crypto")
                }
            }
            .alert("Error", isPresented: $news.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(news.alertMessage)
            }
            .navigationTitle("Top Stories")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    UVHubView()
        .environmentObject(AppData())
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(News())
}

struct ArticleCard: View {
    let article: Article

    var body: some View {
        VStack {
            // Upper half: Article image
            if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .cornerRadius(16)
                }
            } else { // Fallback view if there is no image URL
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(16)
                    .overlay(
                        Text("No Image")
                            .font(.headline)
                            .foregroundColor(.gray)
                    )
            }
            
            // Lower half: Article details
            VStack(alignment: .leading, spacing: 8) {
                Text(article.source) // News source/company
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)

                Divider()

                HStack() { // Bottom: Date and author
                    Text(article.publishedAt, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                }
            }
            .padding([.top, .bottom], 8)
            .padding(.horizontal)
        } // End VStack
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}

struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(article.title)
                .font(.largeTitle)
                .bold()
            if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .cornerRadius(16)
                }
            }
            if let snippet = article.snippet {
                Text(snippet)
            } else {
                Text("No article snippet available.")
                    .font(.headline)
                    .foregroundColor(.gray)
            }

            if let url = URL(string: article.url) {
                Link("Read full article on \(article.source)", destination: url)
                    .font(.callout)
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Article")
        .navigationBarTitleDisplayMode(.inline)
    }
}

