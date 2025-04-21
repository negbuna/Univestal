    func cacheStocks(_ stocks: [Stock]) async throws {
        print("💾 Caching \(stocks.count) stocks...")
        let context = persistentContainer.newBackgroundContext()
        
        await context.perform {
            for stock in stocks {
                let cachedStock = CachedStock(context: context)
                cachedStock.symbol = stock.symbol
                cachedStock.data = try? JSONEncoder().encode(stock)
                cachedStock.timestamp = Date()
            }
            
            do {
                try context.save()
                print("✅ Successfully cached \(stocks.count) stocks")
            } catch {
                print("❌ Error caching stocks: \(error)")
            }
        }
    }
    
    func getCachedStocks() async throws -> [Stock] {
        print("🔍 Fetching cached stocks...")
        let context = persistentContainer.newBackgroundContext()
        
        return try await context.perform {
            let request: NSFetchRequest<CachedStock> = CachedStock.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedStock.timestamp, ascending: false)]
            
            let cachedStocks = try context.fetch(request)
            print("📦 Found \(cachedStocks.count) cached stocks")
            
            let stocks = cachedStocks.compactMap { cached -> Stock? in
                guard let data = cached.data else { return nil }
                return try? JSONDecoder().decode(Stock.self, from: data)
            }
            
            print("✅ Successfully decoded \(stocks.count) stocks from cache")
            return stocks
        }
    }