//
//  ExpensesListViewController.swift
//  Oikon
//
//  Created by Bruno Bernardino on 24/05/15.
//  Copyright (c) 2015 emotionLoop. All rights reserved.
//

import Cocoa

class ExpensesListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSDatePickerCellDelegate {
    
    var thisController: ExpensesListViewController!
    
    // Set default expenses array
    var expenses: NSMutableArray! = []
    var expenseTypes: NSMutableArray! = []
    var currentFromDate: NSDate!
    var currentToDate: NSDate!
    var currentFilterName: NSString!
    var currentFilterTypes: NSMutableArray! = []
    let uncategorizedStringValue = NSLocalizedString("uncategorized", comment: "")
    
    var settings: NSUserDefaults!
    
    var sidebarViewController: ExpensesListSidebarViewController!
    var mainViewController: ViewController!
    
    var selectedExpenseIndex: Int!
    
    var lastiCloudFetch: NSDate?
    
    @IBOutlet var fromDateText: NSDatePicker!
    @IBOutlet var toDateText: NSDatePicker!

    @IBOutlet var expensesTableView: NSTableView!

    // From Date was changed
    @IBAction func changedFromDate(sender: AnyObject) {
        self.currentFromDate = self.fromDateText.dateValue
        
        // Update Settings & UI
        self.updateSearchSettings()
        self.updateSearchLabelsAndViews()
        
        // Reload data
        self.getAllExpenses()
    }

    // To Date was changed
    @IBAction func changedToDate(sender: AnyObject) {
        self.currentToDate = self.toDateText.dateValue
        
        // Update Settings & UI
        self.updateSearchSettings()
        self.updateSearchLabelsAndViews()
        
        // Reload data
        self.getAllExpenses()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // Listen for iCloud changes (after it's done)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "iCloudDidUpdate:", name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: nil)
        
        self.thisController = self
        
        // Set title
        //self.setTitle("Past Expenses");
        
        // Fetch previous search dates
        self.fetchSearchSettings()
        
        // Set default from and to dates to the current month (first to last day), if none was set before
        if ( self.currentFromDate == nil || self.currentToDate == nil ) {
            self.setDefaultSearchDates()
        }
        
        // Make sure the table loads data from and listens to this controller
        expensesTableView.setDelegate(self)
        expensesTableView.setDataSource(self)
        
        // Make sure the date fields are listening to this controller for changes
        self.fromDateText.delegate = self
        self.toDateText.delegate = self
        
        // Fetch expenses
        self.getAllExpenses()
    }
    
    override func viewWillAppear() {
        // Fetch settings
        self.fetchSearchSettings()
        
        // Initialize expense types
        self.getAllExpenses()
    }
    
    // Set from and to dates to the current month (first and last day)
    func setDefaultSearchDates() {
        let dateFormatter = NSDateFormatter()
        let currentDate = NSDate()
        let currentCalendar = NSCalendar.currentCalendar()
        let calendarUnits: NSCalendarUnit = [NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day]

        let dateComponents = currentCalendar.components(calendarUnits, fromDate: currentDate)
    
        // Set format for text views
        dateFormatter.dateFormat = NSLocalizedString("MMM, d yyyy", comment: "")
    
        //
        // Set "from date"
        //
        dateComponents.day = 1
        self.currentFromDate = currentCalendar.dateFromComponents(dateComponents)
    
        // Set "from date" text field
        //self.fromDateText.stringValue = dateFormatter.stringFromDate(self.currentFromDate)
        self.fromDateText.dateValue = self.currentFromDate
    
        //
        // Set "to date"
        //
        let daysRange: NSRange = currentCalendar.rangeOfUnit(NSCalendarUnit.Day, inUnit: NSCalendarUnit.Month, forDate: currentDate)
        dateComponents.day = daysRange.length// Last day of the current month
        
        self.currentToDate = currentCalendar.dateFromComponents(dateComponents)
    
        // Set "to date" text
        //self.toDateText.stringValue = dateFormatter.stringFromDate(self.currentToDate)
        self.toDateText.dateValue = self.currentToDate
    }
    
