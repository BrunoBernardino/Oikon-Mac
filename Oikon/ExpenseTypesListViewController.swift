//
//  ExpenseTypesListViewController.swift
//  Oikon
//
//  Created by Bruno Bernardino on 20/06/15.
//  Copyright (c) 2015 emotionLoop. All rights reserved.
//

import Cocoa

class ExpenseTypesListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    // Set default expense types array
    var expenseTypes: NSMutableArray! = []
    
    var selectedExpenseTypeIndex: Int! = 0
    var selectedExpenseTypeName: NSString! = ""
    
    var lastiCloudFetch: Date?
    
    var thisController: ExpenseTypesListViewController!
    var mainViewController: ViewController!
    
    @IBOutlet var expenseTypesTableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // Listen for iCloud changes (after it's done)
        NotificationCenter.default.addObserver(self, selector: #selector(ExpenseTypesListViewController.iCloudDidUpdate(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: nil)
        
        self.thisController = self
        
        // Set title
        //self.setTitle("Expense Types");
        
        // Make sure the table loads data from and listens to this controller
        expenseTypesTableView.delegate = self
        expenseTypesTableView.dataSource = self
        
        // Fetch expense types
        self.getAllExpenseTypes()
    }
    
    override func viewWillAppear() {
        // Initialize expense types
        self.getAllExpenseTypes()
    }
    
    // Get all expense types
    func getAllExpenseTypes() {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entity(forEntityName: "ExpenseType", in:context!)
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entityDesc
        
        // Sort expenses by name
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
        let sortDescriptors = NSArray(object: sortDescriptor)
        
        request.sortDescriptors = sortDescriptors as? [NSSortDescriptor]
        
        //
        // Search
        //
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.fetch(request) as NSArray
        
        if ( error != nil ) {
            objects = []
        }
        
        if ( objects.count == 0 ) {
            /*let alertView = NSAlert()
            alertView.addButtonWithTitle("OK")
            alertView.messageText = "There was an error fetching your expense types. Maybe you don't have any yet?"
            alertView.alertStyle = NSAlertStyle.WarningAlertStyle
            alertView.runModal()*/
            
            //NSLog("Objects fetched were 0")
        }
        
        self.expenseTypes = NSMutableArray(array: objects)
        
        //NSLog("%@", self.expenseTypes)
        
        // Reload view with new data
        self.expenseTypesTableView.reloadData()
    }
    
    // Get a count of all expenses for a given expense type
    func getExpenseTypeCount( _ expenseTypeName: NSString ) -> NSInteger {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entity(forEntityName: "Expense", in:context!)
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entityDesc
        
        // Add expense type name to search
        let filterNamePredicate: NSPredicate = NSPredicate(format: "(type =[c] %@)", expenseTypeName)
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
        
        return objects.count
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
    
    func numberOfRows(in aTableView: NSTableView) -> Int {
        let numberOfRows:Int = self.expenseTypes.count
        return numberOfRows
    }
    
    // Format & Display Row Cells
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cellIdentifier = NSString(format: "%@Cell", tableColumn!.identifier) as String!
        
        let result: NSTableCellView = self.expenseTypesTableView.make(withIdentifier: cellIdentifier!, owner: self.expenseTypesTableView) as! NSTableCellView
        
        var stringValue: NSString!
        
        // Format Count
        if ( tableColumn!.identifier == "count" ) {
            let numberOfExpenses = self.getExpenseTypeCount( (self.expenseTypes.object(at: row) as AnyObject).value(forKey: "name") as! NSString ) as NSNumber
            let numberFormatter = NumberFormatter()
            numberFormatter.locale = Locale.current
            numberFormatter.numberStyle = NumberFormatter.Style.none
            
            stringValue = numberFormatter.string(from: numberOfExpenses)! as NSString
        } else {
            stringValue = (self.expenseTypes.object( at: row ) as AnyObject).value( forKey: tableColumn!.identifier ) as! NSString!
        }
        
        result.textField!.stringValue = stringValue as String
        
        return result
    }
    
    // Row is selected
    @IBAction func showExpenseTypeForEdit(_ sender: AnyObject) {
        let selectedRowIndex = self.expenseTypesTableView.selectedRow
        
        // If the index is -1 means nothing is selected, but this event was triggered still
        if ( selectedRowIndex != -1 ) {
            // Define selected values
            self.selectedExpenseTypeIndex = selectedRowIndex
            self.selectedExpenseTypeName = (self.expenseTypes.object(at: selectedRowIndex) as AnyObject).value(forKey: "name") as! NSString
            
            // Show popover
            self.performSegue(withIdentifier: "editExpenseType", sender: self)
        }
    }
    
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        // Assign mainViewController
        if segue.identifier == "addExpenseType" {
            let viewController = segue.destinationController as! AddExpenseTypeViewController
            viewController.mainViewController = thisController
        }
        
        // Assign mainViewController & original expense type
        if segue.identifier == "editExpenseType" {
            let viewController = segue.destinationController as! EditExpenseTypeViewController
            viewController.mainViewController = thisController
            viewController.originalExpenseTypeIndex = selectedExpenseTypeIndex
            viewController.originalExpenseTypeName = selectedExpenseTypeName
            
        }
    }
    
    // iCloud just finished updating
    @IBAction func iCloudDidUpdate( _ sender: AnyObject? ) {
        // TODO: This is causing some unnecessary instability
        /*// This was creating an infinite loop, so we only allow this to run once every minute tops.
        let codeHasRunInThePastMinute: Bool
        
        if ( self.lastiCloudFetch != nil ) {
            let secondsAfterLastRun = Int( NSDate().timeIntervalSinceDate(self.lastiCloudFetch!) )
            
            if ( secondsAfterLastRun < 60 ) {
                codeHasRunInThePastMinute = true
            } else {
                codeHasRunInThePastMinute = false
                self.lastiCloudFetch = NSDate()
            }
        } else {
            self.lastiCloudFetch = NSDate()
            codeHasRunInThePastMinute = true// We won't allow this to run so soon in the app
        }
        
        // Run the actual code, if there's a need to
        if ( !codeHasRunInThePastMinute ) {
            self.getAllExpenseTypes()
        }*/
    }
    
}
