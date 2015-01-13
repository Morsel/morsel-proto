//
//  PROManageMorselViewController.swift
//  MorselAddPrototype
//
//  Created by Marty Trzpit on 12/19/14.
//  Copyright (c) 2014 Morsel. All rights reserved.
//

import UIKit

let kDefaultTitleCellHeight: CGFloat = 60.0
let kTestImageNameA: String = "color-grid"
let kTestImageNameB: String = "test"

enum PROPosition: Int {
    case None
    case Top
    case Middle
    case Bottom
}

class PROManageMorselViewController: UIViewController,
    UITableViewDataSource,
    UITableViewDelegate,
    UIActionSheetDelegate,
    UIAlertViewDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate,
    CLImageEditorDelegate,
    PROInputAccessoryViewDelegate,
    ExpandableTableViewDelegate,
    RSKImageCropViewControllerDelegate {
    @IBOutlet weak var tableView: UITableView? = nil
    var alamofireManager: Manager? = nil

    var morsel: PROMorsel? = nil {
        didSet {
            updateUI()
        }
    }

    var updatingCounter: Int = 0
    var updating: Bool = false {
        didSet {
            titleViewLabel.hidden = false
            titleViewLabel.alpha = 1.0
            updatingCounter += updating ? 1 : -1
            if updatingCounter < 1 {
                if !isKeyboardActive { navigationItem.pro_disableButtons(false) }
                if morsel?.updatedAtDate == nil {
                    titleViewLabel.hidden = true
                } else {
                    if isViewLoaded() && view.window != nil {
                        titleViewLabel.text = "Updated!"
                        UIView.animateWithDuration(1.0, animations: {
                            self.titleViewLabel.alpha = 0.0
                        })
                    }
                }
                titleActivityIndicatorView.stopAnimating()
            } else {
                titleViewLabel.text = "Updating..."
                titleActivityIndicatorView.startAnimating()
                if !isKeyboardActive { navigationItem.pro_disableButtons(true) }
            }
            titleViewLabel.sizeToFit()
            titleViewLabel.center = CGPointMake(titleViewLabel.center.x, titleActivityIndicatorView.center.y)
        }
    }
    var isKeyboardActive: Bool {
        get {
            return activeTextView != nil
        }
    }

    var dataManager: PRODataManager = PRODataManager.sharedInstance
    var newMorsel: Bool = false
    var originalImage: UIImage? = nil
    var keyboardInputAccessoryView: PROInputAccessoryView? = nil
    var titleCellHeight: CGFloat = kDefaultTitleCellHeight
    var titleViewLabel = UILabel()
    var titleActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    var addToExistingMorselTableHeaderView: UIView? = nil
    var defaultKeyboardHeight: CGFloat = CGFloat(0.0)
    var activeTextView: UITextView? = nil
    var viewAppeared: Bool = false
    var activeCell: PROTableViewCell? {
        get {
            if activeTextView == nil { return nil }

            return findCell(activeTextView)
        }
    }
    var activeCellIndexPath: NSIndexPath? {
        get {
            if activeTextView == nil { return nil }

            return tableView!.indexPathForRowAtPoint(activeCell!.center)
        }
    }

    var lastUpdatedAtDate: NSDate? = nil
    var tempImportedImageURL: String? = nil

    func findCell(view: UIView?) -> PROTableViewCell? {
        if view == nil {
            return nil
        } else if view!.isKindOfClass(PROTableViewCell) {
            return view as? PROTableViewCell
        } else {
            return findCell(view!.superview)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let defaultNotificationCenter = NSNotificationCenter.defaultCenter()
        defaultNotificationCenter.addObserver(self,
            selector: Selector("keyboardWillShow:"),
            name: UIKeyboardWillShowNotification,
            object: nil
        )
        
        defaultNotificationCenter.addObserver(self,
            selector: Selector("keyboardWillHide:"),
            name: UIKeyboardWillHideNotification,
            object: nil
        )
        
        defaultNotificationCenter.addObserver(self,
            selector: Selector("keyboardDidShow:"),
            name: UIKeyboardDidShowNotification,
            object: nil
        )

        addToExistingMorselTableHeaderView = tableView?.tableHeaderView

        var updatingTitleView = UIView(frame: CGRect(origin: CGPointZero, size: CGSize(width: 100.0, height: 40.0)))

        titleActivityIndicatorView.hidesWhenStopped = true
        updatingTitleView.addSubview(titleActivityIndicatorView)
        let offset: CGFloat = 20.0
        titleActivityIndicatorView.center = CGPointMake(CGRectGetMidX(titleActivityIndicatorView.frame) - offset, CGRectGetMidY(updatingTitleView.frame))

        titleViewLabel.font = UIFont.systemFontOfSize(14.0)
        updatingTitleView.addSubview(titleViewLabel)

        self.navigationItem.titleView = updatingTitleView
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if viewAppeared { return }

        dataManager.mixpanel.track("Viewed Morsel", properties: [
            "new_morsel": newMorsel
            ])

        if tableView?.dataSource == nil { tableView?.dataSource = self }
        
        if tableView?.delegate == nil { tableView?.delegate = self }
        
        alamofireManager = Manager(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        keyboardInputAccessoryView = PROInputAccessoryView.defaultInputAccessoryView(self)
        keyboardInputAccessoryView?.updatePosition(PROPosition.None)
        
        toggleTabBarHidden(true)
        updating = false
        updatingCounter = 0
        dataManager.isPublishing = false

        newMorsel = (morsel == nil)
        // Hide the 'Add to existing morsel' header if a morsel is passed in
        if newMorsel {
            apiCreateMorsel()

            titleCellHeight = kDefaultTitleCellHeight
            tableView?.tableHeaderView = nil
        } else {
            var titleCell: PROTableViewCell = tableView?.dequeueReusableCellWithIdentifier("editTitleCell") as PROTableViewCell
            titleCell.titleCell = true
            titleCell.textView?.text = morsel!.title
            titleCellHeight = CGFloat(titleCell.cellHeight!)
            tableView?.tableHeaderView = nil
        }

        updateUI()

        tableView?.reloadData()

        viewAppeared = true
    }

    func updateUI() {
        if morsel == nil {
            navigationItem.rightBarButtonItem?.title = ""
        } else {
            navigationItem.rightBarButtonItem?.title = "Publish Update"
        }
    }

    func toggleNavBarHidden(hidden: Bool) {
        UIApplication.sharedApplication().setStatusBarHidden(hidden, withAnimation: UIStatusBarAnimation.Slide)
        navigationController?.setNavigationBarHidden(hidden, animated: true)
    }

    func toggleTabBarHidden(hidden: Bool) {
        var transitionView: UIView? = view.subviews.reverse().last as? UIView
        if (transitionView? == nil) { return }

        let tabBar = tabBarController?.tabBar
        let appDelegate = UIApplication.sharedApplication().delegate?

        var viewFrame = appDelegate?.window!?.frame
        var tabBarFrame = tabBar?.frame
        var containerFrame = transitionView?.frame
        var offset = (hidden ? 0 : tabBarFrame?.size.height)
        tabBarFrame?.origin.y = viewFrame!.size.height - offset!
        containerFrame?.size.height = viewFrame!.size.height - offset!

        UIView.animateWithDuration(0.3, animations: {
            tabBar?.frame = tabBarFrame!
            transitionView?.frame = containerFrame!
        })
    }

    func returnToMorsels() {
        viewAppeared = false

        toggleTabBarHidden(false)
        tableView?.dataSource = nil
        tableView?.delegate = nil

        alamofireManager!.session.invalidateAndCancel()
        view.endEditing(true)
        if tabBarController?.selectedIndex != 0 {
            tabBarController?.selectedIndex = 0
        }
        navigationController?.popToRootViewControllerAnimated(true)

        tempImportedImageURL = nil
        morsel = nil
    }

    func updateScrollPosition() {
        UIView.beginAnimations(nil, context: nil)

        if activeTextView != nil {
            var aRect: CGRect = self.view!.frame
            aRect.size.height -= defaultKeyboardHeight + 40.0
            let activeTextViewRect: CGRect? = view?.convertRect(activeTextView!.frame, fromView: activeTextView?.superview)

            if (!CGRectContainsRect(aRect, activeTextViewRect!)) {
                let butts = self.tableView?.convertRect(activeTextView!.frame, fromView: activeTextView?.superview)
                self.tableView?.scrollRectToVisible(CGRectOffset(butts!, 0.0, defaultKeyboardHeight + 40.0), animated:true)
            }
        }

        UIView.commitAnimations()
    }

    func cleanupMorsel() {
        if morsel == nil {
            returnToMorsels()
        } else {
            if newMorsel && morsel!.items.count == 0 && morsel!.title == nil {
                var index: Int?
                for (_index, _morsel) in enumerate(dataManager.morsels) {
                    if morsel! == _morsel {
                        index = _index
                    }
                }
                if (index != nil) { dataManager.morsels.removeAtIndex(index!) }
                apiDeleteMorsel()
            } else {
                returnToMorsels()
            }
        }
    }

    func importURL(urlString: String) {
        var escapedUrlString: String = urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLHostAllowedCharacterSet())!
        var url = kWEBAPIURL + "/og/" + escapedUrlString
        request(Method.GET, url,
            parameters: [
                "client[device]": "proto"
            ]).responseJSON { (request, response, json, error) in
                if error != nil {
                    Util.showOkAlertWithTitle("Error!", message: "\(error?.localizedDescription)")
                    self.tempImportedImageURL = nil
                } else {
                    self.tempImportedImageURL = json!.valueForKey("image_url") as NSString
                    // TODO: Check if photo exists,
                    // if so, upload
                    // else create item w/o image
                    var text = "(Imported from \(urlString))\n\n"
                    + (json!.valueForKey("title") as NSString) + "\n\n"
                    + (json!.valueForKey("description") as NSString)
                    self.apiCreateItem(json!.valueForKey("image_url") as NSString, text)
                }
        }

        // TODO: Create Item w/ metadata description
        // TODO: Upload photo from metadata photo
    }


    // MARK: Show Stuff

    func showCropperForImage(image: UIImage) {
        var cropper = RSKImageCropViewController(image: image, cropMode: .Square, cropSize: CGSizeMake(600,600))
        cropper.delegate = self
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
            , dispatch_get_main_queue(), {
                self.presentViewController(cropper, animated: false, completion: nil)
        })
    }

    func showEditorForImage(image: UIImage) {
        var editor = CLImageEditor(image: image, delegate: self)
        for subtool: CLImageToolInfo in editor.toolInfo.subtools as [CLImageToolInfo] {
            subtool.available = contains(["CLFilterTool", "CLAdjustmentTool", "CLDrawTool"], subtool.toolName)
        }
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
            , dispatch_get_main_queue(), {
                self.presentViewController(editor, animated: false, completion: nil)
        })
    }

    func showCamera() {
        let picker: UIImagePickerController = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = UIImagePickerControllerSourceType.Camera
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureMode.Photo
        presentViewController(picker, animated: true, completion: nil)
    }

    func showPhotoLibrary() {
        let picker: UIImagePickerController = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = false
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        presentViewController(picker, animated: true, completion: nil)
    }

    func showImportFromURL() {
        var alertView = UIAlertView(
            title: "Import URL",
            message: "Enter a link below to import it",
            delegate: self,
            cancelButtonTitle: "Cancel",
            otherButtonTitles: "Import"
        )
        alertView.alertViewStyle = UIAlertViewStyle.PlainTextInput
        alertView.textFieldAtIndex(0)?.text = "https://www.eatmorsel.com/paulfehribach/1511-a-signature-duet-of-pork-for-fall"
        alertView.show()
    }

    func showCameraOrPhotosAlert() {
        var actionSheet = UIActionSheet(
            title: "Select a photo",
            delegate: self,
            cancelButtonTitle: nil,
            destructiveButtonTitle: nil,
            otherButtonTitles: "Take a Photo", "Select from Library", "Import from URL"
        )

        actionSheet.addButtonWithTitle("Cancel")
        actionSheet.showInView(view)
    }

    func positionForActiveCell() -> Int {
        var indexPath = activeCellIndexPath
        if indexPath != nil {
            return indexPath!.section + indexPath!.row
        } else {
            return 0
        }
    }

    func positionForPreviousCell() -> Int {
        var currentPosition = positionForActiveCell()
        var prevPosition = currentPosition - 1
        if prevPosition < 0 {
            prevPosition = max(1,tableView!.numberOfRowsInSection(1) - 1)
        }

        return prevPosition
    }
    
    func positionForNextCell() -> Int {
        var currentPosition = positionForActiveCell()
        var nextPosition = currentPosition + 1
        if nextPosition > tableView?.numberOfRowsInSection(1) {
            nextPosition = 0
        }
        
        return nextPosition
    }
    
    func indexPathForPosition(position: Int) -> NSIndexPath {
        if position > 0 {
            return NSIndexPath(forRow: position - 1, inSection: 1)
        } else {
            return NSIndexPath(forRow: 0, inSection: 0)
        }
    }

    // MARK: Keyboard

    func keyboardWillShow(notification: NSNotification) {
        if self.tableView?.tableHeaderView != nil {
            tableView?.beginUpdates()
            self.tableView?.tableHeaderView = nil
            tableView?.endUpdates()
        }

        var keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue()
        defaultKeyboardHeight = keyboardFrame!.height

        toggleNavBarHidden(true)
        updateScrollPosition()
    }

    func keyboardWillHide(notification: NSNotification) {
        toggleNavBarHidden(false)
    }

    func keyboardDidShow(notification: NSNotification) {
        updateScrollPosition()
    }

    // MARK: API

    func isDirty() -> Bool {
        return morsel?.title != morsel?.cleanTitle
    }

    func apiCreateMorsel() {
        if morsel?.id != nil { return }
        updating = true

        alamofireManager!.request(Method.POST,
            kAPIURL + "/morsels.json",
            parameters: [
                "client[device]": "proto",
                "api_key": dataManager.currentUser!.apiKey!
            ]).responseJSON({ (request, response, json, error) in
                self.updating = false
                if error != nil {
                    Util.showOkAlertWithTitle("Error!", message: "\(error?.localizedDescription)")
                } else {
                    self.morsel = self.dataManager.importMorsel((json!.valueForKey("data") as NSDictionary))
                }
            })
    }

    func apiDeleteMorsel() {
        titleViewLabel.text = "Clean up..."
        updating = true

        alamofireManager!.request(Method.DELETE,
            kAPIURL + "/morsels/" + morsel!.id! + ".json",
            parameters: [
                "client[device]": "proto",
                "api_key": dataManager.currentUser!.apiKey!
            ]).responseJSON({ (request, response, json, error) in
                self.updating = false
                self.returnToMorsels()
            })
    }

    func apiUpdateTitle() {
        if morsel?.title != morsel?.cleanTitle {
            updating = true

            alamofireManager!.request(Method.PUT,
                kAPIURL + "/morsels/" + morsel!.id! + ".json",
                parameters: [
                    "client[device]": "proto",
                    "api_key": dataManager.currentUser!.apiKey!,
                    "morsel[title]": morsel!.title!
                ]).responseJSON({ (request, response, json, error) in
                    self.updating = false
                    if error != nil {
                        Util.showOkAlertWithTitle("Error!", message: "\(error?.localizedDescription)")
                    } else {
                        self.morsel?.updateFromJSON((json!.valueForKey("data") as NSDictionary))
                        self.morsel?.cleanTitle = self.morsel?.title
                    }
                })
        }
    }

    func apiPublishMorsel() {
        if morsel?.items.count == 0 {
            // Don't allow publishing w/o any items
            Util.showOkAlertWithTitle("Missing photos", message: "Add some photos before publishing your morsel")
            return
        } else if morsel!.title!.isEmpty {
            Util.showOkAlertWithTitle("Missing title", message: "Add a title")
            return
        }
        updating = true

        alamofireManager!.request(Method.POST,
            kAPIURL + "/morsels/" + morsel!.id! + (morsel!.isDraft ? "/publish.json" : "/republish.json"),
            parameters: [
                "client[device]": "proto",
                "api_key": dataManager.currentUser!.apiKey!,
                "morsel[primary_item_id]": morsel!.lastItemOrPrimaryItemID(),
                "post_to_facebook": "true", // !!!: Eh, just pass true for both of these, social worker doesn't block anything else
                "post_to_twitter": "true"
            ]).responseJSON({ (request, response, json, error) in
                self.updating = false
                if error != nil {
                    Util.showOkAlertWithTitle("Error!", message: "\(error?.localizedDescription)")
                }
                self.dataManager.isPublishing = true
                Util.showOkAlertWithTitle("Queued for publication", message: "Expect to see it live in a few seconds. If you're connected with Facebook and Twitter (in the main app), we'll syndicate it out to those too!")
                self.returnToMorsels()
            })
    }

    func apiUploadItemPhoto(item: PROItem) {
        updating = true
        // !!!: Assuming presigned exists
        // !!!: Assuming photo exists

        var parameters: NSMutableDictionary = NSMutableDictionary(dictionary: item.presignedUploadDictionary!)
        var presignedURL: NSString = parameters["url"] as NSString
        parameters.removeObjectForKey("url")

        var imageData: NSData = UIImageJPEGRepresentation(item.photoImage!, 1)
        let manager = AFHTTPRequestOperationManager()
        manager.responseSerializer = AFHTTPResponseSerializer()
        manager.responseSerializer.acceptableContentTypes = NSSet(object: "application/xml")
        manager.POST(presignedURL,
            parameters: parameters,
            constructingBodyWithBlock: { (formData) -> Void in
                formData.appendPartWithFileData(imageData,
                    name: "file",
                    fileName: "photo.jpg",
                    mimeType: "image/jpeg"
                )
            },
            success: { (operation, responseObject) -> Void in
                self.updating = false
                var dictionary = NSDictionary(XMLData: (responseObject as NSData))
                self.apiUpdatePhotoKey(item, key: dictionary["Key"] as String)
            }) { (operation, error) -> Void in
                self.updating = false
                return
        }
    }

    func apiUpdatePhotoKey(item: PROItem, key: String) {
        updating = true

        alamofireManager!.request(Method.PUT,
            kAPIURL + "/items/" + item.id! + ".json",
            parameters: [
                "client[device]": "proto",
                "api_key": dataManager.currentUser!.apiKey!,
                "item[photo_key]": key
            ]
            ).responseJSON({ (request, response, json, error) in
                self.updating = false
                if error != nil {
                    Util.showOkAlertWithTitle("Error!", message: "\(error?.localizedDescription)")
                } else {
                    item.updateFromJSON(json as? NSDictionary)
                    item.cleanText = item.text
                }
            })
    }

    func apiCreateItem(image: UIImage, _ text: String? = nil) {
        updating = true

        alamofireManager!.request(Method.POST,
            kAPIURL + "/items.json",
            parameters: [
                "client[device]": "proto",
                "api_key": dataManager.currentUser!.apiKey!,
                "item[morsel_id]": morsel!.id!,
                "item[description]": (text != nil ? text! : NSNull()),
                "prepare_presigned_upload": "true"
            ]).responseJSON({ (request, response, json, error) in
                self.updating = false
                if error != nil {
                    Util.showOkAlertWithTitle("Error!", message: "\(error?.localizedDescription)")
                } else {
                    var item = self.dataManager.importItem((json!.valueForKey("data") as NSDictionary), morsel: self.morsel!)
                    item.photoImage = image
                    self.apiUploadItemPhoto(item)
                    self.tableView?.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
                    var row = self.morsel!.items.count
                    if row > 0 {
                        var indexPath = NSIndexPath(forRow: row - 1, inSection: 1)
                        self.becomeFirstResponderAtIndexPath(indexPath)
                    }
                }
            })
    }

    func apiCreateItem(imageUrl: String, _ text: String? = nil) {
        updating = true
        
        alamofireManager!.request(Method.POST,
            kAPIURL + "/items.json",
            parameters: [
                "client[device]": "proto",
                "api_key": dataManager.currentUser!.apiKey!,
                "item[morsel_id]": morsel!.id!,
                "item[description]": (text != nil ? text! : NSNull()),
                "item[remote_photo_url]": imageUrl
            ]).responseJSON({ (request, response, json, error) in
                self.updating = false
                if error != nil {
                    Util.showOkAlertWithTitle("Error!", message: "\(error?.localizedDescription)")
                } else {
                    var item = self.dataManager.importItem((json!.valueForKey("data") as NSDictionary), morsel: self.morsel!)
                    self.tableView?.reloadSections(NSIndexSet(index: 1), withRowAnimation: .Automatic)
                    var row = self.morsel!.items.count
                    if row > 0 {
                        var indexPath = NSIndexPath(forRow: row - 1, inSection: 1)
                        self.becomeFirstResponderAtIndexPath(indexPath)
                    }
                }
            })
    }

    func apiDeleteItem(item: PROItem) {
        titleViewLabel.text = "Clean up..."
        updating = true

        alamofireManager!.request(Method.DELETE,
            kAPIURL + "/items/" + item.id! + ".json",
            parameters: [
                "client[device]": "proto",
                "api_key": dataManager.currentUser!.apiKey!
            ]).responseJSON({ (request, response, json, error) in
                self.updating = false
            })
    }

    func apiUpdateDescription(item: PROItem) {
        // !!!: Assuming item already exists on backend
        if item.text != item.cleanText {
            updating = true

            alamofireManager!.request(Method.PUT,
                kAPIURL + "/items/" + item.id! + ".json",
                parameters: [
                    "client[device]": "proto",
                    "api_key": dataManager.currentUser!.apiKey!,
                    "item[description]": item.text!
                ]
                ).responseJSON({ (request, response, json, error) in
                    self.updating = false
                    if error != nil {
                        Util.showOkAlertWithTitle("Error!", message: "\(error?.localizedDescription)")
                    } else {
                        item.updateFromJSON(json as? NSDictionary)
                        item.cleanText = item.text
                    }
                })
        }
    }


    // MARK: - IBAction

    @IBAction func cancel(sender: AnyObject) {
        if morsel != nil {
            dataManager.mixpanel.track("Tapped Cancel", properties: [
                "morsel_id": morsel!.id!
            ])
        }

        if updating {
            Util.showOkAlertWithTitle("Syncing Data...", message: "Wait a few seconds and try again")
        } else {
            if isDirty() {
                var alertView = UIAlertView(
                    title: "Unsaved changes",
                    message: "Discard any changes made?",
                    delegate: self,
                    cancelButtonTitle: "Cancel",
                    otherButtonTitles: "Discard"
                )

                alertView.show()
            } else {
                cleanupMorsel()
            }
        }
    }

    @IBAction func submit(sender: AnyObject) {
        if morsel != nil && !updating {
            dataManager.mixpanel.track("Tapped Publish", properties: [
                "morsel_id": morsel!.id!
                ])
            apiPublishMorsel()
        } else {
            Util.showOkAlertWithTitle("Syncing Data...", message: "Wait a few seconds and try again")
        }
    }

    @IBAction func pickExistingMorsel(sender: AnyObject) {
        self.view.endEditing(true)
        cancel(sender)
    }

    @IBAction func addItem(sender: AnyObject) {
        self.view.endEditing(true)

        if morsel != nil {
            dataManager.mixpanel.track("Tapped Append Photo", properties: [
                "morsel_id": morsel!.id!
                ])
            showCameraOrPhotosAlert()
        } else {
            Util.showOkAlertWithTitle("Syncing Data...", message: "Wait a few seconds and try again")
        }
    }


    // MARK: - UIActionSheetDelegate

    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 { // Camera
            if morsel != nil {
                dataManager.mixpanel.track("Tapped Camera", properties: [
                    "morsel_id": morsel!.id!
                    ])
            }
            showCamera()
        } else if buttonIndex == 1 {   //  Photo Library
            if morsel != nil {
                dataManager.mixpanel.track("Tapped Photo Library", properties: [
                    "morsel_id": morsel!.id!
                    ])
            }
            showPhotoLibrary()
        } else if buttonIndex == 2 {   //  Import from URL
            if morsel != nil {
                dataManager.mixpanel.track("Tapped Import from URL", properties: [
                    "morsel_id": morsel!.id!
                    ])
            }
            showImportFromURL()
        } else { // Cancel
            if morsel != nil {
                dataManager.mixpanel.track("Tapped Cancel", properties: [
                    "morsel_id": morsel!.id!
                    ])
            }
        }
    }


    // MARK: - UIAlertViewDelegate

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.title == "Unsaved changes" && buttonIndex == 1 {
            cleanupMorsel()
        } else if (alertView.title == "Import URL" && buttonIndex == 1) {
            importURL(alertView.textFieldAtIndex(0)!.text)
        }
    }


    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        originalImage = info[UIImagePickerControllerOriginalImage] as UIImage!

        dismissViewControllerAnimated(false, completion: nil)
        showCropperForImage(originalImage!)
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(false, completion: nil)
    }


    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return (section == 1 && morsel != nil && morsel!.items.count > 0) ? "Items" : nil;
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 1 ? (morsel != nil ? morsel!.items.count : 0) : 1;
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.section == 1) {
            var item: PROItem = morsel!.sortedItems[indexPath.row]
            return item.cellHeight
        } else {
            return [max(titleCellHeight, kDefaultTitleCellHeight), -1, 80][indexPath.section]
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var identifier: String? = ["editTitleCell", "editItemCell", "addItemCell"][indexPath.section]

        var cell: PROTableViewCell = tableView.dequeueReusableCellWithIdentifier(identifier!, forIndexPath: indexPath) as PROTableViewCell

        cell.titleCell = indexPath.section == 0
        var textView = cell.textView
        var imageView = cell.photoImageView
        if textView != nil {
            if indexPath.section == 0 {
                textView?.text = morsel != nil ? morsel!.title : nil
                if imageView != nil {
                    var primaryItem: PROItem? = morsel?.primaryItem()
                    if primaryItem != nil {
                        if primaryItem?.photoImage == nil {
                            if primaryItem?.photoURL != nil {
                                imageView?.setImageWithURLRequest(NSURLRequest(URL: NSURL(string: primaryItem!.photoURL!)!),
                                    placeholderImage: nil,
                                    usingActivityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge,
                                    success: { (imageRequest, urlResponse, image) -> Void in
                                        if imageView?.image == image { return }
                                        primaryItem?.photoImage = image
                                        imageView?.alpha = 0.0
                                        imageView?.image = image.blurredImageWithRadius(20.0, iterations: 2, tintColor: UIColor.blackColor())
                                        UIView.animateWithDuration(0.3, animations: {
                                            imageView?.alpha = 1.0
                                            return
                                        })
                                    },
                                    failure: { (imageRequest, urlResponse, error) -> Void in
                                        imageView?.image = nil
                                        return
                                })
                            } else {
                                imageView?.image = nil
                            }
                        } else {
                            imageView?.image = primaryItem?.photoImage?.blurredImageWithRadius(20.0, iterations: 2, tintColor: UIColor.blackColor())
                        }
                    } else {
                        imageView?.image = nil
                    }
                }
            } else if indexPath.section == 1 {
                var item: PROItem = morsel!.sortedItems[indexPath.row]
                textView?.text = item.text

                if item.photoImage == nil {
                    if item.photoURL != nil {
                        imageView?.setImageWithURLRequest(NSURLRequest(URL: NSURL(string: item.photoURL!)!),
                            placeholderImage: nil,
                            usingActivityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge,
                            success: { (imageRequest, urlResponse, image) -> Void in
                                if imageView?.image == image { return }
                                item.photoImage = image
                                imageView?.alpha = 0.0
                                imageView?.image = image
                                UIView.animateWithDuration(0.3, animations: {
                                    imageView?.alpha = 1.0
                                    return
                                })
                            },
                            failure: { (imageRequest, urlResponse, error) -> Void in
                                imageView?.image = nil
                                return
                        })
                    } else if tempImportedImageURL != nil {
                        imageView?.setImageWithURLRequest(NSURLRequest(URL: NSURL(string: tempImportedImageURL!)!),
                            placeholderImage: nil,
                            usingActivityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge,
                            success: { (imageRequest, urlResponse, image) -> Void in
                                if imageView?.image == image { return }
                                item.photoImage = image
                                item.photoURL = self.tempImportedImageURL
                                self.tempImportedImageURL = nil
                                imageView?.alpha = 0.0
                                imageView?.image = image
                                UIView.animateWithDuration(0.3, animations: {
                                    imageView?.alpha = 1.0
                                    return
                                })
                            },
                            failure: { (imageRequest, urlResponse, error) -> Void in
                                imageView?.image = nil
                                return
                        })
                    } else {
                        imageView?.image = nil
                    }
                } else {
                    imageView?.image = item.photoImage
                }
            }

            textView?.inputAccessoryView = keyboardInputAccessoryView
        }

        cell.setNeedsLayout()
        return cell
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            var item: PROItem = morsel!.sortedItems[indexPath.row]
            dataManager.mixpanel.track("Deleted Item", properties: [
                "item_id": item.id!,
                "morsel_id": morsel!.id!
            ])
            apiDeleteItem(item)
            dataManager.removeItemFromMorsel(item, morsel: morsel!)
            self.view.endEditing(true)

            tableView.deleteRowsAtIndexPaths([indexPath],
                withRowAnimation: UITableViewRowAnimation.Fade
            )
        }
    }


    // MARK: - PROInputAccessoryViewDelegate

    func inputAccessoryViewTappedDismissKeyboardButton(inputAccessoryView: UIView) {
        self.view.endEditing(true)
    }

    func inputAccessoryViewTappedUpButton(inputAccessoryView: UIView) {
        if tableView?.numberOfRowsInSection(1) > 0 {
            becomeFirstResponderAtIndexPath(indexPathForPosition(positionForPreviousCell()))
//            updateScrollPosition()
        }
    }

    func inputAccessoryViewTappedDownButton(inputAccessoryView: UIView) {
        if tableView?.numberOfRowsInSection(1) > 0 {
            becomeFirstResponderAtIndexPath(indexPathForPosition(positionForNextCell()))
//            updateScrollPosition()
        }
    }

    func inputAccessoryViewTappedAddButton(inputAccessoryView: UIView) {
        addItem(inputAccessoryView)
    }

    // MARK: - ExpandableTableViewDelegate

    func tableView(tableView: UITableView, updatedText: String, indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            morsel?.title = updatedText
        } else {
            var item: PROItem = morsel!.sortedItems[indexPath.row]
            item.text = updatedText
        }

    }

    func tableView(tableView: UITableView, updatedHeight: CGFloat, indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            titleCellHeight = updatedHeight
        } else {
            var item: PROItem = morsel!.sortedItems[indexPath.row]
            item.cellHeight = updatedHeight
        }

        updateScrollPosition()
    }

    func tableView(tableView: UITableView, textViewDidBeginEditing: UITextView, titleCell: Bool) -> Bool {
        activeTextView = textViewDidBeginEditing
        updateScrollPosition()
        if tableView.numberOfRowsInSection(1) > 0 {
            keyboardInputAccessoryView?.updatePosition(positionForIndexPath(activeCellIndexPath!))
        }
        navigationItem.pro_disableButtons(true)

        return true
    }

    func tableView(tableView: UITableView, textViewDidEndEditing: UITextView, titleCell: Bool) -> Bool {
        if titleCell {
            apiUpdateTitle()
        } else {
            var item: PROItem = morsel!.sortedItems[activeCellIndexPath!.row]
            apiUpdateDescription(item)
        }
        activeTextView = nil
        navigationItem.pro_disableButtons(false)

        return true
    }


    // MARK: - CLImageEditorDelegate

    func imageEditor(editor: CLImageEditor!, didFinishEdittingWithImage image: UIImage!) {
        editor.dismissViewControllerAnimated(false, completion: nil)
        apiCreateItem(image, nil)
    }

    func imageEditorDidCancel(editor: CLImageEditor!) {
        editor.dismissViewControllerAnimated(false, completion: nil)
        showCropperForImage(originalImage!)
    }


    // MARK: - RSKImageCropViewControllerDelegate

    func imageCropViewController(controller: RSKImageCropViewController!, didCropImage croppedImage: UIImage!) {
        dismissViewControllerAnimated(false, completion: nil)
        showEditorForImage(croppedImage)
    }

    func imageCropViewControllerDidCancelCrop(controller: RSKImageCropViewController!) {
        dismissViewControllerAnimated(false, completion: nil)
    }




    // MARK: - Testing

    func fakeAddItem(image: UIImage) {
        apiCreateItem(image, nil)

        self.tableView?.tableHeaderView = nil
    }

    func becomeFirstResponderAtIndexPath(indexPath: NSIndexPath) {
        self.tableView!.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.Top)
        var cell: PROTableViewCell? = self.tableView?.cellForRowAtIndexPath(indexPath) as PROTableViewCell?

        cell!.textView?.becomeFirstResponder()
    }

    func positionForIndexPath(indexPath: NSIndexPath) -> PROPosition {
        if indexPath.section == 0 {
            return PROPosition.Top
        } else if (indexPath.row == tableView!.numberOfRowsInSection(indexPath.section) - 1) {
            return PROPosition.Bottom
        } else {
            return PROPosition.Middle
        }
    }
}
