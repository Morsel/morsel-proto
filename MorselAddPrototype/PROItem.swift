//
//  PROItem.swift
//  MorselAddPrototype
//
//  Created by Marty Trzpit on 12/12/14.
//  Copyright (c) 2014 Morsel. All rights reserved.
//

import UIKit

class PROItem: NSObject {
    var id: String? = nil
    var text: String? = nil
    var sortOrder: NSNumber = 0
    var cleanText: String? = nil
    var photoURL: String? = nil
    var presignedUploadDictionary: NSDictionary? = nil
    var nonce: String? = nil
    var photoImage: UIImage? = nil
    var cellHeight: CGFloat = 420.0

    override init() {
        super.init()
        self.nonce = NSUUID().UUIDString
    }

    init(id: String, text: String?, photoURL: String?) {
        self.id = id
        self.text = text
        self.photoURL = photoURL
        self.nonce = NSUUID().UUIDString
    }

    init(id: String, text: String?, photoImage: UIImage?) {
        self.id = id
        self.text = text
        self.photoImage = photoImage
        self.nonce = NSUUID().UUIDString
    }

    class func createFromJSON(dictionary: NSDictionary?) -> PROItem {
        var idNumber = dictionary!["id"] as NSNumber

        var item = PROItem()
        item.id = "\(idNumber)"

        item.updateFromJSON(dictionary)

        return item
    }

    func updateFromJSON(dictionary: NSDictionary?) {
        if (dictionary!["description"] != nil && dictionary!["description"] as? NSNull != NSNull()) { text = (dictionary!["description"] as NSString) }

        if (dictionary!["photos"] != nil && dictionary!["photos"] as? NSNull != NSNull()) {
            var photosJson = dictionary!["photos"] as NSDictionary
            photoURL = photosJson["_320x320"] as NSString
        }

        if (dictionary!["sort_order"] != nil && dictionary!["sort_order"] as? NSNull != NSNull()) { sortOrder = (dictionary!["sort_order"] as NSNumber) }

        if (dictionary!["presigned_upload"] != nil && dictionary!["presigned_upload"] as? NSNull != NSNull()) { presignedUploadDictionary = (dictionary!["presigned_upload"] as NSDictionary) }

        cleanText = text
    }
}