    // Get all expenses from a range (set in self.currentFromDate and self.currentToDate)
    func getAllExpenses() {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entityForName("Expense", inManagedObjectContext:context!)
    
        let request = NSFetchRequest()
        request.entity = entityDesc
    
        // Sort expenses by date
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let sortDescriptors = NSArray(object: sortDescriptor)
        
        request.sortDescriptors = sortDescriptors as? [NSSortDescriptor]
    
        // Check if the dates are valid
        if ( self.currentFromDate == nil || self.currentToDate == nil ) {
            // If not, set the dates as the current month (first to last day)
            //NSLog( "DATES WERE NOT VALID!!!" );
            self.setDefaultSearchDates()
        }
    
        //
        // Update dates' times
        //
    
        // Make start date's time = 00:00:00
        let currentCalendar = NSCalendar.currentCalendar()
        let calendarUnits: NSCalendarUnit = [NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Hour, NSCalendarUnit.Minute, NSCalendarUnit.Second]
        let fromDateComponents = currentCalendar.components(calendarUnits, fromDate: self.currentFromDate)
    
        fromDateComponents.hour = 0
        fromDateComponents.minute = 0
        fromDateComponents.second = 0

        self.currentFromDate = currentCalendar.dateFromComponents(fromDateComponents)
    
        // Make end date's time = 23:59:59
        let toDateComponents = currentCalendar.components(calendarUnits, fromDate: self.currentToDate)
    
        toDateComponents.hour = 23
        toDateComponents.minute = 59
        toDateComponents.second = 59
        
        self.currentToDate = currentCalendar.dateFromComponents(toDateComponents)
    
        //
        // Update search settings and search
        //
    
        self.updateSearchSettings()
    
        let usedPredicates = NSMutableArray()
    
        // Add dates to search
        let datesPredicate = NSPredicate(format: "(date >= %@) and (date <= %@)", self.currentFromDate, self.currentToDate)
        
        usedPredicates.addObject(datesPredicate)

        // Add any self.currentFilterTypes to search
        let filterTypesPredicate: NSPredicate
        
        if ( self.currentFilterTypes.count > 0 ) {
            let uncategorizedText = NSLocalizedString("uncategorized", comment: "")
            
            let hasUncategorized:Bool = self.currentFilterTypes.containsObject(uncategorizedText)
            
            // Parse the array, removing "uncategorized"
            let parsedFilterTypes = mainViewController.parseFilterTypes(self.currentFilterTypes)
    
            // If there are still any items, it means we're filtering for more than uncategorized
            if ( parsedFilterTypes.count > 0 ) {
                if ( hasUncategorized ) {
                    filterTypesPredicate = NSPredicate(format: "(type IN %@) or (type = nil)", parsedFilterTypes)
                } else {
                    filterTypesPredicate = NSPredicate(format: "(type IN %@)", parsedFilterTypes)
                }
            } else {
                // If not, it just means we were only filtering uncategorized
                filterTypesPredicate = NSPredicate(format: "(type = nil)")
            }
            
            usedPredicates.addObject(filterTypesPredicate)
        }
    
        // Add any self.currentFilterName to search
        let filterNamePredicate: NSPredicate
        if ( self.currentFilterName.length > 0 ) {
            filterNamePredicate = NSPredicate(format: "(name CONTAINS[cd] %@)", self.currentFilterName)
    
            usedPredicates.addObject(filterNamePredicate)
        }

        // Add the predicate to the request
        let finalPredicate: NSPredicate = NSCompoundPredicate(andPredicateWithSubpredicates:usedPredicates as AnyObject as! [NSPredicate])
        request.predicate = finalPredicate
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.executeFetchRequest(request)
        
        if ( error != nil ) {
            objects = []
        }
        
        self.expenses = NSMutableArray(array: objects)
        
        //NSLog("%@", self.expenses)
        
        // Calculate and show total
        sidebarViewController.calculateAndShowTotal( self.expenses )
        
        // Reload view with new data
        self.expensesTableView.reloadData()
    }
    
