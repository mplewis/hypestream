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
        cell.textLabel!.text = title
        cell.detailTextLabel!.text = artist
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        let track = tracks[indexPath.row]
        let id = track["id"]
        let key = track["key"]
        let artist = track["artist"]
        let title = track["song"]
        
        let mediaUrl = NSURL(string: "http://hypem.com/serve/source/\(id)/\(key)")
        let mediaRequest = NSMutableURLRequest(URL: mediaUrl)
        mediaRequest.HTTPMethod = "POST"
        
        NSURLConnection.sendAsynchronousRequest(mediaRequest, queue: queue) { (response, jsonData, error) in
            if (jsonData == nil) {
                println("Couldn't retrieve stream URL for \(artist) - \(title)")
                return
            }
            let jsonString: String = NSString(data: jsonData, encoding: NSUTF8StringEncoding)
            let jsonData = JSON(string: jsonString)
            if let streamUrlString = jsonData["url"].asString {
                println("Retrieving track from \(streamUrlString)")

                var error: NSError?
                let streamUrl = NSURL(string: streamUrlString)
                let trackData = NSData.dataWithContentsOfURL(streamUrl, options: nil, error: &error)
                if (error != nil) {
                    println(error!.localizedDescription)
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
                println("Couldn't get stream URL for \(artist) - \(title)")
                return
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    @IBAction func refreshFeed(AnyObject) {
        let homeUrl = NSURL(string: "http://hypem.com/popular/1")
        
        NSURLConnection.sendAsynchronousRequest(NSURLRequest(URL: homeUrl), queue: queue) { (response, htmlData, error) in
            if (htmlData == nil) {
                println("Couldn't scrape HTML from Hype Machine")
                return
            }
            let htmlString = NSString(data: htmlData, encoding: NSUTF8StringEncoding)
            let startScript = "<script type=\"application/json\" id=\"displayList-data\">"
            let endScript = "</script>"
            if let partial = htmlString.componentsSeparatedByString(startScript)[1] as? String {
                let script = partial.componentsSeparatedByString(endScript)[0]
                let scriptJson = JSON(string: script)
                let retrieved = scriptJson["tracks"].asArray
                if (retrieved == nil) {
                    println("Couldn't load tracks")
                    return
                }

                self.tracks = retrieved!
            } else {
                println("Failure on splitting start")
            }
        }
    }
}
