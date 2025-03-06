//
//  Learn.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/28/24.
//

import SwiftUI

struct LearnDetailView: View {
    let topic: Topic
    
    private func formatText(_ input: String) -> Text {
        var result = Text("")
        let parts = input.split(separator: "*")
        
        for (index, part) in parts.enumerated() {
            if index % 2 == 1 {
                // Bold text between **
                result = result + Text(String(part)).bold()
            } else {
                // Regular text
                result = result + Text(String(part))
            }
        }
        return result
    }
    
    var body: some View {
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                Spacer()
                Text(topic.description)
                    .padding()
                    .font(.body)
            Spacer()
        }
        .navigationTitle(topic.question)
        .navigationBarTitleDisplayMode(.inline)
        .globeOverlay()
    }
}

#Preview {
    Learn()
}

struct Learn: View {
    @State var text: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var filteredTopics: [Topic] {
        if text.isEmpty {
            return Topics.allTopics
        } else {
            return Topics.allTopics.filter { $0.question.localizedCaseInsensitiveContains(text) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredTopics) { topic in
                NavigationLink(destination: LearnDetailView(topic: topic)) {
                    Text(topic.question)
                        .padding()
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .searchable(text: $text, prompt: "Search")
        }
    }
}

extension Learn {
    static let investing = Topic(
        question: "What is investing?",
        description: "Investing is putting your money into something with the hope that it will grow over time. For example, you might invest in stocks or cryptocurrencies. Think of it as planting a tree that grows and gives you fruit later. Univestal helps by offering a trading simulator where you can practice investing with fake money to see how your decisions play out."
    )
    
    static let diversification = Topic(
        question: "Why is diversification important?",
        description: "Diversification means not putting all your eggs in one basket. If you spread your money across different investments, like stocks, crypto, or even other assets, you reduce the risk of losing it all if one fails. With Univestal, you can learn diversification strategies through our tools, which include market data and portfolio simulations."
    )
    
    static let stocks = Topic(
        question: "What are stocks?",
        description: "Stocks are shares of ownership in a company. When you own a stock, you're a small part-owner of that business, and you can earn money if the company does well. It's like owning a slice of the company pie. Univestal provides real-time stock price data and educational resources to help you understand the market."
    )
    
    static let cryptocurrency = Topic(
        question: "What is cryptocurrency?",
        description: "Cryptocurrency is digital money that's secured using cryptography, which makes it safe and hard to counterfeit. Popular examples are Bitcoin and Ethereum. With Univestal, you can track coin prices, create a watchlist, and learn how to trade in a safe, simulated environment."
    )
    
    static let gettingStarted = Topic(
        question: "How do I start investing?",
        description: "Starting small is key! You don't need a lot of money to begin investing. Learn the basics, set goals, and practice. Univestal gives you all the tools to start, including tutorials, tips, and a trading simulator where you can invest without risking real money."
    )
    
    static let simulator = Topic(
        question: "What is a trading simulator?",
        description: "A trading simulator is a tool that lets you practice investing without using real money. It's like a video game for investing, where you can learn how to buy and sell stocks or crypto and see how your choices affect your portfolio. Univestal's simulator is built to help you gain confidence before investing for real."
    )
    
    static let pricing = Topic(
        question: "Why do prices go up and down?",
        description: "Prices change based on supply and demand, news, and the market's mood. If a lot of people want a stock or crypto, the price goes up; if they don't, it drops. Univestal helps you stay informed with real-time price updates and tools to track trends."
    )
    
    static let risks = Topic(
        question: "What are risks in investing?",
        description: "Investing always comes with risks—your investments might not grow, and you could even lose money. Learning to manage risk is important. Univestal helps you understand risks through simulations and lessons, so you can make smarter decisions."
    )
    
    static let orders = Topic(
        question: "What types of orders can you place?",
        description: "There are four main types of orders:\n\n1. **Market Orders**: Buy or sell instantly at the current price.\n2. **Limit Orders**: Set a specific price to buy or sell.\n3. **Stop-Limit Orders**: Automatically trade when a target price is reached.\n4. **Bracket Orders**: Lock in profits or cut losses with a pre-set plan.\n\nUnivestal's trading simulator will soon let you try all of these orders to learn how they work in real markets."
    )
}

