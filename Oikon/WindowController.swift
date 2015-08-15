//
//  WindowController.swift
//  Oikon
//
//  Created by Bruno Bernardino on 09/07/15.
//  Copyright © 2015 emotionLoop. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        
        NSLog("Window loaded!")

        // Unify title bar
        self.window!.titleVisibility = NSWindowTitleVisibility.Hidden
        self.window!.titlebarAppearsTransparent = true
    }
}