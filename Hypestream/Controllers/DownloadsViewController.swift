//
//  ViewController.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/17/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import UIKit

class DownloadsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DownloadProgressDelegate {

    // MARK: - Interface Builder
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Class Properties

    var tracks: [Track] = [Track]() {
        didSet {
            tableView.reloadData()
            if (tracks.count > 0) {
                navigationController!.tabBarItem.badgeValue = String(tracks.count)
            } else {
                navigationController!.tabBarItem.badgeValue = nil
            }
        }
    }
    let refreshControl = UIRefreshControl()
    let appDelegate = (UIApplication.sharedApplication().delegate as AppDelegate)

    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate.downloadProgressDelegate = self
        refreshControl.addTarget(self, action: Selector("scrapeAndReload"), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(self.refreshControl)
        tableView.registerNib(UINib(nibName: "HypeTrackCell", bundle: nil), forCellReuseIdentifier: "HypeTrackCell")

        loadTracksFromDB()
        refreshControl.beginRefreshing()
        let newOffset = CGPointMake(0, -self.tableView.contentInset.top);
        tableView.setContentOffset(newOffset, animated:true);
        scrapeAndReload()
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
        cell.setProgressNow(track.downloadProgress)
        cell.loading = track.downloadInProgress
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let row = tableView.cellForRowAtIndexPath(indexPath) as HypeTrackCell
        let track = tracks[indexPath.row]
        appDelegate.downloadTrack(track)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - DownloadProgressDelegate
    
    func didMoveTrackToInbox(track: Track) {
        if let index = self.indexForTrack(track) {
            let path = NSIndexPath(forRow: index, inSection: 0)
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.beginUpdates()
                self.tracks.removeAtIndex(index)
                self.tableView.deleteRowsAtIndexPaths([path], withRowAnimation: .Fade)
                self.tableView.endUpdates()
            });
        }
    }
    
    // MARK: - Functionality

    func loadTracksFromDB() {
        let results = Helper.getTracksWithState(.ToDownload)
        if let error = results.error {
            println(error.localizedDescription)
            dispatch_async(dispatch_get_main_queue(), {
                SVProgressHUD.showErrorWithStatus("Couldn't access DB")
            })
        } else {
            self.tracks = results.tracks!
        }
    }
    
    func scrapeAndReload() {
        Scraper.addNewTracksToDB({ (added, skipped, errors) -> Void in
            println("Added: \(added.count), skipped: \(skipped.count), errors: \(errors.count)")
            self.loadTracksFromDB()
            self.refreshControl.endRefreshing()
        }, onError: { (error) -> Void in
            println(error.localizedDescription)
            dispatch_async(dispatch_get_main_queue(), {
                SVProgressHUD.showErrorWithStatus("Couldn't fetch tracks")
            })
            self.refreshControl.endRefreshing()
        })
    }
    
    // MARK: - Helpers
    
    func indexForTrack(track: Track) -> Int? {
        for (index, tableTrack) in enumerate(self.tracks) {
            if (track == tableTrack) {
                return index
            }
        }
        return nil
    }

}
