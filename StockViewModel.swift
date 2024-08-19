import Foundation
import Combine

struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}

class StockViewModel: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var errorMessage: IdentifiableError? = nil
    
    func fetchStocks() {
        let page = 1
        let pageSize = 100
        
        UV.fetchStocks(page: page, pageSize: pageSize) { [weak self] (stocks, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = IdentifiableError(message: "Error: \(error.localizedDescription)")
                    print("Error fetching stocks: \(error.localizedDescription)")

                } else if let stocks = stocks {
                    self?.stocks = stocks
                    print("Stocks fetched: \(stocks)")

                }
            }
        }
    }
}

