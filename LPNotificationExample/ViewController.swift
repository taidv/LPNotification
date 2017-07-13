//
//  ViewController.swift
//  LPNotificationExample
//
//  Created by Dinh Van Tai on 2017/07/13.
//  Copyright © 2017 Dinh Van Tai. All rights reserved.
//

import UIKit

class ViewController: UIViewController, LPNotificationDelegate {
    
    @IBOutlet weak var btnSend: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func touchBtnSend(_ sender: UIButton) {
        let p = LPNotification()
        p.delegate = self
        p.show("TESTS", message: "Test content")
        LPushManager.shared.push(p: p)
    }
    
    // MARK: - LPNotificationDelegate
    
    func pushTapHandler() {
        print("Push tapped")
    }
    
    func pushCompleteHandler() {
        print("Push completed")
        LPushManager.shared.clean()
    }
}

