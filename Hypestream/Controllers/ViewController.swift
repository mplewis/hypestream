//
//  ViewController.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/17/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import UIKit

let queue = NSOperationQueue.mainQueue()
let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!

    var tracks: [JSON] = [JSON]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshFeed("")
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracks.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("SongCell") as UITableViewCell
        let track = tracks[indexPath.row]
        let artist = track["artist"].asString
        let title = track["song"].asString
        cell.textLabel.text = title
        cell.detailTextLabel!.text = artist
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let track = tracks[indexPath.row]
        let idOp = track["id"].asString
        let keyOp = track["key"].asString
        let artistOp = track["artist"].asString
        let titleOp = track["song"].asString
        
        if (idOp == nil || keyOp == nil) {
            println("Missing ID or key for \(track)")
            return
        }

        if (artistOp == nil || titleOp == nil) {
            println("Missing artist or title for \(track)")
            return
        }
        
        let id = idOp!
        let key = keyOp!
        let artist = artistOp!
        let title = titleOp!

        Scraper.getSourceURLForTrack(id, key: key) { (urlReturned, error) -> Void in
            if let errorReturned = error {
                println(errorReturned.localizedDescription)
            } else if let streamUrlString = urlReturned {
                println("Retrieving track from \(streamUrlString)")
                
                var error: NSError?
                let streamUrl = NSURL(string: streamUrlString)!
                let trackDataOp = NSData(contentsOfURL:streamUrl)
                if (trackDataOp == nil) {
                    println("Couldn't load NSData with contentsOfURL: \(streamUrl)")
                    return
                }
                let trackData = trackDataOp!
                if let errorNSData = error {
                    println(errorNSData.localizedDescription)
                    return
                }
                
                let targetPath: String = NSString.pathWithComponents([documentsPath, "\(artist) - \(title).mp3"])
                let writeSuccess = trackData.writeToFile(targetPath, atomically: true)
                if (writeSuccess) {
                    println("Write successful for \(targetPath)")
                } else {
                    println("Write failed for \(targetPath)")
                }
            } else {
                println("Neither URL nor error returned from Scraper.getSourceURLForTrack")
            }
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    @IBAction func refreshFeed(AnyObject) {
        Scraper.getPopularTracks { (tracks, error) -> Void in
            if let errorReturned = error {
                println(errorReturned.localizedDescription)
            } else if let tracksReturned = tracks {
                self.tracks = tracksReturned
            } else {
                println("No tracks or error returned from Scraper.getPopularTracks")
            }
        }
    }
}
