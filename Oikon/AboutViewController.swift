//
//  AboutViewController.swift
//  Oikon
//
//  Created by Bruno Bernardino on 09/07/15.
//  Copyright © 2015 emotionLoop. All rights reserved.
//

import Cocoa

class AboutViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
        
    // Open oikon website
    @IBAction func openWebsite( sender: AnyObject? ) {
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: "http://oikon.us")!)
    }
    
    // Open support email
    @IBAction func openSupportEmail( sender: AnyObject? ) {
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: "mailto:hello@emotionloop.com")!)
    }
}

