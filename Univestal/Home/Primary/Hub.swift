//
//  UVHubView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/7/24.
//

import SwiftUI

struct UVHubView: View {
    @ObservedObject var appData: AppData
    @ObservedObject var news: News
    @State var searchQuery: String = "" // Default query
    @State private var debounceTimer: Timer?
    @State private var isLoading: Bool = false
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                ColorManager.bkgColor
                    .ignoresSafeArea()

                VStack {
                    if (news.articles.isEmpty && isLoading == false) { // Show alert if no articles are found
                        Text("No articles found.")
                            .foregroundColor(.gray)
                            .font(.headline)
                    } else if isLoading {
                        ProgressView("Loading articles...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                            .foregroundColor(.gray)
                            .font(.headline)
                    } else {
                        List(news.articles) { article in
                            NavigationLink(destination: ArticleDetailView(article: article)) {
                                ArticleCard(article: article)
                            }
                        }
                    }
                }
                //Text("Displaying articles: \(news.articles.count)")  // Add this line for debugging
            }
            .onAppear {
                news.loadMockData()
                news.fetchArticles(query: "crypto")
                print(news.articles)
            }
            .searchable(text: $searchQuery, prompt: "Search")
            .onChange(of: searchQuery) {
                debounceTimer?.invalidate()
                news.showAlert = false
                isLoading = true
                debounceTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                    if !searchQuery.isEmpty {
                        news.fetchArticles(query: searchQuery.lowercased())
                    }
                    isLoading = false
                }
            }
            .navigationTitle("Top Stories")
            .alert(isPresented: .constant(news.showAlert && !searchQuery.isEmpty)) {
                Alert(
                    title: Text("No Results"),
                    message: Text(news.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#Preview {
    UVHubView(appData: AppData(), news: News())
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
                    .font(.caption)
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

