import SwiftUI

struct DetailedCoinView: View {
    let coin: Coin
    @EnvironmentObject var watchlist: Watchlist

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Symbol: \(coin.symbol.uppercased())")
                .font(.title2)
                .bold()
            Text("Current Price: $\(coin.current_price, specifier: "%.2f")")
                .font(.title3)
            Text("Market Cap: $\(coin.market_cap, specifier: "%.2f")")
                .font(.title3)
            Text("24h Change: \(coin.price_change_percentage_24h, specifier: "%.2f")%")
                .font(.title3)
                .foregroundColor(coin.price_change_percentage_24h >= 0 ? .green : .red)
            if let sparkline = coin.sparkline_in_7d {
                Text("Price Sparkline (7d):")
                    .font(.title3)
                
                Divider()
                    .background(Color.primary.opacity(1.0))
                
                SparklineView(prices: sparkline.price)
                    .frame(height: 200)
                    .padding(.vertical, 8)
                
                Divider()
                    .background(Color.primary.opacity(1.0))
            }
            
            HStack {
                Spacer()
                
                
                if !watchlist.isInWatchlist(coin) {
                    Button("Add to Watchlist") {
                        watchlist.addCoin(coin)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 170, height: 55)
                    .background(Color.blue)
                    .cornerRadius(20)
                    .padding()
                } else {
                    Button("Remove from Watchlist") {
                        watchlist.removeCoin(coin)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 220, height: 55)
                    .background(Color.blue)
                    .cornerRadius(20)
                    .padding()
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle(coin.name)
    }
}
