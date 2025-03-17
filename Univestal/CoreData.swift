//
//  CoreData.swift
//  Univestal
//
//  Created by Nathan Egbuna on 12/9/24.
//

import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Entities") // Name of .xcdatamodeld file
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("CoreData store loaded successfully at: \(storeDescription.url?.absoluteString ?? "unknown location")")
            
            // Print the store type
            print("Store type: \(storeDescription.type)")
            
            // Print entity descriptions
            let entities = container.managedObjectModel.entities
            print("Loaded entities: \(entities.map { $0.name ?? "unnamed" })")
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    // Add verification method
    func verifyStoreConfiguration() {
        let context = persistentContainer.viewContext
        let entities = ["StockWatchlistItem", "WatchlistItem", "CDPortfolio", "CDTrade", "StockTrade"]
        
        for entityName in entities {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
            fetchRequest.fetchLimit = 1
            
            do {
                _ = try context.fetch(fetchRequest)
                print("✅ Successfully verified entity: \(entityName)")
            } catch {
                print("❌ Error verifying entity \(entityName): \(error)")
            }
        }
    }
}
