//
//  AppDelegate.swift
//  Oikon
//
//  Created by Bruno Bernardino on 18/02/15.
//  Copyright (c) 2015 emotionLoop. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        self.synchronizeSettings()

        // Allow sending notifications even when the app is not focused
        NSUserNotificationCenter.default.delegate = self
        
        // Listen for iCloud changes (when they will happen)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.iCloudWillUpdate(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange, object: nil)
        
        // Listen for iCloud changes (after it's done)
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.iCloudDidUpdate(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.emotionloop.OikonMac" in the user's Application Support directory.
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls[urls.count - 1] 
        return appSupportURL.appendingPathComponent("com.emotionloop.OikonMac")
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Oikon", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = FileManager.default
        var shouldFail = false
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."

        // Make sure the application files directory is there
        let propertiesOpt: [AnyHashable: Any]?
        do {
            propertiesOpt = try (self.applicationDocumentsDirectory as NSURL).resourceValues(forKeys: [URLResourceKey.isDirectoryKey])
        } catch var error1 as NSError {
            error = error1
            propertiesOpt = nil
        } catch {
            fatalError()
        }

        if let properties = propertiesOpt {
            if !(properties[URLResourceKey.isDirectoryKey]! as AnyObject).boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } else {
            do {
                try fileManager.createDirectory(atPath: self.applicationDocumentsDirectory.path, withIntermediateDirectories: true, attributes: nil)
            } catch var error1 as NSError {
                error = error1
            } catch {
                fatalError()
            }
        }
        
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator?
        if !shouldFail && (error == nil) {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            do {
                try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.currentStoreURL(), options: self.storeOptions as! [AnyHashable: Any]?)
            } catch var error1 as NSError {
                error = error1
            } catch {
                fatalError()
            }
        }
        
        if shouldFail || (error != nil) {
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            if error != nil {
                dict[NSUnderlyingErrorKey] = error
            }
            //error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict as? [NSObject : AnyObject])
            //NSApplication.sharedApplication().presentError(error!)
            NSLog("Error: %@", error!)
            
            do {
                try fileManager.createDirectory(atPath: self.applicationDocumentsDirectory.path, withIntermediateDirectories: true, attributes: nil)
            } catch var error1 as NSError {
                error = error1
            } catch {
                fatalError()
            }
            
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            do {
                try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.currentStoreURL(), options: self.storeOptions as! [AnyHashable: Any]?)
            } catch var error1 as NSError {
                error = error1
            } catch {
                fatalError()
            }
        }

        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if let moc = self.managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
            }
            var error: NSError? = nil
            if moc.hasChanges {
                do {
                    try moc.save()
                } catch let error1 as NSError {
                    error = error1
                }
                let nserror = error! as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

    func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        if let moc = self.managedObjectContext {
            return moc.undoManager
        } else {
            return nil
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplicationTerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        if let moc = managedObjectContext {
            if !moc.commitEditing() {
                NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
                return .terminateCancel
            }
            
            if !moc.hasChanges {
                return .terminateNow
            }
            
            var error: NSError? = nil

            do {
                try moc.save()
            } catch let error1 as NSError {
                error = error1
            }

            if ( error != nil ) {
                let result = sender.presentError(error!)
                if (result) {
                    return .terminateCancel
                }
                
                let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
                let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
                let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
                let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
                let alert = NSAlert()
                alert.messageText = question
                alert.informativeText = info
                alert.addButton(withTitle: quitButton)
                alert.addButton(withTitle: cancelButton)
                
                let answer = alert.runModal()
                if answer == NSAlertFirstButtonReturn {
                    return .terminateCancel
                }
            }
        }

        // If we got here, it is time to quit.
        return .terminateNow
    }
    
    // Get current store URL (it will change based on if iCloud is enabled or not)
    func currentStoreURL() -> URL {
        return self.applicationDocumentsDirectory.appendingPathComponent("Oikon.sqlite")
    }
    
    // Store options for iCloud
    func iCloudStoreOptions() -> NSDictionary {
        return [ NSPersistentStoreUbiquitousContentNameKey: "iCloudStore" ]
    }
    
    // Store options for local
    func localStoreOptions() -> NSDictionary? {
        return [ NSPersistentStoreUbiquitousContentNameKey: "localStore" ]
    }
    
    var settings: UserDefaults = UserDefaults.standard
    var storeOptions: NSDictionary? = nil
    
    // Reload store
    func reloadWithNewStore(_ newStore: NSPersistentStore?) {
        NSLog("RELOADING STORE")
        
        self.synchronizeSettings()
    
        if ( newStore != nil ) {
            var error: NSError? = nil
            
            do {
                try self.persistentStoreCoordinator?.remove(newStore!)
            } catch let error1 as NSError {
                error = error1
            }
            
            if ( error != nil ) {
                NSLog("Unresolved error while removing persistent store \(String(describing: error)), \(String(describing: error?.userInfo))")
            }
        }
        
        var error: NSError? = nil
        
        do {
            try self.persistentStoreCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.currentStoreURL(), options:self.storeOptions as! [AnyHashable: Any]?)
        } catch let error1 as NSError {
            error = error1
            
            if ( error != nil ) {
                NSLog("Unresolved error while adding persistent store \(String(describing: error)), \(String(describing: error?.userInfo))")
            }
        }
    }

    // Set/get default settings
    func synchronizeSettings() -> Void {
        NSLog( "## Starting settings synchronization ##" )

        self.settings = UserDefaults.standard
        self.settings.synchronize()
        
        // iCloud sync
        if ( self.settings.object(forKey: "iCloud.osx") == nil ) {
            let defaultiCloud: NSMutableDictionary = [:]
            
            defaultiCloud.setValue(false, forKey:"isEnabled")
            defaultiCloud.setValue(nil, forKey:"lastSyncStart")// Last time a sync was started from the app
            defaultiCloud.setValue(nil, forKey:"lastSuccessfulSync")// Last time a sync was finished successfully from the app
            defaultiCloud.setValue(nil, forKey:"lastRemoteSync")// Last time an update existed remotely
            defaultiCloud.setValue(nil, forKey:"lastLocalUpdate")// Last time something was updated locally
            
            self.settings.set(defaultiCloud, forKey: "iCloud.osx")
            
            NSLog("#!## LOADING LOCAL DATA ##!#")
            self.storeOptions = self.localStoreOptions()
        } else {
            var iCloudSettings: NSMutableDictionary
            
            iCloudSettings = self.settings.object(forKey: "iCloud.osx") as! NSMutableDictionary
            
            if ( iCloudSettings.value(forKey: "isEnabled") as! Bool == true ) {
                NSLog("### LOADING ICLOUD DATA ###")
                self.storeOptions = self.iCloudStoreOptions()
            } else {
                NSLog("### LOADING LOCAL DATA ###")
                self.storeOptions = self.localStoreOptions()
            }
        }
        
        // Search dates
        if ( self.settings.value(forKey: "searchFromDate.osx") == nil ) {
            self.settings.setValue(nil, forKey:"searchFromDate.osx")
        }
        
        if ( self.settings.value(forKey: "searchToDate.osx") == nil ) {
            self.settings.setValue(nil, forKey:"searchToDate.osx")
        }
        
        // Filters - Type
        if ( self.settings.value(forKey: "filterTypes.osx") == nil ) {
            self.settings.setValue(nil, forKey:"filterTypes.osx")
        }
        
        // Filters - Name
        if ( self.settings.value(forKey: "filterName.osx") == nil ) {
            self.settings.setValue(nil, forKey:"filterName.osx")
        }
        
        self.settings.synchronize()
    }
    
    @IBAction func iCloudWillUpdate( _ sender: AnyObject? ) {
        self.setiCloudStartSyncDate()
    }
    
    @IBAction func iCloudDidUpdate( _ sender: AnyObject? ) {
        self.setiCloudEndSyncDate()
    }
    
    // Update iCloud start sync date
    func setiCloudStartSyncDate() {
        let iCloudSettings: NSMutableDictionary = (self.settings.object(forKey: "iCloud.osx") as! NSDictionary!).mutableCopy() as! NSMutableDictionary
    
        print("Set the sync start date to now", terminator: "")
    
        // Set the sync start date to now
        iCloudSettings.setValue(Date(), forKey:"lastSyncStart")
    
        self.settings.set(iCloudSettings, forKey:"iCloud.osx")
    }
    
    // Update iCloud end sync date
    func setiCloudEndSyncDate() {
        let iCloudSettings: NSMutableDictionary = (self.settings.object(forKey: "iCloud.osx") as! NSDictionary!).mutableCopy() as! NSMutableDictionary
    
        print("Set the sync end date to now", terminator: "")
    
        // Set the sync end date to now
        iCloudSettings.setValue(Date(), forKey:"lastSuccessfulSync")
    
        self.settings.set(iCloudSettings, forKey:"iCloud.osx")
    }
    
    // Migrate data to iCloud
    func migrateDataToiCloud() {
        print("Migrating data to iCloud", terminator: "")
    
        let tmpStoreOptions: NSMutableDictionary? = self.storeOptions?.mutableCopy() as! NSMutableDictionary?
    
        tmpStoreOptions?.setObject(true, forKey:NSPersistentStoreRemoveUbiquitousMetadataOption as NSCopying)
    
        let tmpStore: NSPersistentStore? = nil
    
        // Update store options for reload
        self.storeOptions = self.iCloudStoreOptions()
    
        // Reload store
        self.reloadWithNewStore(tmpStore)
    
        let iCloudSettings: NSMutableDictionary = (self.settings.object(forKey: "iCloud.osx") as! NSDictionary!).mutableCopy() as! NSMutableDictionary
    
        print("Set the last remote sync date to now", terminator: "")
    
        // Set the last remote sync date to now
        iCloudSettings.setValue(Date(), forKey:"lastRemoteSync")
    
        self.settings.set(iCloudSettings, forKey:"iCloud.osx")
    }
    
    // Migrate data to Local
    func migrateDataToLocal() {
        print("Migrating data to Local", terminator: "")
    
        let tmpStoreOptions: NSMutableDictionary? = self.storeOptions?.mutableCopy() as! NSMutableDictionary?
    
        tmpStoreOptions?.setObject(true, forKey:NSPersistentStoreRemoveUbiquitousMetadataOption as NSCopying)
    
        let tmpStore: NSPersistentStore? = nil
        
        // Update store options for reload
        self.storeOptions = self.localStoreOptions()
        
        // Reload store
        self.reloadWithNewStore(tmpStore)
        
        let iCloudSettings: NSMutableDictionary = (self.settings.object(forKey: "iCloud.osx") as! NSDictionary!).mutableCopy() as! NSMutableDictionary
    
        print("Set the last local sync date to now", terminator: "")
    
        // Set the last local sync date to now
        iCloudSettings.setValue(Date(), forKey:"lastLocalUpdate")
    
        self.settings.set(iCloudSettings, forKey:"iCloud.osx")
    }
    
    // Remove all data
    func removeAllData() {
        print("REMOVING ALL DATA!", terminator: "")
    
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
    
        // Remove all expenses
        var entityDesc = NSEntityDescription.entity(forEntityName: "Expense", in:context!)
        
        var request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entityDesc
        
        var objects: [NSManagedObject]
        
        var error: NSError? = nil
        
        objects = (try! context!.fetch(request)) as! [NSManagedObject]
        
        if ( error == nil ) {
            for object: NSManagedObject in objects {
                context?.delete(object)
            }
            
            do {
                try context?.save()
            } catch let error1 as NSError {
                error = error1
            }
        } else {
            NSLog("Error: %@", error!)
        }
        
        // Remove all expense types
        entityDesc = NSEntityDescription.entity(forEntityName: "ExpenseType", in:context!)
        
        request = NSFetchRequest()
        request.entity = entityDesc
        
        objects = []
        
        (try! context!.fetch(request)) as! [NSManagedObject]
        
        if ( error == nil ) {
            for object: NSManagedObject in objects {
                context?.delete(object)
            }
            
            do {
                try context?.save()
            } catch let error1 as NSError {
                error = error1
            }
        } else {
            NSLog("Error: %@", error!)
        }
    }
}

