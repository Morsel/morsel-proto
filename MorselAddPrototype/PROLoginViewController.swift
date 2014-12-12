//
//  PROLoginViewController.swift
//  MorselAddPrototype
//
//  Created by Marty Trzpit on 1/5/15.
//  Copyright (c) 2015 Morsel. All rights reserved.
//

import UIKit

class PROLoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var loginTextField: UITextField? = nil
    @IBOutlet weak var passwordTextField: UITextField? = nil
    @IBOutlet weak var loginButton: UIButton? = nil

    let dataManager: PRODataManager = PRODataManager.sharedInstance
    var appViewController: UIViewController {
        get {
            var appVC = storyboard?.instantiateViewControllerWithIdentifier("tabBarController") as UIViewController
            appVC.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
            return appVC
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loginTextField?.text = nil
        passwordTextField?.text = nil
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if dataManager.currentUser != nil {
            presentViewController(appViewController, animated: false, completion: nil)
        } else {
            loginTextField?.becomeFirstResponder()
        }
    }
    
    @IBAction func login(sender: UIButton) {
        if loginTextField!.text.isEmpty || passwordTextField!.text.isEmpty {
            Util.showOkAlertWithTitle("Empty Fields!", message: "Please fill in both fields")
            return
        }

        sender.pro_disable(true)
        request(Method.POST, kAPIURL + "/users/sign_in.json",
            parameters: [
                "client[device]": "proto",
                "user[login]": loginTextField!.text,
                "user[password]": passwordTextField!.text
            ]).responseJSON { (request, response, json, error) in
                if error != nil {
                    Util.showOkAlertWithTitle("Error!", message: "\(error?.localizedDescription)")
                } else if json!.valueForKey("errors") != nil {
                    Util.showOkAlertWithTitle("Error!", message: "Invalid Login")
                } else {
                    self.dataManager.importCurrentUser(json!.valueForKey("data") as? NSDictionary)
                    self.presentViewController(self.appViewController, animated: true, completion: nil)
                }

                sender.pro_disable(false)
        }
    }


    // MARK: UITextFieldDelegate

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            if textField == loginTextField {
                passwordTextField?.becomeFirstResponder()
            } else {
                view.endEditing(true)
                login(loginButton!)
            }
            return false
        }
        return true
    }
}
