import SwiftUI

struct UVSearch2: View {
    @StateObject private var viewModel = CoinViewModel()
    @EnvironmentObject var watchlist: Watchlist
    
    var body: some View {
        NavigationStack {
            List(viewModel.filteredCoins, id: \.id) { coin in
                NavigationLink(destination: DetailedCoinView(coin: coin)) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(coin.name)
                                .font(.headline)
                            if watchlist.isInWatchlist(coin) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                }
                            }
                        
                        Text("Symbol: \(coin.symbol.uppercased())")
                            .font(.subheadline)
                        Text("Current Price: $\(coin.current_price, specifier: "%.2f")")
                            .font(.caption)
                        Text("24h Change: \(coin.price_change_percentage_24h, specifier: "%.2f")%")
                            .font(.caption)
                            .foregroundColor(coin.price_change_percentage_24h >= 0 ? .green : .red)
                    }
                }
            }
            .navigationTitle("Coins")
            .searchable(text: $viewModel.searchText)
            .onAppear {
                viewModel.fetchCoins()
            }
        }
        .alert(item: $viewModel.errorMessage) { errorMessage in
            Alert(title: Text("Error"), message: Text(errorMessage.message), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    UVSearch2()
        .environmentObject(Watchlist())
}

struct SparklineView: View {
    let prices: [Double]

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard prices.count > 1 else { return }
                let maxY = prices.max() ?? 1
                let minY = prices.min() ?? 0
                let rangeY = maxY - minY
                let stepX = geometry.size.width / CGFloat(prices.count - 1)
                let stepY = geometry.size.height / CGFloat(rangeY)

                path.move(to: CGPoint(x: 0, y: (prices[0] - minY) * stepY))

                for index in prices.indices {
                    let x = CGFloat(index) * stepX
                    let y = (prices[index] - minY) * stepY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.blue, lineWidth: 2)
        }
    }
}
