//
//  NewsModels.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/28/24.
//

import Foundation

struct NewsResponse: Codable {
    let meta: Meta
    let data: [Article]
}

struct Meta: Codable {
    let found: Int
    let returned: Int
    let limit: Int
    let page: Int
}

struct Article: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let keywords: String?
    let snippet: String
    let url: String
    let image_url: String?
    let language: String
    let published_at: Date
    let source: String
    let categories: [String]
    let relevance_score: Double?
    
    enum CodingKeys: String, CodingKey {
        case id = "uuid" // Map "uuid" to "id"
        case title
        case description
        case keywords
        case snippet
        case url
        case image_url
        case language
        case published_at
        case source
        case categories
        case relevance_score
    }
}
