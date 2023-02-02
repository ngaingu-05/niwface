//
//  CoreData.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 28.08.22.
//

import Foundation
import CoreData

class CoreData: NSObject {
    // Singletons
    static let stack = CoreData()
    
    // MARK: - Core Data stack
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Nerveous")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    public var context: NSManagedObjectContext {
            return self.persistentContainer.viewContext
    }
    
    // MARK: - Core Data Saving support
    
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
    
    // MARK: Retrieve data
    func getRecordingsFromStorage(predicate: NSPredicate?, completion: @escaping ([DataRecording]) -> Void) {
        var results : [DataRecording] = []
        let request = NSFetchRequest<DataRecording>(entityName: "DataRecording")
        if let predicate = predicate {
            request.predicate = predicate
        }
        
        let context = persistentContainer.viewContext
        
        context.perform {
            do {
                results = try context.fetch(request)
            } catch _ {
                print("Error fetching results")
            }
            
            completion(results)
        }
    }
}
