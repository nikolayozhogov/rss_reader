//
//  ViewController.swift
//  RSSReader
//
//  Created by nikolay on 17.04.2020.
//  Copyright © 2020 nikolay. All rights reserved.
//

import UIKit
import CoreData

class CoreDataManager {
    
    //MAKR: Get Context
    
    public static func getContext() -> NSManagedObjectContext {
        //guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    public static func read_sort(entityName: String, sortKey: String, ascending: Bool) -> [NSManagedObject] {
        
        var objects: [NSManagedObject] = []
        
        let managedContext = self.getContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
           
        let sort = NSSortDescriptor(key: sortKey, ascending: ascending)
        fetchRequest.sortDescriptors = [sort]
        
        do {
            objects = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return objects
    }
    
}
