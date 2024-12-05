//
//  NewsModels.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/28/24.
//

import Foundation

struct Article: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let keywords: String?
    let snippet: String?
    let url: String
    let imageUrl: String?
    let language: String
    let publishedAt: Date
    let source: String
    let categories: [String]
    let relevanceScore: Double?
    
    enum CodingKeys: String, CodingKey {
        case id = "uuid"
        case title, description, keywords, snippet, url
        case imageUrl = "image_url"
        case language
        case publishedAt = "published_at"
        case source, categories
        case relevanceScore = "relevance_score"
    }
}

struct Meta: Codable {
    let found: Int
    let returned: Int
    let limit: Int
    let page: Int
}

struct NewsResponse: Codable {
    let meta: Meta
    let data: [Article]
}
