//
//  PRODataManager.swift
//  MorselAddPrototype
//
//  Created by Marty Trzpit on 12/12/14.
//  Copyright (c) 2014 Morsel. All rights reserved.
//

import Foundation

private let _DataManagerSharedInstance = PRODataManager()

class PRODataManager: NSObject {
    class var sharedInstance: PRODataManager {
        return _DataManagerSharedInstance
    }

    var morsels: [PROMorsel] = [PROMorsel]()
    var sortedMorsels: [PROMorsel] {
        get {
            return morsels.sorted({ (a, b) -> Bool in
                b.updatedAtDate!.isEarlierThan(a.updatedAtDate)
            })
        }
    }
    var currentUser: PROUser? = nil
    var defaultDateFormatter: NSDateFormatter = NSDateFormatter()
    var isPublishing: Bool = false
    var mixpanel = Mixpanel.sharedInstanceWithToken("823ff7e87c6ac2775ffa2e8e1c419f67")

    override init () {
        super.init()
        defaultDateFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
        defaultDateFormatter.dateFormat = "yyyy-MM-dd'T'H:mm:ss.SSS'Z'"
        Rollbar.initWithAccessToken("fcd9041c48484862ad4ca2023ec3a855")

        if NSUserDefaults.standardUserDefaults().objectForKey("currentUser.id") != nil {
            currentUser = PROUser()
            currentUser?.id = NSUserDefaults.standardUserDefaults().objectForKey("currentUser.id") as NSString
            currentUser?.username = NSUserDefaults.standardUserDefaults().objectForKey("currentUser.username") as NSString
            currentUser?.apiKey = NSUserDefaults.standardUserDefaults().objectForKey("currentUser.apiKey") as NSString

            Rollbar.currentConfiguration().setPersonId(currentUser!.id!, username: currentUser!.username!, email: nil)
            mixpanel.registerSuperProperties([
                "user_id": currentUser!.id!,
                "user_username": currentUser!.username!
            ])
            mixpanel.identify(currentUser!.id!)
        }
    }

    func reset() {
        currentUser = nil
        deleteAllMorsels()

        NSUserDefaults.standardUserDefaults().setPersistentDomain(NSDictionary(), forName: NSBundle.mainBundle().bundleIdentifier!)
        NSUserDefaults.standardUserDefaults().synchronize()

        Rollbar.currentConfiguration().setPersonId(nil, username: nil, email: nil)
        mixpanel.registerSuperProperties(nil)
        mixpanel.identify(nil)
    }

    func morselsArePublishing() -> Bool {
        var publishing: Bool = false

        for morsel in morsels {
            if morsel.isPublishing {
                publishing = true
                break
            }
        }

        return publishing
    }

    func createMorsel() -> PROMorsel {
        var morsel = PROMorsel()
        morsels.append(morsel)
        return morsel
    }

    func importMorsel(dictionary: NSDictionary?) -> PROMorsel {
        var idNumber = dictionary!["id"] as NSNumber

        var morsel = findMorsel("\(idNumber)")
        if morsel != nil {
            morsel?.updateFromJSON(dictionary)
        } else {
            morsel = PROMorsel.createFromJSON(dictionary)
        }

        morsels.append(morsel!)
        return morsel!
    }

    func importMorsels(morselsJson: [NSDictionary]) {
        for (morselDictionary: NSDictionary) in morselsJson {
            var creatorIDNumber = morselDictionary["creator_id"] as NSNumber
            //  Don't import morsels you're tagged in
            if "\(creatorIDNumber)" == currentUser?.id {
                importMorsel(morselDictionary)
            }
        }
    }

    func importItem(dictionary: NSDictionary?, morsel: PROMorsel) -> PROItem {
        var idNumber = dictionary!["id"] as NSNumber

        var item = findItem("\(idNumber)", morsel: morsel)
        if item != nil {
            item?.updateFromJSON(dictionary)
        } else {
            item = PROItem.createFromJSON(dictionary)
        }

        morsel.items.append(item!)
        return item!
    }

    func importCurrentUser(dictionary: NSDictionary?) -> PROUser {
        currentUser = PROUser.createFromJSON(dictionary)
        NSUserDefaults.standardUserDefaults().setObject(currentUser!.id!, forKey: "currentUser.id")
        NSUserDefaults.standardUserDefaults().setObject(currentUser!.username!, forKey: "currentUser.username")
        NSUserDefaults.standardUserDefaults().setObject(currentUser!.apiKey!, forKey: "currentUser.apiKey")
        NSUserDefaults.standardUserDefaults().synchronize()

        Rollbar.currentConfiguration().setPersonId(currentUser!.id!, username: currentUser!.username!, email: nil)
        mixpanel.registerSuperProperties([
            "user_id": currentUser!.id!,
            "user_username": currentUser!.username!
            ])
        mixpanel.identify(currentUser!.id!)
        
        return currentUser!
    }

    func morselCount() -> Int {
        return morsels.count
    }

    func findMorsel(morselID: String) -> PROMorsel? {
        if morselCount() == 0 { return nil }

        var results =  morsels.filter { (morsel) -> Bool in
            return morsel.id == morselID
        }

        return results.count > 0 ? results.first : nil
    }

    func deleteAllMorsels() {
        morsels.removeAll(keepCapacity: false)
    }

    func findItem(itemID: String, morsel: PROMorsel) -> PROItem? {
        let items = morsel.items
        if items.count == 0 { return nil }

        var results =  items.filter { (item) -> Bool in
            return item.id == itemID
        }

        return results.count > 0 ? results.first : nil
    }

    func appendRandomItemToMorsel(morselID: String, image: UIImage) -> PROItem {
        var nextID = itemCountForMorsel(morselID) + 1
        var item = PROItem(id: "\(nextID)", text: nil, photoImage: image)
        findMorsel(morselID)!.items.append(item)

        return item
    }

    func removeItemFromMorsel(item: PROItem, morsel: PROMorsel) {
        var index: Int?

        for(idx, _item) in enumerate(morsel.items) {
            if item == _item {
                index = idx
                break
            }
        }

        if (index != nil) {
            morsel.items.removeAtIndex(index!)
        }
    }

    func itemsForMorsel(morselID: String) -> [PROItem] {
        return findMorsel(morselID)!.items
    }

    func itemCountForMorsel(morselID: String?) -> Int {
        if morselID == nil { return 0 }
        return itemsForMorsel(morselID!).count
    }
}
