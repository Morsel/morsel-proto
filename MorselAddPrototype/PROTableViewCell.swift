//
//  PROTableViewCell.swift
//  MorselAddPrototype
//
//  Created by Marty Trzpit on 12/15/14.
//  Copyright (c) 2014 Morsel. All rights reserved.
//
//  Based off of: https://github.com/acerbetti/ACEExpandableTextCell

import UIKit

@objc protocol ExpandableTableViewDelegate: class, UITableViewDelegate {
    func tableView(tableView: UITableView, updatedText: String, indexPath: NSIndexPath)

    optional func tableView(tableView: UITableView, updatedHeight: CGFloat, indexPath: NSIndexPath)
    optional func tableView(tableView: UITableView, textViewDidBeginEditing: UITextView, titleCell: Bool) -> Bool
    optional func tableView(tableView: UITableView, textViewDidEndEditing: UITextView, titleCell: Bool) -> Bool
}

let kCellBottomPadding: CGFloat = 20.0

class PROTableViewCell: UITableViewCell, UITextViewDelegate, UIActionSheetDelegate {
    @IBOutlet weak var textView: UITextView? = nil
    @IBOutlet weak var photoImageView: UIImageView? = nil
    @IBOutlet weak var tableView: UITableView? = nil
    @IBOutlet weak var separatorView: UIView? = nil
    @IBOutlet weak var infoButton: UIButton? = nil

    var textViewHeight: Float? {
        get {
            if (titleCell && textView!.text.isEmpty) {
                return Float(kDefaultTitleCellHeight)
            } else {
                let width: CGFloat? = textView?.frame.size.width
                var size: CGSize? = textView?.sizeThatFits(CGSizeMake(width!, CGFloat.max))
                return Float(max(size!.height, (titleCell ? 60.0 : 40.0)))
            }
        }
    }

    var cellHeight: Float? {
        get {
            if titleCell {
                return textViewHeight!
            } else {
                let imageOffset = photoImageView != nil ? CGRectGetMaxY(photoImageView!.frame) : 0.0
                let separatorOffset = separatorView != nil ? CGRectGetHeight(separatorView!.frame) + kCellBottomPadding : 0.0
                return textViewHeight! + Float(imageOffset) + Float(separatorOffset)
            }
        }
    }
    var descriptionText: String? = nil
    var titleCell: Bool = false

    override func layoutSubviews() {
        super.layoutSubviews()

        if textView != nil {
            textView?.frame = CGRectMake(
                CGRectGetMinX(textView!.frame),
                CGRectGetMinY(textView!.frame),
                CGRectGetWidth(textView!.frame),
                CGFloat(textViewHeight!)
            )
        }

        if separatorView != nil {
            separatorView?.frame = CGRectMake(
                CGRectGetMinX(separatorView!.frame),
                CGRectGetMaxY(textView!.frame),
                CGRectGetWidth(separatorView!.frame),
                CGRectGetHeight(separatorView!.frame)
            )
        }

        if titleCell == false {
            infoButton?.layer.shadowColor = UIColor.blackColor().CGColor
            infoButton?.layer.shadowOffset = CGSizeZero
            infoButton?.layer.shadowRadius = 5.0
            infoButton?.layer.shadowOpacity = 1.0
        } else {
            photoImageView?.frame = frame
        }
    }

    func setText(text: String?) {
        descriptionText = text
        textView?.text = text

        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
            , dispatch_get_main_queue(), {
                self.textViewDidChange(self.textView!)
        })
    }

    @IBAction func itemInfo() {
        textView?.resignFirstResponder()
        var actionSheet = UIActionSheet(
            title: "Item Options",
            delegate: self,
            cancelButtonTitle: nil,
            destructiveButtonTitle: "Delete this Item"
        )

        actionSheet.addButtonWithTitle("Cancel")
        actionSheet.showInView(tableView)
    }


    // MARK: - UITextViewDelegate

    func textViewDidBeginEditing(textView: UITextView) {
        if ((tableView?.delegate?.respondsToSelector(Selector("tableView:textViewDidBeginEditing:titleCell:"))) == true) {
            var delegate: (AnyObject) = (tableView!.delegate! as AnyObject)
            delegate.tableView!(tableView!, textViewDidBeginEditing: textView, titleCell: titleCell)
        }
    }

    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        if ((tableView?.delegate?.respondsToSelector(Selector("tableView:textViewDidEndEditing:titleCell:"))) == true) {
            var delegate: (AnyObject) = (tableView!.delegate! as AnyObject)
            return delegate.tableView!(tableView!, textViewDidEndEditing: textView, titleCell: titleCell)
        }

        return true
    }

    func textViewDidChange(textView: UITextView) {
        if ((tableView?.delegate?.respondsToSelector(Selector("tableView:updatedText:indexPath:"))) == true) {
            var delegate: (AnyObject) = (tableView!.delegate! as AnyObject)
            var indexPath: NSIndexPath? = tableView?.indexPathForCell(self)
            if indexPath == nil { return }

            descriptionText = textView.text

            delegate.tableView!(tableView!,
                updatedText: descriptionText!,
                indexPath: indexPath!
            )

            var newHeight: Float = cellHeight!
            var oldHeight: Float = Float(delegate.tableView!(tableView!, heightForRowAtIndexPath: indexPath!))

            if(fabs(newHeight - oldHeight) > 0.01) {
                if ((delegate.respondsToSelector(Selector("tableView:updatedHeight:indexPath:"))) == true) {
                    delegate.tableView!(tableView!,
                        updatedHeight: CGFloat(newHeight),
                        indexPath: indexPath!
                    )
                }

                tableView?.beginUpdates()
                setNeedsLayout()
                tableView?.endUpdates()
            }
        }
    }


    //  MARK: - UIActionSheetDelegate

    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            var delegate: (AnyObject) = (tableView!.delegate! as AnyObject)
            if ((delegate.respondsToSelector(Selector("tableView:textViewDidBeginEditing:titleCell:"))) == true) {

                delegate.tableView!(tableView!,
                    commitEditingStyle: UITableViewCellEditingStyle.Delete,
                    forRowAtIndexPath: tableView!.indexPathForCell(self)!
                )
            }
        }
    }
}
