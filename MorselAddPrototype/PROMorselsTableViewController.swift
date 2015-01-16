//
//  PROMorselsTableViewController.swift
//  MorselAddPrototype
//
//  Created by Marty Trzpit on 12/11/14.
//  Copyright (c) 2014 Morsel. All rights reserved.
//

import UIKit

class PROMorselsTableViewController: UITableViewController {
    let dataManager: PRODataManager = PRODataManager.sharedInstance
    var timer: NSTimer? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        var refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("fetchData"), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        dataManager.mixpanel.track("Viewed Morsels")

        tableView?.reloadData()
        fetchData()

        // TODO: If recently updated, do check until done publishing
        if dataManager.isPublishing {
            timer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        stopTimer()
    }

    func update() {
        if dataManager.morselsArePublishing() {
            NSLog("Ding")
            fetchData()
        } else {
            NSLog("Dong")
            stopTimer()
        }
    }

    func stopTimer() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }

        dataManager.isPublishing = false
    }

    func fetchData() {
        refreshControl?.beginRefreshing()

        request(Method.GET, kAPIURL + "/morsels.json",
            parameters: [
                "client[device]": "proto",
                "api_key": dataManager.currentUser!.apiKey!
            ]).responseJSON { (request, response, json, error) in
                if error != nil {
                    Util.showOkAlertWithTitle("Error!", message: "\(error?.localizedDescription)")
                } else if (json!.valueForKey("errors") != nil && json!.valueForKey("errors") as? NSNull != NSNull()) {
                    var errors: NSDictionary = json!.valueForKey("errors") as NSDictionary
                    Util.showOkAlertWithTitle("API Error!", message: "\(errors)")
                } else if (json!.valueForKey("data") != nil && json!.valueForKey("data") as? NSNull != NSNull()) {
                    self.dataManager.deleteAllMorsels()
                    self.dataManager.importMorsels(json!.valueForKey("data") as [NSDictionary])
                    self.tableView.reloadData()
                }
                self.refreshControl?.endRefreshing()
        }
    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return dataManager.morselCount()
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100.0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as UITableViewCell

        var morsel = dataManager.sortedMorsels[indexPath.row]
        var title: String = morsel.title != nil ? morsel.title! : "Untitled"
        if let morselStatus = morsel.status() {
            cell.textLabel?.text = "[\(morselStatus)] \(title)"
        } else {
            cell.textLabel?.text = title
        }
        if morsel.updatedAtDate != nil {
            cell.detailTextLabel?.text = "Updated \(morsel.updatedAtDate!.timeAgoSinceNow())"
        } else {
            cell.detailTextLabel?.text = nil
        }

        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            var morsel = dataManager.sortedMorsels[indexPath.row]

            dataManager.removeMorsel(morsel)
            tableView.deleteRowsAtIndexPaths([indexPath],
                withRowAnimation: UITableViewRowAnimation.Fade
            )

            request(Method.DELETE,
                kAPIURL + "/morsels/" + morsel.id! + ".json",
                parameters: [
                    "client[device]": "proto",
                    "api_key": dataManager.currentUser!.apiKey!
                ]).responseJSON({ (request, response, json, error) in
                    if error != nil {
                        Util.showOkAlertWithTitle("Error!", message: "\(error?.localizedDescription)")
                    } else if (json!.valueForKey("errors") != nil && json!.valueForKey("errors") as? NSNull != NSNull()) {
                        var errors: NSDictionary = json!.valueForKey("errors") as NSDictionary
                        Util.showOkAlertWithTitle("API Error!", message: "\(errors)")
                    }
                    self.fetchData()
                })
        }
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var manageMorselViewController: PROManageMorselViewController = segue.destinationViewController as PROManageMorselViewController
        let indexPath: NSIndexPath? = tableView.indexPathForSelectedRow()

        let row = indexPath?.row
        var morsel = dataManager.sortedMorsels[row!]

        manageMorselViewController.morsel = morsel

        dataManager.mixpanel.track("Tapped Morsel", properties: [
            "morsel_id": morsel.id!
        ])
    }
}
