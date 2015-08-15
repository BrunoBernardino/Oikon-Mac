//
//  EditExpenseViewController.swift
//  Oikon
//
//  Created by Bruno Bernardino on 07/07/15.
//  Copyright (c) 2015 emotionLoop. All rights reserved.
//

import Cocoa

class EditExpenseViewController: NSViewController {
    
    var mainViewController: ExpensesListViewController!
    
    var indexOfExpenseBeingEdited: Int!

    @IBOutlet var valueText: NSTextField!
    @IBOutlet var nameText: NSTextField!
    @IBOutlet var dateText: NSDatePicker!
    @IBOutlet var typeText: NSPopUpButton!
    
    // Update expense
    @IBAction func updateExpense(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let numberFormatter = NSNumberFormatter()
        numberFormatter.locale = NSLocale.currentLocale()
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        
        let uncategorizedStringValue = NSLocalizedString("uncategorized", comment: "")
        
        // Set defaults
        var expenseValue: NSNumber = 0
        var expenseName: NSString = ""
        var expenseType: NSString? = uncategorizedStringValue
        var expenseDate: NSDate = NSDate()// Default expense date to "now"
        
        // Avoid empty values crashing the code
        if let tmpExpenseValue: NSNumber = numberFormatter.numberFromString(self.valueText.stringValue) {
            expenseValue = tmpExpenseValue
        }
        if let tmpExpenseName: NSString = self.nameText.stringValue as NSString? {
            expenseName = tmpExpenseName
        }
        if let tmpExpenseType: NSString = self.typeText.titleOfSelectedItem! as NSString? {
            expenseType = tmpExpenseType
        }
        if let tmpExpenseDate: NSDate = self.dateText.dateValue as NSDate? {
            expenseDate = tmpExpenseDate
        }
        
        //NSLog("%d, %@, %@, %@", expenseValue, expenseName, expenseType!, expenseDate)
        
        //
        // START: Validate fields for common errors
        //
        
        // Check if value is greater than 0
        if ( !expenseValue.boolValue ) {
            self.mainViewController.mainViewController.showAlert(NSLocalizedString("Please confirm the value of the expense.", comment:""), window: self.view.window!)
            
            return;
        }
        
        // Check if the expense name is not empty
        if ( expenseName.length <= 0 ) {
            self.mainViewController.mainViewController.showAlert(NSLocalizedString("Please confirm the name of the expense.", comment:""), window: self.view.window!)
            
            return;
        }
        
        //
        // END: Validate fields for common errors
        //
        
        // Check if the expense type is empty (if empty or uncategorized, set to nil)
        if ( expenseType!.length <= 0 || expenseType!.isEqualToString(uncategorizedStringValue) ) {
            expenseType = nil
        }
        
        //
        // Save object
        //
        
        let expenseBeingUpdated: NSManagedObject = self.mainViewController.expenses.objectAtIndex(self.indexOfExpenseBeingEdited) as! NSManagedObject
        expenseBeingUpdated.setValue(expenseValue, forKey: "value")
        expenseBeingUpdated.setValue(expenseName, forKey: "name")
        expenseBeingUpdated.setValue(expenseType, forKey: "type")
        expenseBeingUpdated.setValue(expenseDate, forKey: "date")
        
        var error: NSError? = nil
        context?.save(&error)
        
        if ( error == nil ) {
            //self.mainViewController.showAlert(NSLocalizedString("Your expense was updated successfully.", comment:""), window: self.view.window!)
        } else {
            NSLog("Error: %@", error!)
            
            self.mainViewController.mainViewController.showAlert(NSLocalizedString("There was an error updating your expense. Please confirm the value types match.", comment:""), window: self.view.window!)
        }
        
        // Update expenses list
        self.mainViewController.getAllExpenses()
        
        // Close popover
        self.dismissViewController(self)
    }
    
    // Delete expense
    @IBAction func deleteExpense(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let expenseToRemove: NSManagedObject = self.mainViewController.expenses.objectAtIndex( self.indexOfExpenseBeingEdited ) as! NSManagedObject
        
        let buttonPressed = self.mainViewController.mainViewController.showConfirm( NSLocalizedString("Are you sure you want to delete this expense?", comment: "") )
        
        // Confirmed!
        if buttonPressed == NSAlertSecondButtonReturn {
            // Delete from core data
            context?.deleteObject(expenseToRemove)
            
            var error: NSError? = nil
            context?.save(&error)
            
            if ( error == nil ) {
                // Delete from view
                self.mainViewController.expenses.removeObjectAtIndex(self.indexOfExpenseBeingEdited)
                
                // Update the expenses list
                self.mainViewController.getAllExpenses()
            } else {
                NSLog("Error: %@", error!)
            }
            
            // Close popover
            //self.dismissViewController(self)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let uncategorizedString = NSLocalizedString("uncategorized", comment: "")
        
        // Fill up expense types
        var expenseTypeStrings: [String] = []
        
        // Add uncategorized
        expenseTypeStrings.append( "" )
        expenseTypeStrings.append( uncategorizedString )
        
        for expenseType in self.mainViewController.expenseTypes {
            expenseTypeStrings.append( expenseType.valueForKey("name") as! String )
        }
        
        self.typeText.removeAllItems()
        self.typeText.addItemsWithTitles(expenseTypeStrings)
        
        // Fill up UI with details from the selected expense
        
        let expenseBeingUpdated: NSManagedObject = self.mainViewController.expenses.objectAtIndex(self.indexOfExpenseBeingEdited) as! NSManagedObject
        
        // Format Value
        var valueString: AnyObject? = expenseBeingUpdated.valueForKey("value")
        let numberFormatter = NSNumberFormatter()
        numberFormatter.locale = NSLocale.currentLocale()
        numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        
        valueString = NSString(format:"%@", numberFormatter.stringFromNumber(NSNumber(float: valueString as! Float))!)
        
        self.valueText.stringValue = valueString as! String
        self.nameText.stringValue = expenseBeingUpdated.valueForKey("name") as! String
        self.dateText.dateValue = expenseBeingUpdated.valueForKey("date") as! NSDate
        
        // Select proper expense type
        if let selectedType: AnyObject = expenseBeingUpdated.valueForKey("type") {
            self.typeText.selectItemWithTitle(selectedType as! String)
            self.typeText.setTitle(selectedType as! String)
        } else {
            self.typeText.selectItemWithTitle(uncategorizedString)
            self.typeText.setTitle(uncategorizedString)
        }
    }
    
    override func viewWillAppear() {
    }
    
    // This is what visually updates the selected item when the popup is changed
    @IBAction func typePopUpChanged(sender: AnyObject) {
        self.typeText.setTitle( self.typeText.titleOfSelectedItem! )
    }

}
