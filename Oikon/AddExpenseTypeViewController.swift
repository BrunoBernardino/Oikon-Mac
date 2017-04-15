//
//  AddExpenseTypeViewController.swift
//  Oikon
//
//  Created by Bruno Bernardino on 20/06/15.
//  Copyright (c) 2015 emotionLoop. All rights reserved.
//

import Cocoa

class AddExpenseTypeViewController: NSViewController {
    
    var mainViewController: ExpenseTypesListViewController!

    @IBOutlet var nameText: NSTextField!
    
    // Add expense type
    @IBAction func addExpenseType(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let uncategorizedStringValue = NSLocalizedString("uncategorized", comment: "")
        
        // Set defaults
        var expenseTypeName: NSString = ""
        
        // Avoid empty values crashing the code
        if let tmpExpenseTypeName: NSString? = self.nameText?.stringValue as NSString? {
            expenseTypeName = tmpExpenseTypeName!
        }
        
        //NSLog("%@", expenseTypeName)
        
        //
        // START: Validate fields for common errors
        //
        
        // Check if the expense type name is not empty
        if ( expenseTypeName.length <= 0 ) {
            self.mainViewController.mainViewController.showAlert(NSLocalizedString("Please confirm the name of the expense type.", comment:"") as NSString, window: self.mainViewController.view.window!)
            
            return;
        }
        
        // Check if the expense type name is "uncategorized" (case insensitive, not allowed)
        if ( expenseTypeName.compare(uncategorizedStringValue) == ComparisonResult.orderedSame ) {
            self.mainViewController.mainViewController.showAlert(NSLocalizedString("Your expense type can't be called 'uncategorized'.", comment:"") as NSString, window: self.mainViewController.view.window!)

            return;
        }
        
        // Check if an expense type with that name already exists
        if ( self.mainViewController.expenseTypeExists(expenseTypeName) ) {
            self.mainViewController.mainViewController.showAlert(NSLocalizedString("An expense type with the same name already exists.", comment:"") as NSString, window: self.mainViewController.view.window!)
            
            return;
        }
        
        //
        // END: Validate fields for common errors
        //
        
        //
        // Save object
        //
        
        let newExpenseType: NSManagedObject = NSEntityDescription.insertNewObject(forEntityName: "ExpenseType", into: context!) 

        newExpenseType.setValue(expenseTypeName, forKey: "name")
        
        var error: NSError? = nil
        do {
            try context?.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        if ( error == nil ) {
            // Cleanup field
            self.nameText.stringValue = ""
            
            // Refresh the table in the mainViewController
            self.mainViewController.getAllExpenseTypes()
            
            //self.mainViewController.mainViewController.showAlert(NSLocalizedString("Your expense type was added successfully.", comment:""), window: self.mainViewController.view.window!)
        } else {
            NSLog("Error: %@", error!)
            
            self.mainViewController.mainViewController.showAlert(NSLocalizedString("There was an error adding your expense type. Please confirm the value types match.", comment:"") as NSString, window: self.mainViewController.view.window!)
        }
        
        // Close popover
        self.dismissViewController(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {
    }

}
