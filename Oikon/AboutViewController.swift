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
    @IBAction func openWebsite( _ sender: AnyObject? ) {
        NSWorkspace.shared().open(URL(string: "https://oikon.net")!)
    }
    
    // Open support email
    @IBAction func openSupportEmail( _ sender: AnyObject? ) {
        NSWorkspace.shared().open(URL(string: "mailto:hello@emotionloop.com")!)
    }
}

