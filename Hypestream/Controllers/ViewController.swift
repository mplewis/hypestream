//
//  ViewController.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/17/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSURLSessionDownloadDelegate {

    // MARK: - Interface Builder
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Class Properties

    var tracks: [Track] = [Track]() {
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let row = tableView.cellForRowAtIndexPath(indexPath) as HypeTrackCell
        let track = tracks[indexPath.row]
        track.downloadProgress = 0
        track.downloadInProgress = true
        if let url = NSURL(string: track.source_url) {
            let task = self.bkgSession.downloadTaskWithURL(url)
            task.taskDescription = track.hypem_id
            task.resume()
        } else {
            println("Couldn't create NSURL from \(track.source_url)")
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    // MARK: - NSURLSessionDownloadDelegate
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let taskId = downloadTask.taskDescription
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        println("\(taskId): \(progress)")
        let results = Helper.getTracksWithId(taskId)
        if let error = results.error {
            println(error.localizedDescription)
        } else {
            let track = results.tracks![0]
            track.downloadInProgress = true
            track.downloadProgress = progress
        }
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        println("\(downloadTask): \(fileOffset): \(expectedTotalBytes)")
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL source: NSURL) {
        let taskId = downloadTask.taskDescription
        println("\(taskId): done -> \(source)")
        let fileManager = NSFileManager.defaultManager()
        let results = Helper.getTracksWithId(taskId)
        if let error = results.error {
            // Error getting track with ID = task ID.
            println(error.localizedDescription)
            // Try to delete downloaded tmp file. We don't care if the deletion of a temp file fails.
            fileManager.removeItemAtURL(source, error: nil)
        } else {
            let track = results.tracks![0]
            track.downloadInProgress = false
            track.downloadProgress = 1
            let destString = documentsPath.stringByAppendingPathComponent("\(track.hypem_id).mp3")
            if let dest = NSURL(fileURLWithPath: destString) {
                println("\(taskId): moving -> \(dest)")
                var fileError: NSError?
                fileManager.copyItemAtURL(source, toURL: dest, error: &fileError)
                if let error = fileError {
                    // Error moving file to Documents folder.
                    println(error.localizedDescription)
                    // Try to delete downloaded tmp file. We don't care if the deletion of a temp file fails.
                    fileManager.removeItemAtURL(source, error: nil)
                } else {
                    track.local_file_url = destString
                    track.state = .Inbox
                    println("\(taskId): moved -> \(dest)")
                    var dbError: NSError?
                    (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext!.save(&dbError)
                    if (dbError != nil) {
                        println(dbError!.localizedDescription)
                    }
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
            } else {
                println("Couldn't convert dest to URL: \(destString)")
            }
        }
    }
    
    // MARK: - Functionality

    func refreshFeed() {
        let predicate = NSPredicate(format: "state_raw = %i", TrackState.NotDownloaded.rawValue)
        let results = Helper.getTracksWithPredicate(predicate)
        if let error = results.error {
            println(error.localizedDescription)
        } else {
            self.tracks = results.tracks!
        }
        self.refreshControl.endRefreshing()
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
