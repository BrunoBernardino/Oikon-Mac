//
//  AddExpenseViewController.swift
//  Oikon
//
//  Created by Bruno Bernardino on 16/06/15.
//  Copyright (c) 2015 emotionLoop. All rights reserved.
//

import Cocoa

class AddExpenseViewController: NSViewController {
    
    var mainViewController: ViewController!
    
    var expenseTypes: NSMutableArray! = []
    let uncategorizedStringValue = NSLocalizedString("uncategorized", comment: "")

    @IBOutlet var valueText: NSTextField!
    @IBOutlet var nameText: NSTextField!
    @IBOutlet var dateText: NSDatePicker!
    @IBOutlet var typeText: NSPopUpButton!
    @IBOutlet var addExpenseButton: NSButton!
    
    // Add expense
    @IBAction func addExpense(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        
        // Set defaults
        var expenseValue: NSNumber = 0
        var expenseName: NSString = ""
        var expenseType: NSString? = uncategorizedStringValue as NSString
        var expenseDate: Date = Date()// Default expense date to "now"
        
        // Avoid empty values crashing the code
        if let tmpExpenseValue: NSNumber = numberFormatter.number(from: self.valueText.stringValue) {
            expenseValue = tmpExpenseValue
        }
        if let tmpExpenseName: NSString = self.nameText.stringValue as NSString? {
            expenseName = tmpExpenseName
        }
        if let tmpExpenseType: NSString = self.typeText.titleOfSelectedItem! as NSString? {
            expenseType = tmpExpenseType
        }
        if let tmpExpenseDate: Date = self.dateText.dateValue as Date? {
            expenseDate = tmpExpenseDate
        }
        
        //NSLog("%d, %@, %@, %@", expenseValue, expenseName, expenseType!, expenseDate)
        
        //
        // START: Validate fields for common errors
        //
        
        // Check if value is greater than 0
        if ( !expenseValue.boolValue ) {
            self.mainViewController.showAlert(NSLocalizedString("Please confirm the value of the expense.", comment:"") as NSString, window: self.view.window!)
            
            return;
        }
        
        // Check if the expense name is not empty
        if ( expenseName.length <= 0 ) {
            self.mainViewController.showAlert(NSLocalizedString("Please confirm the name of the expense.", comment:"") as NSString, window: self.view.window!)
            
            return;
        }
        
        //
        // END: Validate fields for common errors
        //
        
        // Check if the expense type is empty (if empty or uncategorized, set to nil)
        if ( expenseType!.length <= 0 || expenseType!.isEqual(to: uncategorizedStringValue) ) {
            expenseType = nil
        }
        
        //
        // Save object
        //
        
        let newExpense: NSManagedObject = NSEntityDescription.insertNewObject(forEntityName: "Expense", into: context!) 
        newExpense.setValue(expenseValue, forKey: "value")
        newExpense.setValue(expenseName, forKey: "name")
        newExpense.setValue(expenseType, forKey: "type")
        newExpense.setValue(expenseDate, forKey: "date")
        
        var error: NSError? = nil
        do {
            try context?.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        if ( error == nil ) {
            // Cleanup fields
            self.valueText.stringValue = ""
            self.nameText.stringValue = ""
            self.typeText.selectItem(at: 0)
            self.typeText.setTitle(uncategorizedStringValue)
            self.dateText.dateValue = Date()
            
            //self.mainViewController.showAlert(NSLocalizedString("Your expense was added successfully.", comment:""), window: self.view.window!)
        } else {
            NSLog("Error: %@", error!)
            
            self.mainViewController.showAlert(NSLocalizedString("There was an error adding your expense. Please confirm the value types match.", comment:"") as NSString, window: self.view.window!)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // Get expense types
        self.getAllExpenseTypes()
        
        //
        // Update value placeholder
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        
        self.valueText.placeholderString = numberFormatter.string(from: 9.99)
        
        //
        // Add items to drop-down
        
        // Fill up expense types
        var expenseTypeStrings: [String] = []
        
        // Add uncategorized
        expenseTypeStrings.append( "" )
        expenseTypeStrings.append( self.uncategorizedStringValue )
        
        for expenseType in self.expenseTypes {
            expenseTypeStrings.append( (expenseType as AnyObject).value(forKey: "name") as! String )
        }
        
        self.typeText.removeAllItems()
        self.typeText.addItems(withTitles: expenseTypeStrings)
        
        // Select uncategorized by default
        self.typeText.selectItem(withTitle: self.uncategorizedStringValue)
        self.typeText.setTitle(self.uncategorizedStringValue)
        
        // Set default date for today
        self.dateText.dateValue = Date()
    }
    
    override func viewWillAppear() {
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
    }
    
    // This is what visually updates the selected item when the popup is changed
    @IBAction func typePopUpChanged(_ sender: AnyObject) {
        self.typeText.setTitle( self.typeText.titleOfSelectedItem! )
    }

}
