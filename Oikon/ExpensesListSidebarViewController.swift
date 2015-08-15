//
//  ExpensesListSidebarViewController.swift
//  Oikon
//
//  Created by Bruno Bernardino on 13/06/15.
//  Copyright (c) 2015 emotionLoop. All rights reserved.
//

import Cocoa

class ExpensesListSidebarViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    // Set default expense types array
    var selectedExpenseTypeNames: NSMutableArray! = []
    let uncategorizedStringValue = NSLocalizedString("uncategorized", comment: "")
    
    var listViewController: ExpensesListViewController!
    var mainViewController: ViewController!
    
    var lastiCloudFetch: NSDate?

    @IBOutlet var totalText: NSTextField!
    @IBOutlet var searchText: NSSearchField!

    @IBOutlet weak var expenseTypesTableView: NSTableView!
    
    @IBAction func enteredSearchText(sender: AnyObject) {
        // Update filter
        self.listViewController.currentFilterName = searchText.stringValue
        
        // Get filtered expenses
        self.listViewController.getAllExpenses()
    }
    
    // Action clicking on checkbox
    @IBAction func checkboxStateChanged(sender: NSButton!) {
        let isRemoving: Bool = ( sender.state == NSOffState )
        let expenseTypeIndex = sender.tag - 1
        let expenseTypeName: String = self.listViewController.expenseTypes.objectAtIndex(expenseTypeIndex).valueForKey("name") as! String
        
        /*NSLog("INDEX = %d", expenseTypeIndex)
        if ( isRemoving ) {
            NSLog("IS REMOVING %@", expenseTypeName)
        } else {
            NSLog("IS ADDING %@", expenseTypeName)
        }*/
        
        // If the array is empty and we're removing something, add everything to the selected array
        if ( self.selectedExpenseTypeNames.count == 0 && isRemoving ) {
            //NSLog("ADDING EVERYTHING TO ARRAY")
            for expenseType in self.listViewController.expenseTypes {
                self.selectedExpenseTypeNames.addObject(expenseType.valueForKey("name")!)
            }
        }
        
        let foundIndex = self.selectedExpenseTypeNames.indexOfObject(expenseTypeName)
        
        //NSLog("FOUND INDEX = %d", foundIndex)
        
        // If we're removing, do it
        if ( isRemoving ) {
            self.selectedExpenseTypeNames.removeObjectAtIndex(foundIndex)
        } else {
            if ( foundIndex != NSNotFound ) {
                // It's already there, do nothing!?
                NSLog("WARNING: Trying to add an expense type to filters, when it's already there. This should not happen!!")
            } else {
                self.selectedExpenseTypeNames.addObject(expenseTypeName)
            }
        }
        
        // If the number of selected expense types is the same as the expense types, remove everything from the array.
        if ( self.selectedExpenseTypeNames.count == self.listViewController.expenseTypes.count ) {
            self.selectedExpenseTypeNames.removeAllObjects()
        }
        
        //NSLog("%@", self.selectedExpenseTypeNames)
        
        // Update filter
        self.listViewController.currentFilterTypes = NSMutableArray(array: self.selectedExpenseTypeNames)
        
        // Get filtered expenses
        self.listViewController.getAllExpenses()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // Listen for iCloud changes (after it's done)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "iCloudDidUpdate:", name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: nil)
        
        // Make sure the table loads data from and listens to this controller
        expenseTypesTableView.setDelegate(self)
        expenseTypesTableView.setDataSource(self)
        
        self.selectedExpenseTypeNames = NSMutableArray(array: self.listViewController.currentFilterTypes)
        
        // Fetch expense types
        self.listViewController.getAllExpenseTypes()
        
        // Reload view with new data
        self.expenseTypesTableView.reloadData()
    }
    
    override func viewWillAppear() {
    }
    
    // Calculate and show total for all found expenses
    func calculateAndShowTotal( expenses:NSMutableArray ) {
        var expensesTotal: Double = 0;
    
        for expense: AnyObject in expenses {
            expensesTotal += expense.valueForKey("value") as! Double
        }
        
        let numberFormatter = NSNumberFormatter()
        numberFormatter.locale = NSLocale.currentLocale()
        numberFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
    
        let formattedTotal:String = numberFormatter.stringFromNumber(NSNumber(double: expensesTotal))!
        
        //NSLog("Calculating total = %@", formattedTotal)
        
        // The object might not be ready/assigned yet
        if ( self.totalText != nil ) {
            self.totalText.stringValue = formattedTotal
        }
    }
    
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        let numberOfRows:Int = self.listViewController.expenseTypes.count
        return numberOfRows
    }
    
    // Format & Display Row Cells
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cellIdentifier = NSString(format: "%@Cell", tableColumn!.identifier) as String!
        
        let result: NSTableCellView = self.expenseTypesTableView.makeViewWithIdentifier(cellIdentifier, owner: self.expenseTypesTableView) as! NSTableCellView
        
        var stringValue: NSString!
        
        // Format checkbox
        if ( tableColumn!.identifier == "checked" ) {
            let checkboxView = result.subviews[0] as! NSButton

            let expenseTypeName = self.listViewController.expenseTypes.objectAtIndex(row).valueForKey("name") as! NSString
            
            // Set tag so we can "find it" after, when clicking on it
            checkboxView.tag = row + 1
            
            // If there's nothing selected, everything is ON
            if ( self.selectedExpenseTypeNames.count == 0 ) {
                checkboxView.state = NSOnState
            } else {
                if ( self.selectedExpenseTypeNames.containsObject(expenseTypeName) ) {
                    checkboxView.state = NSOnState
                } else {
                    checkboxView.state = NSOffState
                }
            }
            
            return result
        }
        
        // Format Count
        if ( tableColumn!.identifier == "count" ) {
            let numberOfExpenses = self.listViewController.getExpenseTypeSum( self.listViewController.expenseTypes.objectAtIndex(row).valueForKey("name") as! NSString ) as Float
            let numberFormatter = NSNumberFormatter()
            numberFormatter.locale = NSLocale.currentLocale()
            numberFormatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
            
            stringValue = numberFormatter.stringFromNumber(numberOfExpenses)
        } else {
            // Format Name
            stringValue = self.listViewController.expenseTypes.objectAtIndex( row ).valueForKey( tableColumn!.identifier ) as! NSString!
        }
        
        result.textField!.stringValue = stringValue as String
        
        return result
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
            self.expenseTypesTableView.reloadData()
        }*/
    }

}