    // Fetch search settings
    func fetchSearchSettings() {
        self.settings = NSUserDefaults.standardUserDefaults()
        self.settings.synchronize()
        
        var shouldUpdateUI:Bool = false
        
        //
        // Dates
        //
        
        if let currentSearchFromDate = self.settings.valueForKey("searchFromDate.osx") as? NSDate {
            self.currentFromDate = currentSearchFromDate
            shouldUpdateUI = true
        }

        if let currentSearchToDate = self.settings.valueForKey("searchToDate.osx") as? NSDate {
            self.currentToDate = currentSearchToDate
            shouldUpdateUI = true
        }

        //
        // Filter Types
        //
        
        if let filterTypes = self.settings.valueForKey("filterTypes.osx") as? NSArray {
            self.currentFilterTypes = NSMutableArray(array: filterTypes as [AnyObject], copyItems: true)
            shouldUpdateUI = true
        } else {
            self.currentFilterTypes = NSMutableArray()
        }
        
        //
        // Filter Name
        //
        
        if let filterName = self.settings.valueForKey("filterName.osx") as? NSString {
            self.currentFilterName = filterName
            shouldUpdateUI = true
        } else {
            self.currentFilterName = ""
        }
        
        //
        // UI Updates
        //
        
        if ( shouldUpdateUI ) {
            self.updateSearchLabelsAndViews()
        }
    }
    
    // Update search settings
    func updateSearchSettings() {
        self.settings = NSUserDefaults.standardUserDefaults()
        self.settings.synchronize()
        
        self.settings.setValue(self.currentFromDate, forKey: "searchFromDate.osx")
        self.settings.setValue(self.currentToDate, forKey: "searchToDate.osx")
        self.settings.setValue(self.currentFilterName, forKey: "filterName.osx")
        self.settings.setValue(self.currentFilterTypes, forKey: "filterTypes.osx")
    }
    
    // Update search labels & views
    func updateSearchLabelsAndViews() {
        let dateFormatter = NSDateFormatter()
    
        // Set format for text views
        dateFormatter.dateFormat = NSLocalizedString("MMM, d yyyy", comment: "")
    
        // Set "from date" text view
        //self.fromDateText.stringValue = dateFormatter.stringFromDate(self.currentFromDate)
        self.fromDateText.dateValue = self.currentFromDate
    
        // Set "to date" text view
        //self.toDateText.stringValue = dateFormatter.stringFromDate(self.currentToDate)
        self.toDateText.dateValue = self.currentToDate
    
        // Mark type toggles as switched off/on
        if ( self.sidebarViewController != nil && self.sidebarViewController.selectedExpenseTypeNames != nil ) {
            self.sidebarViewController.selectedExpenseTypeNames = NSMutableArray(array: self.currentFilterTypes)
            if ( self.sidebarViewController.expenseTypesTableView != nil ) {
                self.sidebarViewController.expenseTypesTableView.reloadData()
            }
        }
    
        // Set current filter name text view
        if ( self.sidebarViewController != nil && self.sidebarViewController.searchText != nil ) {
            self.sidebarViewController.searchText.stringValue = self.currentFilterName as String
        }
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        let numberOfRows:Int = self.expenses.count
        return numberOfRows
    }
    
    // Format & Display Row Cells
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cellIdentifier = NSString(format: "%@Cell", tableColumn!.identifier) as String!
        
        let result: NSTableCellView = self.expensesTableView.makeViewWithIdentifier(cellIdentifier, owner: self.expensesTableView) as! NSTableCellView
        
        var stringValue: AnyObject? = self.expenses.objectAtIndex( row ).valueForKey( tableColumn!.identifier )
        
        // Format Value
        if ( tableColumn!.identifier == "value" ) {
            let numberFormatter = NSNumberFormatter()
            numberFormatter.locale = NSLocale.currentLocale()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            
            stringValue = NSString(format:"%@", numberFormatter.stringFromNumber(NSNumber(float: stringValue as! Float))!)
        }
        
