import SwiftUI

struct UVSearch: View {
    @StateObject private var viewModel = StockViewModel()
    
    var body: some View {
        NavigationStack {
            List(viewModel.stocks, id: \.ticker) { stock in
                VStack(alignment: .leading) {
                    Text(stock.ticker)
                        .font(.headline)
                    Text(stock.publisher)
                        .font(.subheadline)
                    Text("Country: \(stock.country)")
                        .font(.caption)
                    Text("Currency: \(stock.currency)")
                        .font(.caption)
                }
            }
            .navigationTitle("Search")
            .onAppear {
                viewModel.fetchStocks()
            }
        }
        .alert(item: $viewModel.errorMessage) { errorMessage in
            Alert(title: Text("Error"), message: Text(errorMessage.message), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    UVSearch()
}
