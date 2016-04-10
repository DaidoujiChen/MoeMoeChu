//
//  CoreData.swift
//  MoeMoeDer
//
//  Created by DaidoujiChen on 2016/1/7.
//  Copyright © 2016年 DaidoujiChen. All rights reserved.
//

import Foundation
import CoreData

// MARK: Private Class Methods
extension CoreData {
    
    // 是否還在舊路徑
    private class func isDBInOldPath() -> Bool {
        return DaiFileManager.isExistIn(DaiFileManager.document["/MoeMoeDer.sqlite"].path)
    }
    
    // 把 db 搬到新路徑
    private class func moveDBToNewPath() {
        let sqlite = DaiFileManager.document["/MoeMoeDer.sqlite"]
        if DaiFileManager.isExistIn(sqlite.path) {
            sqlite.move(DaiFileManager.applicationSupport["/MoeMoeDer/MoeMoeDer.sqlite"])
        }
        
        let sqlite_shm = DaiFileManager.document["/MoeMoeDer.sqlite-shm"]
        if DaiFileManager.isExistIn(sqlite_shm.path) {
            sqlite_shm.move(DaiFileManager.applicationSupport["/MoeMoeDer/MoeMoeDer.sqlite-shm"])
        }
        
        let sqlite_wal = DaiFileManager.document["/MoeMoeDer.sqlite-wal"]
        if DaiFileManager.isExistIn(sqlite_wal.path) {
            sqlite_wal.move(DaiFileManager.applicationSupport["/MoeMoeDer/MoeMoeDer.sqlite-wal"])
        }
    }
    
}

// MARK: Private Properties
extension CoreData {

    // Library/Application Support 資料夾, 據說 db 放這邊才不會被囉唆
    private static let applicationSupportDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        print(urls)
        return urls[urls.count - 1]
    }()
    
    private static let managedObjectModel: NSManagedObjectModel? = {
        guard let modelURL = NSBundle.mainBundle().URLForResource("MoeMoeDer", withExtension: "momd") else {
            print("File MoeMoeDer.momd Missing")
            return nil
        }
        return NSManagedObjectModel(contentsOfURL: modelURL)
    }()
    
    private static var persistentStoreCoordinator: NSPersistentStoreCoordinator? {
        get {
            guard let managedObjectModel = self.managedObjectModel else {
                print("Using managedObjectContext Fail")
                return nil
            }
            
            // 開啟 app 一次, 只會檢查一次是否已搬過去
            dispatch_once(&self.checkOldDBPathOnce) {
                if self.isDBInOldPath() {
                    self.moveDBToNewPath()
                }
                else {
                    DaiFileManager.applicationSupport["/MoeMoeDer/"]
                }
            }
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
            let url = self.applicationSupportDirectory.URLByAppendingPathComponent("/MoeMoeDer/MoeMoeDer.sqlite")
            let failureReason = "There was an error creating or loading the application's saved data."
            do {
                try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
            }
            catch {
                var dict = [String: AnyObject]()
                dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
                dict[NSLocalizedFailureReasonErrorKey] = failureReason
                
                dict[NSUnderlyingErrorKey] = error as NSError
                let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
                NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
                abort()
            }
            return coordinator
        }
    }
    
}

// MARK: CoreData
class CoreData {
    
    private static var internalManagedObjectContext: NSManagedObjectContext? = nil
    private static var managedObjectContextOnce: dispatch_once_t = 0
    private static var checkOldDBPathOnce: dispatch_once_t = 0
    
    static var managedObjectContext: NSManagedObjectContext {
        get {
            dispatch_once(&self.managedObjectContextOnce) {
                let coordinator = self.persistentStoreCoordinator
                let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
                managedObjectContext.persistentStoreCoordinator = coordinator
                self.internalManagedObjectContext = managedObjectContext
            }
            return self.internalManagedObjectContext!
        }
    }

    class func saveContext() {
        if self.managedObjectContext.hasChanges {
            self.managedObjectContext.performBlock({ () -> Void in
                do {
                    try self.managedObjectContext.save()
                }
                catch {
                    let nserror = error as NSError
                    NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                    abort()
                }
            })
        }
    }
    
}