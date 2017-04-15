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
        
        let application = NSApplication.shared()
        let fileString = NSLocalizedString("File", comment:"")

        let preferencesString = NSLocalizedString("Preferences…", comment:"")
        let exportString = NSLocalizedString("Export CSV…", comment:"")
        let importString = NSLocalizedString("Import CSV…", comment:"")
        
        let oikonMenuItem = application.mainMenu?.item(withTitle: "Oikon")!
        let fileMenuItem = application.mainMenu?.item(withTitle: fileString)!

        let preferencesMenuItem = (oikonMenuItem!.submenu?.item(withTitle: preferencesString))!
        let exportMenuItem = (fileMenuItem!.submenu?.item(withTitle: exportString))!
        let importMenuItem = (fileMenuItem!.submenu?.item(withTitle: importString))!
        
        // Add action to "Preferences..." menu item
        preferencesMenuItem.action = #selector(ViewController.openPreferences(_:))
        preferencesMenuItem.isEnabled = true
        preferencesMenuItem.target = self
        
        // Add action to "Export CSV..." menu item
        exportMenuItem.action = #selector(ViewController.exportCSV(_:))
        exportMenuItem.isEnabled = true
        exportMenuItem.target = self
        
        // Add action to "Import CSV..." menu item
        importMenuItem.action = #selector(ViewController.importCSV(_:))
        importMenuItem.isEnabled = true
        importMenuItem.target = self
    }
    
    // Formats the date for the CSV file
    func formatDateForCSV( _ date: Date ) -> NSString {
        let dateFormatter = DateFormatter()
        let locale = Locale(identifier: "en_US")

        dateFormatter.locale = locale
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let formattedDate = dateFormatter.string(from: date)

        return formattedDate as NSString
    }
    
    // Get all expenses, for CSV
    func getAllExpenses() -> [NSManagedObject] {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entity(forEntityName: "Expense", in:context!)
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entityDesc
        
        // Sort expenses by date
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let sortDescriptors = NSArray(object: sortDescriptor)
        
        request.sortDescriptors = sortDescriptors as? [NSSortDescriptor]
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.fetch(request) as NSArray
        
        if ( error != nil ) {
            objects = []
        }
        
        return objects as! [NSManagedObject]
    }
    
    // Generate a CSV file content for all expenses
    func getCSVFileString() -> NSString {
        var fileContents:NSString = ""
        
        // Add Header
        fileContents = fileContents.appending("Name,Type,Date,Value") as NSString

        let expenses = self.getAllExpenses()

        for expense: NSManagedObject in expenses {
            // Parse the values for text from the received object
            var expenseValue: NSString = NSString(format: "%0.2f", (expense.value(forKey: "value")! as AnyObject).floatValue)
            var expenseName: NSString = expense.value(forKey: "name")! as! NSString
            var expenseType: NSString
            if expense.value(forKey: "type") != nil {
                expenseType = expense.value(forKey: "type")! as! NSString
            } else {
                // Show "uncategorized" if nothing is set
                expenseType = "uncategorized"// This is not translated on purpose, so it's a "standard" for the CSV
            }
            var expenseDate = self.formatDateForCSV(expense.value(forKey: "date")! as! Date)
            
            // parse commas, new lines, and quotes for CSV
            expenseName = expenseName.replacingOccurrences(of: ",", with: ";") as NSString
            expenseName = expenseName.replacingOccurrences(of: "\n", with: " ") as NSString
            expenseName = expenseName.replacingOccurrences(of: "\"", with: "'") as NSString
            
            expenseType = expenseType.replacingOccurrences(of: ",", with: ";") as NSString
            expenseType = expenseType.replacingOccurrences(of: "\n", with: " ") as NSString
            expenseType = expenseType.replacingOccurrences(of: "\"", with: "'") as NSString
            
            expenseDate = expenseDate.replacingOccurrences(of: ",", with: ";") as NSString
            expenseDate = expenseDate.replacingOccurrences(of: "\n", with: " ") as NSString
            expenseDate = expenseDate.replacingOccurrences(of: "\"", with: "'") as NSString
            
            expenseValue = expenseValue.replacingOccurrences(of: ",", with: ";") as NSString
            expenseValue = expenseValue.replacingOccurrences(of: "\n", with: " ") as NSString
            expenseValue = expenseValue.replacingOccurrences(of: "\"", with: "'") as NSString
            
            let rowForExpense = NSString(format:"\n%@,%@,%@,%@", expenseName, expenseType, expenseDate, expenseValue)
            
            // Append string to file contents
            fileContents = fileContents.appending(rowForExpense as String) as NSString
        }
        
        //NSLog("Final file contents:\n\n%@", fileContents);
        
        return fileContents;
    }
    
    // Export CSV...
    func exportCSV( _ sender: AnyObject? ) {
        // Show panel to select a directory
        let panel: NSOpenPanel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.prompt = NSLocalizedString("Choose", comment: "")
        panel.title = NSLocalizedString("Select a directory to export the CSV file into.", comment: "")
        panel.begin { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let csvFileName: URL = panel.url!.appendingPathComponent(NSString(format:"oikon-export-%d.csv", Int(Date().timeIntervalSince1970)) as String)
                let csvFileContents = self.getCSVFileString()
                
                self.saveCSVFile(csvFileName, contents: csvFileContents)
            }
        }
    }
    
    // Actually save the CSV file
    func saveCSVFile( _ name: URL, contents: NSString ) {
        
        var error: NSError? = nil
        
        do {
            try contents.write(toFile: name.path, atomically: true, encoding: String.Encoding.utf8.rawValue)
        } catch let error1 as NSError {
            error = error1
        }
        
        if ( error == nil ) {
            // Notify the file was saved
            let notification: NSUserNotification = NSUserNotification()
            notification.title = NSLocalizedString("CSV File saved!", comment:"")
            notification.informativeText = NSString(format: NSLocalizedString("The file %@ was saved successfully.", comment:"") as NSString, name.lastPathComponent) as String
            notification.soundName = NSUserNotificationDefaultSoundName
            
            NSUserNotificationCenter.default.deliver(notification)
        } else {
            NSLog("Error: %@", error!)
            
            self.showAlert(NSLocalizedString("There was an error saving the export.", comment:"") as NSString, window: self.view.window!)
        }
    }
    
    // Import CSV...
    func importCSV( _ sender: AnyObject? ) {
        // Show panel to select a file
        let panel: NSOpenPanel = NSOpenPanel()
        panel.showsHiddenFiles = false
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedFileTypes = ["csv", "CSV"]
        panel.prompt = NSLocalizedString("Choose", comment: "")
        panel.title = NSLocalizedString("Choose the CSV file to import data from.", comment: "")
        panel.begin { (result) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let csvFileName: URL = panel.url!
                let csvFileData: Data = try! Data(contentsOf: csvFileName)
                let csvFileContents: NSString = NSString(data: csvFileData, encoding: String.Encoding.utf8.rawValue)!
                
                //NSLog("File contents:\n\n%@", csvFileContents)
                
                self.importCSVFile(csvFileName, contents: csvFileContents)
            }
        }
    }
    
    // Actually import the CSV file
    func importCSVFile( _ name: URL, contents: NSString ) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext

        let locale = Locale(identifier: "en_US")

        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = locale
        numberFormatter.numberStyle = NumberFormatter.Style.decimal

        // Ask if merge, replace, or cancel
        var action = "merge"
        let alertView = NSAlert()
        
        alertView.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alertView.addButton(withTitle: NSLocalizedString("Replace", comment: ""))
        alertView.addButton(withTitle: NSLocalizedString("Merge", comment: ""))
        alertView.alertStyle = NSAlertStyle.critical
        
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
        
        let csvRows = contents.components(separatedBy: "\n")
        
        for csvRow in csvRows {
            // Skip header
            if csvRow == "Name,Type,Date,Value" {
                continue
            }
            
            let csvData = csvRow.components(separatedBy: ",")
            
            //
            // Parse values
            
            let expenseName: NSString = csvData[0] as NSString
            var expenseType: NSString? = csvData[1] as NSString
            let expenseDate: Date = dateFormatter.date( from: csvData[2] )!
            let expenseValue: NSNumber = numberFormatter.number( from: csvData[3] )!
            
            // If the type is "uncategorized" (not translated on purpose), make it nil
            if ( expenseType == "uncategorized" ) {
                expenseType = nil
            }
            
            //
            // Add expense
            
            let newExpense: NSManagedObject = NSEntityDescription.insertNewObject(forEntityName: "Expense", into: context!) 
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
                
                self.showAlert(NSString(format:NSLocalizedString("There was an error adding an expense. Please confirm the value types match for line '%@'.", comment:"") as NSString, csvRow ), window: self.view.window!)
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
        notification.informativeText = NSString(format: NSLocalizedString("The file %@ was imported successfully.", comment:"") as NSString, name.lastPathComponent) as String
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    // Add Expense Type
    func addExpenseType( _ name: NSString ) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext

        let newExpenseType: NSManagedObject = NSEntityDescription.insertNewObject(forEntityName: "ExpenseType", into: context!) 
        
        newExpenseType.setValue(name, forKey: "name")
        
        var error: NSError? = nil
        do {
            try context!.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        if ( error != nil ) {
            NSLog("Error: %@", error!)
            
            self.showAlert(NSString(format:NSLocalizedString("There was an error adding your expense type. Please confirm the value types match for '%@'.", comment:"") as NSString, name), window: self.view.window!)
        }
    }
    
    // Check if an expense type name already exists
    func expenseTypeExists( _ expenseTypeName: NSString ) -> Bool {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entity(forEntityName: "ExpenseType", in:context!)
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entityDesc
        
        // Add expense type name to search
        let filterNamePredicate: NSPredicate = NSPredicate(format: "(name =[c] %@)", expenseTypeName)
        request.predicate = filterNamePredicate
        
        //
        // Search
        //
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.fetch(request) as NSArray
        
        if ( error != nil ) {
            objects = []
        }

        return ( objects.count > 0 )
    }
    
    // Open settings (Preferences... menu item)
    func openPreferences( _ sender: AnyObject? ) {
        self.performSegue(withIdentifier: "settings", sender: self)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        // Assign each "side" view controllers to each one
        if segue.identifier == "pastExpensesOpen" {
            let viewItems = (segue.destinationController as AnyObject).splitViewItems as [NSSplitViewItem]

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
    func parseFilterTypes( _ filterTypes: NSMutableArray ) -> NSMutableArray {
        let parsedFilterTypes = NSMutableArray(array: filterTypes as [AnyObject], copyItems: true)
        
        let uncategorizedText = NSLocalizedString("uncategorized", comment: "")
        
        let uncategorizedIndex = parsedFilterTypes.index(of: uncategorizedText)
    
        let hasUncategorized:Bool = parsedFilterTypes.contains(uncategorizedText)
    
        // Check if the uncategorized exists in the array
        if ( hasUncategorized ) {
            // Remove item in the array
            parsedFilterTypes.removeObject(at: uncategorizedIndex)
        }
    
        return parsedFilterTypes
    }
    
    // Show simple alert
    func showAlert( _ message: NSString, window: NSWindow ) {
        let alertView = NSAlert()

        alertView.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alertView.messageText = message as String
        alertView.alertStyle = NSAlertStyle.warning

        alertView.beginSheetModal(for: window, completionHandler: nil)
    }
    
    // Show confirm dialog
    func showConfirm( _ message: NSString ) -> NSModalResponse {
        let alertView = NSAlert()

        alertView.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        alertView.addButton(withTitle: NSLocalizedString("Delete", comment: ""))
        alertView.alertStyle = NSAlertStyle.critical
        
        alertView.messageText = message as String
        alertView.informativeText = NSLocalizedString("This action is irreversible.", comment:"")
        
        return alertView.runModal()
    }
}

