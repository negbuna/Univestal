import SwiftUI

struct HoldingsView: View {
    @EnvironmentObject var environment: TradingEnvironment
    @State private var selectedFilter: AssetType?
    
    var filteredHoldings: [AssetHolding] {
        guard let filter = selectedFilter else {
            return environment.holdings
        }
        return environment.holdings.filter { $0.type == filter }
    }
    
    var body: some View {
        VStack {
            Picker("Filter", selection: $selectedFilter) {
                Text("All").tag(Optional<AssetType>.none)
                Text("Crypto").tag(Optional<AssetType>.some(.crypto))
                Text("Stocks").tag(Optional<AssetType>.some(.stock))
            }
            .pickerStyle(.segmented)
            .padding()
            
            List {
                ForEach(filteredHoldings) { holding in
                    HoldingRow(holding: holding)
                }
            }
        }
    }
}

struct HoldingRow: View {
    let holding: AssetHolding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(holding.symbol.uppercased())
                    .font(.headline)
                Spacer()
                Text(holding.totalValue.formatted(.currency(code: "USD")))
                    .font(.headline)
            }
            
            HStack {
                Text("\(holding.quantity, specifier: "%.4f") units")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(holding.profitLoss >= 0 ? "+" : "-")
                    .font(.subheadline)
                    .foregroundColor(holding.profitLoss >= 0 ? .green : .red) +
                Text(abs(holding.profitLoss).formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .foregroundColor(holding.profitLoss >= 0 ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}
