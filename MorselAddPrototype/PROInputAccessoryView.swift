//
//  PROInputAccessoryView.swift
//  MorselAddPrototype
//
//  Created by Marty Trzpit on 12/17/14.
//  Copyright (c) 2014 Morsel. All rights reserved.
//

import UIKit

@objc protocol PROInputAccessoryViewDelegate: class {
    optional func inputAccessoryViewTappedDismissKeyboardButton(inputAccessoryView: UIView)
    optional func inputAccessoryViewTappedUpButton(inputAccessoryView: UIView)
    optional func inputAccessoryViewTappedDownButton(inputAccessoryView: UIView)
    optional func inputAccessoryViewTappedAddButton(inputAccessoryView: UIView)
}

class PROInputAccessoryView: UIToolbar {
    weak var inputAccessoryViewDelegate: PROInputAccessoryViewDelegate? = nil
    @IBOutlet weak var upButton: UIBarButtonItem? = nil
    @IBOutlet weak var downButton: UIBarButtonItem? = nil

    private var position: PROPosition = .Top

    class func defaultInputAccessoryView(delegate: PROInputAccessoryViewDelegate?) -> PROInputAccessoryView {
        var accView: PROInputAccessoryView = NSBundle.mainBundle().loadNibNamed("PROInputAccessoryView",
            owner: nil,
            options: nil).first as PROInputAccessoryView

        var borderLayer = CAShapeLayer()
        accView.layer.addSublayer(borderLayer)

        var path = UIBezierPath()
        path.moveToPoint(CGPointMake(0.0, 0.5))
        path.addLineToPoint(CGPointMake(CGRectGetWidth(accView.frame), 0.5))

        borderLayer.frame = accView.bounds;
        borderLayer.path = path.CGPath;

        borderLayer.strokeColor = UIColor.lightGrayColor().CGColor
        borderLayer.lineWidth = 0.5;

        accView.inputAccessoryViewDelegate = delegate

        return accView
    }

    func disableButtons() {
        upButton?.enabled = false
        downButton?.enabled = false
    }

    func updatePosition(newPosition: PROPosition) {
        position = newPosition

        if position == PROPosition.None {
            upButton?.mt_setHidden(true)
            downButton?.mt_setHidden(true)
        } else {
            upButton?.mt_setHidden(false)
            downButton?.mt_setHidden(false)
        }

        switch position {
        case .None:
            upButton?.enabled = false
            downButton?.enabled = false
        case .Top:
            upButton?.enabled = false
            downButton?.enabled = true
        case .Bottom:
            upButton?.enabled = true
            downButton?.enabled = false
        default:
            upButton?.enabled = true
            downButton?.enabled = true
        }
    }


    @IBAction func dismissKeyboard() {
        if inputAccessoryViewDelegate != nil {
            inputAccessoryViewDelegate?.inputAccessoryViewTappedDismissKeyboardButton!(self)
        }
    }
    
    @IBAction func upButtonTapped() {
        if inputAccessoryViewDelegate != nil {
            inputAccessoryViewDelegate?.inputAccessoryViewTappedUpButton!(self)
        }
    }
    
    @IBAction func downButtonTapped() {
        if inputAccessoryViewDelegate != nil {
            inputAccessoryViewDelegate?.inputAccessoryViewTappedDownButton!(self)
        }
    }
    
    @IBAction func addButtonTapped() {
        if inputAccessoryViewDelegate != nil {
            inputAccessoryViewDelegate?.inputAccessoryViewTappedAddButton!(self)
        }
    }
}

extension UIBarButtonItem {
    func mt_setHidden(shouldHide: Bool) {
        if shouldHide {
            self.tintColor = UIColor.clearColor()
        } else {
            self.tintColor = nil
        }
    }
}
