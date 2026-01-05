//
//  CustomLayoutsTabViewController.swift
//  Rectangle
//
//  Created by Rectangle on 1/2/26.
//  Copyright © 2026 Ryan Hanson. All rights reserved.
//

import Cocoa
import SwiftUI

class CustomLayoutsTabViewController: NSViewController {

    override func loadView() {
        // Create SwiftUI hosting controller
        let hostingController = NSHostingController(rootView: LayoutManagerView())

        // Set up the view
        self.view = hostingController.view

        // Add hosting controller as child
        addChild(hostingController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
