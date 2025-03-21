struct InputValidator {
    static func validateTradeAmount(_ amount: Double) -> ValidationResult {
        guard amount > 0 else {
            return .failure(.zeroValue)
        }
        guard amount <= 1_000_000 else {
            return .failure(.maximumTradeAmount(maximum: 1_000_000))
        }
        // More validations...
        return .success(())
    }
    
    static func sanitizeInput(_ input: String) -> String {
        // Remove potential injection characters
        input.components(separatedBy: CharacterSet.alphanumerics.inverted)
             .joined()
    }
}

enum ValidationResult {
    case success(())
    case failure(TradeError)
}
