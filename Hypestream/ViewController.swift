//
//  ViewController.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/17/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import UIKit

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
        
    }

    @IBAction func refreshFeed(AnyObject) {
        let queue = NSOperationQueue.mainQueue()
        let homeUrl = NSURL(string: "http://hypem.com/popular/1")
        
        NSURLConnection.sendAsynchronousRequest(NSURLRequest(URL: homeUrl), queue: queue) { (response, htmlData, error) in
            let htmlString = NSString(data: htmlData, encoding: NSUTF8StringEncoding)
            let startScript = "<script type=\"application/json\" id=\"displayList-data\">"
            let endScript = "</script>"
            if let partial = htmlString.componentsSeparatedByString(startScript)[1] as? String {
                let script = partial.componentsSeparatedByString(endScript)[0]
                let scriptJson = JSON(string: script)
                let tracks = scriptJson["tracks"].asArray
                if (tracks == nil) {
                    println("Couldn't load tracks")
                    return
                }

                self.tracks = tracks!

                for track in tracks! {
                    let id = track["id"]
                    let key = track["key"]
                    let artist = track["artist"]
                    let title = track["song"]

                    let mediaUrl = NSURL(string: "hypem.com/serve/source/\(id)/\(key)")
                    let mediaRequest = NSMutableURLRequest(URL: mediaUrl)
                    mediaRequest.HTTPMethod = "POST"
                    
                    NSURLConnection.sendAsynchronousRequest(mediaRequest, queue: queue) { (response, jsonData, error) in
                        let jsonString: String = NSString(data: jsonData, encoding: NSUTF8StringEncoding)
                        let jsonData = JSON(string: jsonString)
                        let streamUrl = jsonData["url"]
                        println("\(artist) - \(title): \(streamUrl)")
                    }
                }
            } else {
                println("Failure on splitting start")
            }
        }
    }
}