        // Format Date
        if ( tableColumn!.identifier == "date" ) {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = NSLocalizedString("MMM, d", comment:"")
            let locale = NSLocale(localeIdentifier: NSLocalizedString("en_US", comment:""))
            dateFormatter.locale = locale
            
            stringValue = dateFormatter.stringFromDate(stringValue as! NSDate)
        }
        
        // Format Type
        if ( tableColumn!.identifier == "type" ) {
            if ( stringValue == nil ) {
                stringValue = "—"
            }
        }
        
        result.textField!.stringValue = stringValue as! String
        
        return result
    }
    
    // Get all expense types
    func getAllExpenseTypes() {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entityForName("ExpenseType", inManagedObjectContext:context!)
        
        let request = NSFetchRequest()
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
        objects = try! context!.executeFetchRequest(request)
        
        if ( error != nil ) {
            objects = []
        }
        
        let objectsCopy = NSMutableArray(array: objects)
        
        // Add Uncategorized on the beginning of the array
        let uncategorizedObject: [String: String] = [ "name": uncategorizedStringValue ]
        objectsCopy.insertObject( uncategorizedObject, atIndex: 0)
        
        if ( objectsCopy.count == 0 ) {
            /*let alertView = NSAlert()
            alertView.addButtonWithTitle("OK")
            alertView.messageText = "There was an error fetching your expense types. Maybe you don't have any yet?"
            alertView.alertStyle = NSAlertStyle.WarningAlertStyle
            alertView.runModal()*/
            
            //NSLog("Objects fetched were 0")
        }
        
        self.expenseTypes = NSMutableArray(array: objectsCopy)
        
        //NSLog("%@", self.expenseTypes)
    }
    
    // Get a sum of all expenses for a given expense type (between dates)
    func getExpenseTypeSum( expenseTypeName: NSString ) -> Float {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let entityDesc = NSEntityDescription.entityForName("Expense", inManagedObjectContext:context!)
        
        let request = NSFetchRequest()
        request.entity = entityDesc
        
        let usedPredicates = NSMutableArray()
        
        // Add dates to search
        let datesPredicate = NSPredicate(format: "(date >= %@) and (date <= %@)", self.currentFromDate, self.currentToDate)
        
        usedPredicates.addObject(datesPredicate)
        
        // Add expense type name to search
        var filterNamePredicate: NSPredicate = NSPredicate(format: "(type =[c] %@)", expenseTypeName)
        
        // Search for nil when trying to find uncategorized
        if ( expenseTypeName == uncategorizedStringValue ) {
            filterNamePredicate = NSPredicate(format: "(type = nil)")
        }
        
        usedPredicates.addObject(filterNamePredicate)
        
        // Add the predicate to the request
        let finalPredicate: NSPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: usedPredicates as AnyObject as! [NSPredicate])
        request.predicate = finalPredicate
        
        //
        // Search
        //
        
        var objects: NSArray
        
        let error: NSError? = nil
        objects = try! context!.executeFetchRequest(request)
        
        if ( error != nil ) {
            objects = []
        }
        
        var total: Float = 0
        
        for object in objects {
            total += object.valueForKey("value") as! Float
        }
        
        return total
    }
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        // Assign mainViewController
        if segue.identifier == "editExpense" {
            let viewController = segue.destinationController as! EditExpenseViewController
            viewController.indexOfExpenseBeingEdited = self.selectedExpenseIndex
            viewController.mainViewController = thisController
        }
    }
    
    // Clicking on a row to view an expense
    @IBAction func showExpense(sender: AnyObject) {
        let selectedRowIndex = self.expensesTableView.selectedRow
        
        // If the index is -1 means nothing is selected, but this event was triggered still
        if ( selectedRowIndex != -1 ) {
            // Define selected values
            self.selectedExpenseIndex = selectedRowIndex
            
            // Show popover
            self.performSegueWithIdentifier("editExpense", sender: self)
        }
    }
    
    // iCloud just finished updating
    @IBAction func iCloudDidUpdate( sender: AnyObject? ) {
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
            self.getAllExpenses()
            self.getAllExpenseTypes()
        }*/
    }
    
}
