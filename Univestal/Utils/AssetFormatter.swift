import Foundation

enum AssetFormatter {
    static func format(quantity: Double) -> String {
        let number = NSNumber(value: abs(quantity))
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0  // Don't force trailing zeros
        
        // Set maximum fraction digits based on value
        if quantity < 0.01 {
            formatter.maximumFractionDigits = 8
        } else if quantity < 1.0 {
            formatter.maximumFractionDigits = 4
        } else {
            formatter.maximumFractionDigits = 2
        }
        
        // Handle sign
        let sign = quantity < 0 ? "-" : ""
        guard let formatted = formatter.string(from: number) else {
            return String(format: "%.2f", quantity) // Fallback
        }
        
        return sign + formatted
    }
}
