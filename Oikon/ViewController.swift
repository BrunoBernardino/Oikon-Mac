//
//  ViewController.swift
//  Oikon
//
//  Created by Bruno Bernardino on 18/02/15.
//  Copyright (c) 2015 emotionLoop. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    var thisController: ViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.thisController = self
        
        let application = NSApplication.sharedApplication()
        let fileString = NSLocalizedString("File", comment:"")

        let preferencesString = NSLocalizedString("Preferences…", comment:"")
        let exportString = NSLocalizedString("Export CSV…", comment:"")
        let importString = NSLocalizedString("Import CSV…", comment:"")
        
        let oikonMenuItem = application.mainMenu?.itemWithTitle("Oikon")!
        let fileMenuItem = application.mainMenu?.itemWithTitle(fileString)!

        let preferencesMenuItem = (oikonMenuItem!.submenu?.itemWithTitle(preferencesString))!
        let exportMenuItem = (fileMenuItem!.submenu?.itemWithTitle(exportString))!
        let importMenuItem = (fileMenuItem!.submenu?.itemWithTitle(importString))!
        
        // Add action to "Preferences..." menu item
        preferencesMenuItem.action = Selector("openPreferences:")
        preferencesMenuItem.enabled = true
        preferencesMenuItem.target = self
        
        // Add action to "Export CSV..." menu item
        exportMenuItem.action = Selector("exportCSV:")
        exportMenuItem.enabled = true
        exportMenuItem.target = self
        
        // Add action to "Import CSV..." menu item
        importMenuItem.action = Selector("importCSV:")
        importMenuItem.enabled = true
        importMenuItem.target = self
    }
    
    // Formats the date for the CSV file
    func formatDateForCSV( date: NSDate ) -> NSString {
        let dateFormatter = NSDateFormatter()
        let locale = NSLocale(localeIdentifier: "en_US")

        dateFormatter.locale = locale
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let formattedDate = dateFormatter.stringFromDate(date)

        return formattedDate
    }
    
    // Get all expenses, for CSV
    func getAllExpenses() -> [NSManagedObject] {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entityForName("Expense", inManagedObjectContext:context!)
        
        let request = NSFetchRequest()
        request.entity = entityDesc
        
        // Sort expenses by date
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let sortDescriptors = NSArray(object: sortDescriptor)
        
        request.sortDescriptors = sortDescriptors as? [NSSortDescriptor]
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.executeFetchRequest(request)
        
        if ( error != nil ) {
            objects = []
        }
        
        return objects as! [NSManagedObject]
    }
    
    // Generate a CSV file content for all expenses
    func getCSVFileString() -> NSString {
        var fileContents:NSString = ""
        
        // Add Header
        fileContents = fileContents.stringByAppendingString("Name,Type,Date,Value")

        let expenses = self.getAllExpenses()

        for expense: NSManagedObject in expenses {
            // Parse the values for text from the received object
            var expenseValue: NSString = NSString(format: "%0.2f", expense.valueForKey("value")!.floatValue)
            var expenseName: NSString = expense.valueForKey("name")! as! NSString
            var expenseType: NSString
            if expense.valueForKey("type") != nil {
                expenseType = expense.valueForKey("type")! as! NSString
            } else {
                // Show "uncategorized" if nothing is set
                expenseType = "uncategorized"// This is not translated on purpose, so it's a "standard" for the CSV
            }
            var expenseDate = self.formatDateForCSV(expense.valueForKey("date")! as! NSDate)
            
            // parse commas, new lines, and quotes for CSV
            expenseName = expenseName.stringByReplacingOccurrencesOfString(",", withString: ";")
            expenseName = expenseName.stringByReplacingOccurrencesOfString("\n", withString: " ")
            expenseName = expenseName.stringByReplacingOccurrencesOfString("\"", withString: "'")
            
            expenseType = expenseType.stringByReplacingOccurrencesOfString(",", withString: ";")
            expenseType = expenseType.stringByReplacingOccurrencesOfString("\n", withString: " ")
            expenseType = expenseType.stringByReplacingOccurrencesOfString("\"", withString: "'")
            
            expenseDate = expenseDate.stringByReplacingOccurrencesOfString(",", withString: ";")
            expenseDate = expenseDate.stringByReplacingOccurrencesOfString("\n", withString: " ")
            expenseDate = expenseDate.stringByReplacingOccurrencesOfString("\"", withString: "'")
            
            expenseValue = expenseValue.stringByReplacingOccurrencesOfString(",", withString: ";")
            expenseValue = expenseValue.stringByReplacingOccurrencesOfString("\n", withString: " ")
            expenseValue = expenseValue.stringByReplacingOccurrencesOfString("\"", withString: "'")
            
            let rowForExpense = NSString(format:"\n%@,%@,%@,%@", expenseName, expenseType, expenseDate, expenseValue)
            
            // Append string to file contents
            fileContents = fileContents.stringByAppendingString(rowForExpense as String)
        }
        
        //NSLog("Final file contents:\n\n%@", fileContents);
        
        return fileContents;
    }
    
    // Export CSV...
    func exportCSV( sender: AnyObject? ) {
        // Show panel to select a directory
        let panel: NSOpenPanel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = NSLocalizedString("Choose", comment: "")
        panel.title = NSLocalizedString("Select a directory to export the CSV file into.", comment: "")
        panel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let csvFileName: NSURL = panel.URL!.URLByAppendingPathComponent(NSString(format:"oikon-export-%d.csv", Int(NSDate().timeIntervalSince1970)) as String)
                let csvFileContents = self.getCSVFileString()
                
                self.saveCSVFile(csvFileName, contents: csvFileContents)
            }
        }
    }
    
    // Actually save the CSV file
    func saveCSVFile( name: NSURL, contents: NSString ) {
        
        var error: NSError? = nil
        
        do {
            try contents.writeToFile(name.path!, atomically: true, encoding: NSUTF8StringEncoding)
        } catch let error1 as NSError {
            error = error1
        }
        
        if ( error == nil ) {
            // Notify the file was saved
            let notification: NSUserNotification = NSUserNotification()
            notification.title = NSLocalizedString("CSV File saved!", comment:"")
            notification.informativeText = NSString(format: NSLocalizedString("The file %@ was saved scucessfully.", comment:""), name.lastPathComponent!) as String
            notification.soundName = NSUserNotificationDefaultSoundName
            
            NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        } else {
            NSLog("Error: %@", error!)
            
            self.showAlert(NSLocalizedString("There was an error saving the export.", comment:""), window: self.view.window!)
        }
    }
    
    // Import CSV...
    func importCSV( sender: AnyObject? ) {
        // Show panel to select a file
        let panel: NSOpenPanel = NSOpenPanel()
        panel.showsHiddenFiles = false
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["csv", "CSV"]
        panel.prompt = NSLocalizedString("Choose", comment: "")
        panel.title = NSLocalizedString("Choose the CSV file to import data from.", comment: "")
        panel.beginWithCompletionHandler { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let csvFileName: NSURL = panel.URL!
                let csvFileData: NSData = NSData(contentsOfURL: csvFileName)!
                let csvFileContents: NSString = NSString(data: csvFileData, encoding: NSUTF8StringEncoding)!
                
                //NSLog("File contents:\n\n%@", csvFileContents)
                
                self.importCSVFile(csvFileName, contents: csvFileContents)
            }
        }
    }
    
    // Actually import the CSV file
    func importCSVFile( name: NSURL, contents: NSString ) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext

        let locale = NSLocale(localeIdentifier: "en_US")

        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = locale
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let numberFormatter = NSNumberFormatter()
        numberFormatter.locale = locale
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle

        // Ask if merge, replace, or cancel
        var action = "merge"
        let alertView = NSAlert()
        
        alertView.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
        alertView.addButtonWithTitle(NSLocalizedString("Replace", comment: ""))
        alertView.addButtonWithTitle(NSLocalizedString("Merge", comment: ""))
        alertView.alertStyle = NSAlertStyle.CriticalAlertStyle
        
        alertView.messageText = NSLocalizedString("Do you want to replace all data (will remove everything before importing) or merge it? Duplicates might appear if you're merging.", comment:"")
        alertView.informativeText = NSLocalizedString("This action is irreversible.", comment:"")
        
        let promptResult = alertView.runModal()
        
        switch promptResult {
            case NSAlertFirstButtonReturn:
                // Exit
                return
            case NSAlertSecondButtonReturn:
                // Replace
                action = "replace"
                break
            case NSAlertThirdButtonReturn:
                // Merge, do nothing
                break
            default:
                // Exit
            return
        }
        
        // If we're replacing, remove all data first
        if ( action == "replace" ) {
            appDelegate.removeAllData()
        }
        
        let csvRows = contents.componentsSeparatedByString("\n")
        
        for csvRow in csvRows {
            // Skip header
            if csvRow == "Name,Type,Date,Value" {
                continue
            }
            
            let csvData = csvRow.componentsSeparatedByString(",")
            
            //
            // Parse values
            
            let expenseName: NSString = csvData[0] as NSString
            var expenseType: NSString? = csvData[1] as? NSString
            let expenseDate: NSDate = dateFormatter.dateFromString( csvData[2] )!
            let expenseValue: NSNumber = numberFormatter.numberFromString( csvData[3] )!
            
            // If the type is "uncategorized" (not translated on purpose), make it nil
            if ( expenseType == "uncategorized" ) {
                expenseType = nil
            }
            
            //
            // Add expense
            
            let newExpense: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("Expense", inManagedObjectContext: context!) 
            newExpense.setValue(expenseValue, forKey: "value")
            newExpense.setValue(expenseName, forKey: "name")
            newExpense.setValue(expenseType, forKey: "type")
            newExpense.setValue(expenseDate, forKey: "date")
            
            var error: NSError? = nil
            do {
                try context!.save()
            } catch let error1 as NSError {
                error = error1
            }
            
            if ( error != nil ) {
                NSLog("Error: %@", error!)
                
                self.showAlert(NSString(format:NSLocalizedString("There was an error adding an expense. Please confirm the value types match for line '%@'.", comment:""), csvRow ), window: self.view.window!)
            }
            
            // Add Expense Type if it doesn't exist
            if ( expenseType != nil ) {
                if ( !self.expenseTypeExists(expenseType!) ) {
                    self.addExpenseType( expenseType! )
                }
            }
        }
        
        // Notify the import has finished
        let notification: NSUserNotification = NSUserNotification()
        notification.title = NSLocalizedString("CSV File imported!", comment:"")
        notification.informativeText = NSString(format: NSLocalizedString("The file %@ was imported successfully.", comment:""), name.lastPathComponent!) as String
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    }
    
    // Add Expense Type
    func addExpenseType( name: NSString ) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext

        let newExpenseType: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("ExpenseType", inManagedObjectContext: context!) 
        
        newExpenseType.setValue(name, forKey: "name")
        
        var error: NSError? = nil
        do {
            try context!.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        if ( error != nil ) {
            NSLog("Error: %@", error!)
            
            self.showAlert(NSString(format:NSLocalizedString("There was an error adding your expense type. Please confirm the value types match for '%@'.", comment:""), name), window: self.view.window!)
        }
    }
    
    // Check if an expense type name already exists
    func expenseTypeExists( expenseTypeName: NSString ) -> Bool {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entityForName("ExpenseType", inManagedObjectContext:context!)
        
        let request = NSFetchRequest()
        request.entity = entityDesc
        
        // Add expense type name to search
        let filterNamePredicate: NSPredicate = NSPredicate(format: "(name =[c] %@)", expenseTypeName)
        request.predicate = filterNamePredicate
        
        //
        // Search
        //
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.executeFetchRequest(request)
        
        if ( error != nil ) {
            objects = []
        }

        return ( objects.count > 0 )
    }
    
    // Open settings (Preferences... menu item)
    func openPreferences( sender: AnyObject? ) {
        self.performSegueWithIdentifier("settings", sender: self)
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        // Assign each "side" view controllers to each one
        if segue.identifier == "pastExpensesOpen" {
            let viewItems = segue.destinationController.splitViewItems as [NSSplitViewItem]

            let listController = viewItems[0].viewController as! ExpensesListViewController
            let sidebarController = viewItems[1].viewController as! ExpensesListSidebarViewController
            
            listController.mainViewController = thisController
            sidebarController.mainViewController = thisController

            listController.sidebarViewController = sidebarController
            sidebarController.listViewController = listController
        }
        
        // Assign mainViewController
        if segue.identifier == "addExpense" {
            let viewController = segue.destinationController as! AddExpenseViewController
            viewController.mainViewController = thisController
        }
        
        // Assign mainViewController
        if segue.identifier == "expenseTypes" {
            let viewController = segue.destinationController as! ExpenseTypesListViewController
            viewController.mainViewController = thisController
        }
        
        // Assign mainViewController
        if segue.identifier == "settings" {
            let viewController = segue.destinationController as! SettingsViewController
            viewController.mainViewController = thisController
        }
    }
    
    // Change "uncategorized" with ""
    func parseFilterTypes( filterTypes: NSMutableArray ) -> NSMutableArray {
        let parsedFilterTypes = NSMutableArray(array: filterTypes as [AnyObject], copyItems: true)
        
        let uncategorizedText = NSLocalizedString("uncategorized", comment: "")
        
        let uncategorizedIndex = parsedFilterTypes.indexOfObject(uncategorizedText)
    
        let hasUncategorized:Bool = parsedFilterTypes.containsObject(uncategorizedText)
    
        // Check if the uncategorized exists in the array
        if ( hasUncategorized ) {
            // Remove item in the array
            parsedFilterTypes.removeObjectAtIndex(uncategorizedIndex)
        }
    
        return parsedFilterTypes
    }
    
    // Show simple alert
    func showAlert( message: NSString, window: NSWindow ) {
        let alertView = NSAlert()

        alertView.addButtonWithTitle(NSLocalizedString("OK", comment: ""))
        alertView.messageText = message as String
        alertView.alertStyle = NSAlertStyle.WarningAlertStyle

        alertView.beginSheetModalForWindow(window, completionHandler: nil)
    }
    
    // Show confirm dialog
    func showConfirm( message: NSString ) -> NSModalResponse {
        let alertView = NSAlert()

        alertView.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
        alertView.addButtonWithTitle(NSLocalizedString("Delete", comment: ""))
        alertView.alertStyle = NSAlertStyle.CriticalAlertStyle
        
        alertView.messageText = message as String
        alertView.informativeText = NSLocalizedString("This action is irreversible.", comment:"")
        
        return alertView.runModal()
    }
}

