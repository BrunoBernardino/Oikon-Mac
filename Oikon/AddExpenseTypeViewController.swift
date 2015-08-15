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
    @IBAction func addExpenseType(sender: AnyObject) {
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let uncategorizedStringValue = NSLocalizedString("uncategorized", comment: "")
        
        // Set defaults
        var expenseTypeName: NSString = ""
        
        // Avoid empty values crashing the code
        if let tmpExpenseTypeName: NSString? = self.nameText?.stringValue {
            expenseTypeName = tmpExpenseTypeName!
        }
        
        //NSLog("%@", expenseTypeName)
        
        //
        // START: Validate fields for common errors
        //
        
        // Check if the expense type name is not empty
        if ( expenseTypeName.length <= 0 ) {
            self.mainViewController.mainViewController.showAlert(NSLocalizedString("Please confirm the name of the expense type.", comment:""), window: self.mainViewController.view.window!)
            
            return;
        }
        
        // Check if the expense type name is "uncategorized" (case insensitive, not allowed)
        if ( expenseTypeName.compare(uncategorizedStringValue) == NSComparisonResult.OrderedSame ) {
            self.mainViewController.mainViewController.showAlert(NSLocalizedString("Your expense type can't be called 'uncategorized'.", comment:""), window: self.mainViewController.view.window!)

            return;
        }
        
        // Check if an expense type with that name already exists
        if ( self.mainViewController.expenseTypeExists(expenseTypeName) ) {
            self.mainViewController.mainViewController.showAlert(NSLocalizedString("An expense type with the same name already exists.", comment:""), window: self.mainViewController.view.window!)
            
            return;
        }
        
        //
        // END: Validate fields for common errors
        //
        
        //
        // Save object
        //
        
        let newExpenseType: NSManagedObject = NSEntityDescription.insertNewObjectForEntityForName("ExpenseType", inManagedObjectContext: context!) as! NSManagedObject

        newExpenseType.setValue(expenseTypeName, forKey: "name")
        
        var error: NSError? = nil
        context?.save(&error)
        
        if ( error == nil ) {
            // Cleanup field
            self.nameText.stringValue = ""
            
            // Refresh the table in the mainViewController
            self.mainViewController.getAllExpenseTypes()
            
            //self.mainViewController.mainViewController.showAlert(NSLocalizedString("Your expense type was added successfully.", comment:""), window: self.mainViewController.view.window!)
        } else {
            NSLog("Error: %@", error!)
            
            self.mainViewController.mainViewController.showAlert(NSLocalizedString("There was an error adding your expense type. Please confirm the value types match.", comment:""), window: self.mainViewController.view.window!)
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
