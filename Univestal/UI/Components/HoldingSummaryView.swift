import SwiftUI

struct HoldingSummaryView: View {
    let asset: Tradeable
    let currentHolding: Double
    let sellingAmount: Double
    
    private var currentValue: Double {
        currentHolding * asset.currentPrice
    }
    
    private var sellingValue: Double {
        sellingAmount * asset.currentPrice
    }
    
    private var remainingAmount: Double {
        currentHolding - sellingAmount
    }
    
    private var remainingValue: Double {
        remainingAmount * asset.currentPrice
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Position Summary")
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Current Position")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(AssetFormatter.format(quantity: currentHolding)) \(asset.tradeSymbol)")
                        .bold()
                    Text(currentValue, format: .currency(code: "USD"))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("After Sale")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(AssetFormatter.format(quantity: remainingAmount)) \(asset.tradeSymbol)")
                        .bold()
                    Text(remainingValue, format: .currency(code: "USD"))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}
