//
//  SettingsViewController.swift
//  Oikon
//
//  Created by Bruno Bernardino on 08/07/15.
//  Copyright (c) 2015 emotionLoop. All rights reserved.
//

import Cocoa

class SettingsViewController: NSViewController {
    
    var mainViewController: ViewController!
    
    var settings: UserDefaults!
    
    var lastiCloudFetch: Date?
    
    @IBOutlet weak var lastSyncLabel: NSTextField!
    @IBOutlet weak var iCloudSwitch: NSButton!
    
    // Remove all data
    @IBAction func removeAllData(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        
        let buttonPressed = self.mainViewController.showConfirm( NSLocalizedString("This will remove all local & iCloud data, including expenses, and expense types", comment: "") as NSString )
        
        // Confirmed!
        if buttonPressed == NSAlertSecondButtonReturn {
            appDelegate.removeAllData()
        }
    }

    // Toggle iCloud sync
    @IBAction func toggleiCloudSync(_ sender: AnyObject) {
        let appDelegate = NSApplication.shared().delegate as! AppDelegate
        let checkbox: NSButton = sender as! NSButton
        
        self.updateSettings()
        
        if ( checkbox.state == NSOnState ) {
            appDelegate.migrateDataToiCloud()
        } else {
            appDelegate.migrateDataToLocal()
        }
        
        self.fetchSettings()
    }
    
    // Fetch settings
    func fetchSettings() {
        self.settings = UserDefaults.standard
        self.settings.synchronize()
        
        NSLog("%@", self.settings.object(forKey: "iCloud.osx") as! NSMutableDictionary)
        
        let iCloudSettings: NSMutableDictionary = self.settings.object(forKey: "iCloud.osx") as! NSMutableDictionary
        let isiCloudEnabled: Bool = iCloudSettings.value(forKey: "isEnabled") as! Bool
        let lastSync: Date? = iCloudSettings.value(forKey: "lastSuccessfulSync") as? Date
        
        // Update checkbox
        if ( isiCloudEnabled == true ) {
            self.iCloudSwitch.state = NSOnState
        } else {
            self.iCloudSwitch.state = NSOffState
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = DateFormatter.Style.short
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // Update label
        if ( lastSync != nil ) {
            self.lastSyncLabel.stringValue = dateFormatter.string(from: lastSync!)
        } else {
            self.lastSyncLabel.stringValue = NSLocalizedString("N/A", comment:"")
        }
    }
    
    // Update settings
    func updateSettings() {
        self.settings = UserDefaults.standard
        self.settings.synchronize()
        
        let iCloudSettings: NSMutableDictionary = (self.settings.object(forKey: "iCloud.osx") as! NSDictionary!).mutableCopy() as! NSMutableDictionary
        var isiCloudEnabled: Bool = false
        
        // Update checkbox status
        if ( self.iCloudSwitch.state == NSOnState ) {
            isiCloudEnabled = true
        }

        iCloudSettings.setValue(isiCloudEnabled, forKey: "isEnabled")
        
        self.settings.set(iCloudSettings, forKey: "iCloud.osx")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // Listen for iCloud changes (after it's done)
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsViewController.iCloudDidUpdate(_:)), name: NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange, object: nil)
    }
    
    override func viewWillAppear() {
        self.fetchSettings()
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
            self.fetchSettings()
        }*/
    }

}
