//
//  Learn.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/28/24.
//

import SwiftUI

struct LearnDetailView: View {
    let title: String
    let content: String
    
    var body: some View {
        TabView {
            VStack {
                Text(content)
                    .padding()
                    .font(.body)
            }
            .tabItem {
                Text("Page 1")
            }
            // Add more pages if needed
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    Learn()
}

struct Learn: View {
    @State var text: String = ""
    
    static private func boldText(_ text: String) -> Text {
        return Text(text).bold()
    }
    
    var topics = [
        ("What is investing?",
         "\(boldText("Investing")) is putting your money into something with the hope that it will grow over time. For example, you might invest in stocks or cryptocurrencies. Think of it as planting a tree that grows and gives you fruit later. Univestal helps by offering a trading simulator where you can practice investing with fake money to see how your decisions play out."),

        ("Why is diversification important?",
         "\(boldText("Diversification")) means not putting all your eggs in one basket. If you spread your money across different investments, like stocks, crypto, or even other assets, you reduce the risk of losing it all if one fails. With Univestal, you can learn diversification strategies through our tools, which include market data and portfolio simulations."),

        ("What are stocks?",
         "\(boldText("Stocks")) are shares of ownership in a company. When you own a stock, you're a small part-owner of that business, and you can earn money if the company does well. It's like owning a slice of the company pie. Univestal provides real-time stock price data and educational resources to help you understand the market."),

        ("What is cryptocurrency?",
         "\(boldText("Cryptocurrency")) is digital money that's secured using cryptography, which makes it safe and hard to counterfeit. Popular examples are Bitcoin and Ethereum. With Univestal, you can track coin prices, create a watchlist, and learn how to trade in a safe, simulated environment."),

        ("How do I start investing?",
         "Starting small is key! You don't need a lot of money to begin investing. Learn the basics, set goals, and practice. Univestal gives you all the tools to start, including tutorials, tips, and a trading simulator where you can invest without risking real money."),

        ("What is a trading simulator?",
         "A trading simulator is a tool that lets you practice investing without using real money. It’s like a video game for investing, where you can learn how to buy and sell stocks or crypto and see how your choices affect your portfolio. Univestal’s simulator is built to help you gain confidence before investing for real."),

        ("Why do prices go up and down?",
         "Prices change based on supply and demand, news, and the market's mood. If a lot of people want a stock or crypto, the price goes up; if they don’t, it drops. Univestal helps you stay informed with real-time price updates and tools to track trends."),

        ("What are risks in investing?",
         "Investing always comes with risks—your investments might not grow, and you could even lose money. Learning to manage risk is important. Univestal helps you understand risks through simulations and lessons, so you can make smarter decisions."),
        
        ("What types of orders can you place?",
        "There are four main types of orders:\n\n1. \(boldText("Market Orders")): Buy or sell instantly at the current price.\n2. \(boldText("Limit Orders")): Set a specific price to buy or sell.\n3. \(boldText("Stop-Limit Orders")): Automatically trade when a target price is reached.\n4. \(boldText("Bracket Orders")): Lock in profits or cut losses with a pre-set plan.\n\nUnivestal’s trading simulator will soon let you try all of these orders to learn how they work in real markets.")
    ]
    
    var filteredTopics: [(String, String)] {
        if text.isEmpty {
            return topics
        } else {
            return topics.filter { $0.0.localizedCaseInsensitiveContains(text) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredTopics, id: \.0) { topic in
                NavigationLink(destination: LearnDetailView(title: topic.0, content: topic.1)) {
                    Text(topic.0)
                        .padding()
                }
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $text, prompt: "Search")
        }
    }
}
