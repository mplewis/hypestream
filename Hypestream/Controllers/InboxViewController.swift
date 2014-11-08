//
//  InboxViewController.swift
//  Hypestream
//
//  Created by Matthew Lewis on 11/6/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import UIKit

class InboxViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Interface Builder
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Class Properties
    
    var tracks: [Track] = [Track]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerNib(UINib(nibName: "HypeTrackCell", bundle: nil), forCellReuseIdentifier: "HypeTrackCell")
        loadTracksFromDB()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("HypeTrackCell") as HypeTrackCell
        
        // Clear the cell's progress bar
        cell.resetProgress()
        
        // Fill the cell with data
        let track = tracks[indexPath.row]
        track.trackDownloadDelegate = cell
        cell.artist = track.artist
        cell.title = track.title
        cell.loading = false
        cell.lastAccessed = track.last_accessed
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let row = tableView.cellForRowAtIndexPath(indexPath) as HypeTrackCell
        let track = tracks[indexPath.row]
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - Functionality
    
    func loadTracksFromDB() {
        let sortDesc = NSSortDescriptor(key: "last_accessed", ascending: false)
        let results = Helper.getTracksWithState(.Inbox, sortDescriptors: [sortDesc])
        if let error = results.error {
            println(error.localizedDescription)
            dispatch_async(dispatch_get_main_queue(), {
                SVProgressHUD.showErrorWithStatus("Couldn't access DB")
            })
        } else {
            tracks = results.tracks!
        }
    }

}
