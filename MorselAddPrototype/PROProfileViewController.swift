//
//  PROProfileViewController.swift
//  MorselAddPrototype
//
//  Created by Marty Trzpit on 1/2/15.
//  Copyright (c) 2015 Morsel. All rights reserved.
//

import UIKit

class PROProfileViewController: UIViewController {
    let dataManager: PRODataManager = PRODataManager.sharedInstance
    @IBOutlet weak var usernameLabel: UILabel? = nil

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        dataManager.mixpanel.track("Viewed Profile")

        usernameLabel?.text = "Logged in as: \(dataManager.currentUser!.username!)"
    }

    @IBAction func logout(sender: UIButton) {
        dataManager.mixpanel.track("Tapped Logout")
        dataManager.reset()
        sender.pro_disable(true)

        tabBarController!.presentingViewController!.dismissViewControllerAnimated(true,
            completion: { () -> Void in
                sender.pro_disable(false)
        })
    }
}
