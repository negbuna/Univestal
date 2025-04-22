import Foundation

struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let page: Int
    let totalPages: Int
    let hasNextPage: Bool
    
    // For APIs that return different pagination metadata
    init(items: [T], page: Int, totalPages: Int? = nil, totalItems: Int? = nil, itemsPerPage: Int = 25) {
        self.items = items
        self.page = page
        
        if let total = totalPages {
            self.totalPages = total
        } else if let totalItems = totalItems {
            self.totalPages = Int(ceil(Double(totalItems) / Double(itemsPerPage)))
        } else {
            self.totalPages = items.isEmpty ? page : page + 1
        }
        
        self.hasNextPage = page < self.totalPages
    }
}
