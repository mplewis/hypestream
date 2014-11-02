//
//  ViewController.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/17/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSURLSessionDownloadDelegate {

    // MARK: - Interface Builder
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Class Properties

    var tracks: [JSON] = [JSON]() {
        didSet {
            self.tableView.reloadData()
        }
    }

    let refreshControl = UIRefreshControl()
    
    lazy var bkgSession: NSURLSession = {
        let bkgConfig = NSURLSessionConfiguration.backgroundSessionConfiguration("com.kesdev.Hypestream")
        return NSURLSession(configuration: bkgConfig, delegate: self, delegateQueue: nil)
    }()

    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl.addTarget(self, action: Selector("refreshFeed"), forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(self.refreshControl)
        
        self.tableView.registerNib(UINib(nibName: "HypeTrackCell", bundle: nil), forCellReuseIdentifier: "HypeTrackCell")
        
        self.refreshFeed()
    }
    
    // MARK: - UITableView
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("HypeTrackCell") as HypeTrackCell
        let track = tracks[indexPath.row]
        if let artist = track["artist"].asString {
            cell.artist = artist
        }
        if let title = track["song"].asString {
            cell.title = title
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let row = tableView.cellForRowAtIndexPath(indexPath) as HypeTrackCell
        row.loading = true
        row.userInteractionEnabled = false
        
        let track = tracks[indexPath.row]

        if let id = track["id"].asString {
            if let key = track["key"].asString {
                self.downloadTrack(id: id, key: key)
            } else {
                println("No key for track: \(track)")
            }
        } else {
            println("No id for track: \(track)")
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - NSURLSessionDownloadDelegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let taskId = downloadTask.taskDescription
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        println("\(taskId): \(progress)")
        if let cell = cellWithTrackId(taskId) {
            cell.loading = true
            cell.progress = progress
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64,
                    expectedTotalBytes: Int64) {
            println("\(downloadTask): \(fileOffset): \(expectedTotalBytes)")
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        println("Done: \(downloadTask) -> \(location)")
        let taskId = downloadTask.taskDescription
        if let cell = cellWithTrackId(taskId) {
            cell.loading = false
            cell.progress = 1
        }
    }
    
    // MARK: - Functionality

    func refreshFeed() {
        Scraper.getPopularTracks({ tracks in
            self.refreshControl.endRefreshing()
            self.tracks = tracks
        }, onError: { error in
            self.refreshControl.endRefreshing()
            println("Error while refreshing feed: \(error.localizedDescription)")
        })
    }
    
    func downloadTrack(#id: String, key: String) {
        println("Retrieving track: \(id): \(key)")
        Scraper.getSourceURLForTrack(id: id, key: key, onURL: { (url) -> Void in
            if let url = NSURL(string: url) {
                let task = self.bkgSession.downloadTaskWithURL(url)
                task.taskDescription = id
                task.resume()
            } else {
                println("Couldn't create NSURL from \(url)")
            }
        }) { (error) -> Void in
            println(error)
        }
    }
    
    func cellWithTrackId(id: String) -> HypeTrackCell? {
        for (row, track) in enumerate(tracks) {
            if (track["id"].asString == id) {
                return self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0)) as? HypeTrackCell
            }
        }
        return nil
    }
}
