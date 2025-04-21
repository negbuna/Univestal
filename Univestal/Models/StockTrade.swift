import CoreData

@objc(StockTrade)
public class StockTrade: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var symbol: String?
    @NSManaged public var name: String?
    @NSManaged public var quantity: Double
    @NSManaged public var purchasePrice: Double
    @NSManaged public var currentPrice: Double
    @NSManaged public var purchaseDate: Date?
    @NSManaged public var portfolio: CDPortfolio?
}

extension StockTrade {
    static var fetchRequest: NSFetchRequest<StockTrade> {
        NSFetchRequest<StockTrade>(entityName: "StockTrade")
    }
}