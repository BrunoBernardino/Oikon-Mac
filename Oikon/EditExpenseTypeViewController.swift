//
//  EditExpenseTypeViewController.swift
//  Oikon
//
//  Created by Bruno Bernardino on 06/07/15.
//  Copyright (c) 2015 emotionLoop. All rights reserved.
//

import Cocoa

class EditExpenseTypeViewController: NSViewController {
    
    var mainViewController: ExpenseTypesListViewController!
    var originalExpenseTypeName: NSString! = ""
    var originalExpenseTypeIndex: Int! = 0
    
    @IBOutlet var nameText: NSTextField!
    
    // Update expense type and update all the expenses with it
    @IBAction func updateExpenseType(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        
        let uncategorizedStringValue = NSLocalizedString("uncategorized", comment: "")
        
        // Set defaults
        var expenseTypeName: NSString = ""
        
        // Avoid empty values crashing the code
        if let tmpExpenseTypeName: NSString = self.nameText.stringValue as NSString? {
            expenseTypeName = tmpExpenseTypeName
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
        
        // Check if an expense type with that name already exists, and this name changed
        if ( expenseTypeName != originalExpenseTypeName && self.mainViewController.expenseTypeExists(expenseTypeName) ) {
            self.mainViewController.mainViewController.showAlert(NSLocalizedString("An expense type with the same name already exists.", comment:"") as NSString, window: self.mainViewController.view.window!)
            
            return;
        }
        
        //
        // END: Validate fields for common errors
        //
        
        //
        // Save object
        //
        
        let selectedExpenseType: NSManagedObject = self.mainViewController.expenseTypes.object(at: self.originalExpenseTypeIndex) as! NSManagedObject
        
        selectedExpenseType.setValue(expenseTypeName, forKey: "name")
        
        var error: NSError? = nil
        do {
            try context?.save()
        } catch let error1 as NSError {
            error = error1
        }
        
        if ( error == nil ) {
            // Refresh the table in the mainViewController
            self.mainViewController.getAllExpenseTypes()
            
            //self.mainViewController.mainViewController.showAlert(NSLocalizedString("Your expense type was updated successfully.", comment:""), window: self.mainViewController.view.window!)
        } else {
            NSLog("Error: %@", error!)
            
            self.mainViewController.mainViewController.showAlert(NSLocalizedString("There was an error updating your expense type. Please confirm the value types match.", comment:"") as NSString, window: self.mainViewController.view.window!)
        }
        
        // Update all expenses with that expense type
        let entityDesc = NSEntityDescription.entity(forEntityName: "Expense", in:context!)
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        request.entity = entityDesc
        
        // Add expense type name to update only the expenses that match it
        let filterNamePredicate: NSPredicate = NSPredicate(format: "(type = %@)", self.originalExpenseTypeName)
        request.predicate = filterNamePredicate
        
        var objects: [NSManagedObject]
        
        objects = (try! context!.fetch(request)) as! [NSManagedObject]
        
        if ( error == nil ) {
            for object: NSManagedObject in objects {
                object.setValue(self.nameText.stringValue, forKey: "type")
            }
            
            do {
                try context?.save()
            } catch let error1 as NSError {
                error = error1
            }
            
            // Refresh the table in the mainViewController
            self.mainViewController.getAllExpenseTypes()
        } else {
            NSLog("Error: %@", error!)
        }
        
        // Close popover
        self.dismissViewController(self)

    }
    
    // Delete expense type and remove it from all expenses with it
    @IBAction func deleteExpenseType(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        let expenseTypeToRemove: NSManagedObject = self.mainViewController.expenseTypes.object( at: self.originalExpenseTypeIndex ) as! NSManagedObject
        
        let buttonPressed = self.mainViewController.mainViewController.showConfirm( NSLocalizedString("Are you sure you want to delete this expense type?", comment: "") as NSString )
        
        // Confirmed!
        if buttonPressed == NSAlertSecondButtonReturn {
            // Delete from core data
            context?.delete(expenseTypeToRemove)
            
            var error: NSError? = nil
            do {
                try context?.save()
            } catch let error1 as NSError {
                error = error1
            }
            
            if ( error == nil ) {
                // Delete from view
                self.mainViewController.expenseTypes.removeObject(at: self.originalExpenseTypeIndex)
                
                // Refresh the table in the mainViewController
                self.mainViewController.getAllExpenseTypes()
            } else {
                NSLog("Error: %@", error!)
            }
            
            // Change all expenses with this expense type to nil
            let entityDesc = NSEntityDescription.entity(forEntityName: "Expense", in:context!)
            
            let request = NSFetchRequest<NSFetchRequestResult>()
            request.entity = entityDesc
            
            // Add expense type name to update only the expenses that match it
            let filterNamePredicate: NSPredicate = NSPredicate(format: "(type = %@)", self.nameText.stringValue)
            request.predicate = filterNamePredicate
            
            var objects: [NSManagedObject]
            
            objects = (try! context!.fetch(request)) as! [NSManagedObject]
            
            if ( error == nil ) {
                for object: NSManagedObject in objects {
                    object.setValue(nil, forKey: "type")
                }
                
                do {
                    try context?.save()
                } catch let error1 as NSError {
                    error = error1
                }
                
                // Refresh the table in the mainViewController
                self.mainViewController.getAllExpenseTypes()
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
        
        self.nameText.stringValue = self.originalExpenseTypeName as String!
    }
    
    override func viewWillAppear() {
    }
    
}
