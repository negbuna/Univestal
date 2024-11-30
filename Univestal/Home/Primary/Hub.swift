//
//  UVHubView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/7/24.
//

import SwiftUI

import SwiftUI

struct UVHubView: View {
    @ObservedObject var appData: AppData
    @ObservedObject var news: News
    @State var searchQuery: String = "".lowercased() // Default query
    @State private var debounceTimer: Timer?
    @State private var showAlert: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    ColorManager.bkgColor
                        .ignoresSafeArea()

                    VStack {
                        if news.articles.isEmpty {
                            // Show alert if no articles are found
                            Text("No articles found.")
                                .foregroundColor(.gray)
                                .font(.headline)
                                .padding()
                        } else {
                            // Display articles in a list
                            List(news.articles) { article in
                                NavigationLink(destination: ArticleDetailView(article: article)) {
                                    ArticleCard(article: article)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .onAppear {
                news.fetchArticles(query: "cryptocurrency") // Default query
            }
            .searchable(text: $searchQuery, prompt: "Search")
            .onChange(of: searchQuery) { // To prevent rapid successive calls
                debounceTimer?.invalidate()
                debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    news.fetchArticles(query: searchQuery)
                    if news.articles.isEmpty {
                        showAlert = true
                    }
                }
            }
            .navigationTitle("Top Stories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: UVSettingsView(appData: appData)) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("No Results"), message: Text("No articles were found matching your search."), dismissButton: .default(Text("OK")))
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
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .cornerRadius(16)
                }
            } else {
                // Fallback view if there is no image URL
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
                // News source/company
                Text(article.source)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Title
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)

                Divider()

                // Bottom: Date and author
                HStack {
                    if let publishedAt = article.publishedAt {
                        Text(publishedAt, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Unknown Date")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
//                    Spacer() // Authors aren't included in the API
//                    Text(article.author ?? "Unknown")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
                }
            }
            .padding([.top, .bottom], 8)
            .padding(.horizontal)

        } // end VStack
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(article.title)
                .font(.largeTitle)
                .bold()

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

