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
                                news.loadMoreArticlesIfNeeded(currentArticle: article, query: searchText.isEmpty ? "stocks crypto" : searchText)
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
                    news.fetchArticles(query: searchText.isEmpty ? "stocks crypto" : searchText)
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
                            news.fetchArticles(query: searchText.isEmpty ? "stocks crypto" : searchText)
                        }
                    }
                }
            }
            .onAppear {
                if news.articles.isEmpty {
                    news.fetchArticles(query: "stocks crypto")
                }
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
}

struct ArticleCard: View {
    let article: Article

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
                // Upper half: Article image
                if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: geometry.size.width, height: 200)
                            .cornerRadius(16)
                    }
                }
                
                // Lower half: Article details
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.source)
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text(article.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(3)
                }
                .padding(.horizontal)
            }
            .frame(width: geometry.size.width)
            .background(Color.clear)
        }
        .frame(height: 300)
    }
}

struct ArticleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let article: Article

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let imageUrl = article.imageUrl, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: 250)
                                    .clipShape(Rectangle())
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: geometry.size.width, height: 250)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text(article.title)
                                .font(.largeTitle)
                                .bold()
                            
                            if let snippet = article.snippet {
                                Text(snippet)
                                    .font(.body)
                            }
                            
                            if let url = URL(string: article.url) {
                                Link("Read full article on \(article.source)", destination: url)
                                    .font(.callout)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

