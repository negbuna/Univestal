//
// ArticleModels.swift
//  Univestal
//
//  Created by Nathan Egbuna on 2/13/25.
//

import SwiftUI

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

