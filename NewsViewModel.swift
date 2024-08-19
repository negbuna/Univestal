//
//  NewsViewModel.swift
//  UV
//
//  Created by Nathan Egbuna on 8/9/24.
//

import SwiftUI

struct NewsArticleView: View {
    let article: NewsArticle

    var body: some View {
        HStack {
            if let image_url = article.image_url, let url = URL(string: image_url) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit) 
                        .frame(width: 100, height: 100) 
                        .cornerRadius(10)
                        .clipped()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary)
                        .frame(width: 100, height: 100)
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(article.source)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2) 
                    .foregroundColor(.primary)
                
                Text("\(article.author) · \(article.published_at)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 5)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 10)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .padding()
        )
        
        .padding(.horizontal)
    }
}
