//
//  PROUser.swift
//  MorselAddPrototype
//
//  Created by Marty Trzpit on 12/30/14.
//  Copyright (c) 2014 Morsel. All rights reserved.
//

import UIKit

class PROUser: NSObject {
    var id: String?
    var username: String?
    var apiKey: String?

    class func createFromJSON(dictionary: NSDictionary?) -> PROUser {
        var user = PROUser()

        var idNumber = dictionary!["id"] as NSNumber
        user.id = "\(idNumber)"

        user.updateFromJSON(dictionary)

        return user
    }

    func updateFromJSON(dictionary: NSDictionary?) {
        if (dictionary!["username"] != nil && dictionary!["username"] as? NSNull != NSNull()) { username = (dictionary!["username"] as NSString) }
        if (dictionary!["auth_token"] != nil && dictionary!["auth_token"] as? NSNull != NSNull()) {
            var auth_token = dictionary!["auth_token"] as NSString
            apiKey = "\(id!):\(auth_token)"
        }
    }
}
