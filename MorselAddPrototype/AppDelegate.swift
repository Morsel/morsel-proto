//
//  AppDelegate.swift
//  MorselAddPrototype
//
//  Created by Marty Trzpit on 12/11/14.
//  Copyright (c) 2014 Morsel. All rights reserved.
//

import UIKit

#if DEBUG
let kAPIURL = "https://api-staging.eatmorsel.com"
#else
let kAPIURL = "https://api.eatmorsel.com"
#endif

let kWEBAPIURL = "https://morsel-webapi.herokuapp.com"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        setupAppearance()
        if NSUserDefaults.standardUserDefaults().objectForKey("displayedWhatsNew") == nil {
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
                , dispatch_get_main_queue(), {
                    Util.showOkAlertWithTitle("What's New in this Version", message:
                        "- Import multiple photos from Photo Library by selecting more than one"
                            + "\n\n- Want to change the cover photo? Just tap the 'i' over the photo"
                            + "\n\n\n- NOTE: Photo editing features will come back in the final version"
                    )
            })

            NSUserDefaults.standardUserDefaults().setObject(true, forKey: "displayedWhatsNew")
            NSUserDefaults.standardUserDefaults().synchronize()
        }


        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    func setupAppearance() {
        var navBarColor = UIColor(red: 0.976470588, green: 0.968627451, blue: 0.968627451, alpha: 1.0)
        if UINavigationBar.respondsToSelector(Selector("appearance")) {
            UINavigationBar.appearance().barTintColor = navBarColor
            UINavigationBar.appearance().setBackgroundImage(imageWithColor(navBarColor), forBarMetrics: UIBarMetrics.Default)
            UINavigationBar.appearance().backgroundColor = navBarColor
        }
        UITableViewHeaderFooterView.appearance().tintColor = navBarColor
    }

    func imageWithColor(color : UIColor) -> UIImage {
        var rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        var context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)

        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}

extension UIButton {
    func pro_disable(shouldDisable: Bool) {
        enabled = !shouldDisable
        alpha = shouldDisable ? 0.5 : 1.0
    }
}

extension UIColor {
    class func randomColor() -> UIColor {
        return self(
            hue: mt_randomNormal(nil),
            saturation: mt_randomNormal(0.5),
            brightness: mt_randomNormal(0.5),
            alpha: 1
        )
    }

    //  Return a cgfloat from 0.0 -> 1.0, + offset
    private class func mt_randomNormal(offset : CGFloat?) -> CGFloat {
        return min(CGFloat(Float(arc4random()) / Float(UINT32_MAX)) + (offset ?? 0.0), 1.0)
    }
}

extension UINavigationItem {
    func pro_disableButtons(shouldDisable: Bool) {
        leftBarButtonItem?.enabled = !shouldDisable
        rightBarButtonItem?.enabled = !shouldDisable
    }
}

class Util {
    class func clamp<T: Comparable>(a: T, min: T, max: T) -> T {
        return Swift.max(min, Swift.min(max, a))
    }

    class func showOkAlertWithTitle(title: String, message: String) {
        var alertView = UIAlertView(
            title: title,
            message: message,
            delegate: nil,
            cancelButtonTitle: "Ok"
        )
        
        alertView.show()
    }
}
