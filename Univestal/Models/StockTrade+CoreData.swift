import CoreData

extension StockTrade {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StockTrade> {
        return NSFetchRequest<StockTrade>(entityName: "StockTrade")
    }
    
    public class func newTrade(in context: NSManagedObjectContext) -> StockTrade {
        let trade = StockTrade(context: context)
        trade.id = UUID()
        trade.purchaseDate = Date()
        return trade
    }
}