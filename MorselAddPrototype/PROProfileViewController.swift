//
//  PROProfileViewController.swift
//  MorselAddPrototype
//
//  Created by Marty Trzpit on 1/2/15.
//  Copyright (c) 2015 Morsel. All rights reserved.
//

import UIKit
import MessageUI

class PROProfileViewController: UIViewController, MFMailComposeViewControllerDelegate {
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

    @IBAction func sendFeedback(sender: UIButton) {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }

    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self

        mailComposerVC.setToRecipients(["kris@eatmorsel.com"])
        mailComposerVC.setSubject("Morsel Prototype Feedback")

        return mailComposerVC
    }

    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }

    // MARK: - MFMailCompseViewControllerDelegate

    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
