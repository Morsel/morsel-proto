//
//  PROMorsel.swift
//  MorselAddPrototype
//
//  Created by Marty Trzpit on 12/12/14.
//  Copyright (c) 2014 Morsel. All rights reserved.
//

import Foundation

class PROMorsel: NSObject {
    let dataManager: PRODataManager = PRODataManager.sharedInstance

    var id: String? = nil
    var title: String? = nil
    var cleanTitle: String? = nil
    var primaryItemID: String? = nil

    var items: [PROItem] = []
    var sortedItems: [PROItem] {
        get {
            return items.sorted({ (a, b) -> Bool in
                b.sortOrder.integerValue > a.sortOrder.integerValue
            })
        }
    }
    var isDraft: Bool = true
    var isPublishing: Bool = false
    var updatedAtDate: NSDate? = nil

    class func createFromJSON(dictionary: NSDictionary?) -> PROMorsel {
        var morsel = PROMorsel()

        var idNumber = dictionary!["id"] as NSNumber
        morsel.id = "\(idNumber)"

        morsel.updateFromJSON(dictionary)

        if (dictionary!["items"] != nil && dictionary!["items"] as? NSNull != NSNull()) {
            for (itemDictionary: NSDictionary) in dictionary!["items"] as [NSDictionary] {
                var item = PROItem.createFromJSON(itemDictionary)
                morsel.items.append(item)
            }
        }

        if morsel.primaryItemID == nil {
            morsel.primaryItemID = morsel.lastItemID()
        }

        return morsel
    }

    func updateFromJSON(dictionary: NSDictionary?) {
        if (dictionary!["title"] != nil && dictionary!["title"] as? NSNull != NSNull()) { title = (dictionary!["title"] as NSString) }
        if (dictionary!["draft"] != nil && dictionary!["draft"] as? NSNull != NSNull()) {
            isDraft = (dictionary!["draft"] as Bool)
        } else if (dictionary!["published_at"] != nil && dictionary!["published_at"] as? NSNull != NSNull()) {
            isDraft = false
        }

        if (dictionary!["publishing"] != nil && dictionary!["publishing"] as? NSNull != NSNull()) {
            isPublishing = (dictionary!["publishing"] as Bool)
        }

        if (dictionary!["updated_at"] != nil && dictionary!["updated_at"] as? NSNull != NSNull()) {
            updatedAtDate = dataManager.defaultDateFormatter.dateFromString((dictionary!["updated_at"] as NSString))
        }

        if (dictionary!["primary_item_id"] != nil && dictionary!["primary_item_id"] as? NSNull != NSNull()) {
            var primaryItemIDNumber = dictionary!["primary_item_id"] as NSNumber
            primaryItemID = "\(primaryItemIDNumber)"
        }

        cleanTitle = title
    }

    func lastItemID() -> String? {
        return sortedItems.count > 0 ? sortedItems.last!.id! : nil
    }

    func lastItemOrPrimaryItemID() -> String {
        var lastID: String? = lastItemID()
        return lastID != nil ? lastID! : primaryItemID!
    }

    func status() -> String? {
        if isPublishing {
            return "PUBLISHING"
        } else if isDraft {
            return "DRAFT"
        } else {
            return nil
        }
    }
}
