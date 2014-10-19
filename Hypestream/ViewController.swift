//
//  ViewController.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/17/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var outputView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshFeed("")
    }

    @IBAction func refreshFeed(AnyObject) {
        outputView.text = "Loading..."
        let url = NSURL(string: "http://hypem.com/playlist/popular/3day/json/1/data.js")
        let request = NSURLRequest(URL: url)
        let queue = NSOperationQueue.mainQueue()
        let cookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue) {(response, jsonData, error) in
            // Parse JSON data
            var err: NSError?
            let data: AnyObject? = NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers, error: &err)
            if (data == nil) {
                println("No data received")
                return
            }
            if (err != nil) {
                println("JSON error: \(err!.localizedDescription)")
                return
            }
            let tracksMaybe =  data as? Dictionary<String, AnyObject>;
            if (tracksMaybe != nil) {
                println("Successfully retrieved tracks")
            } else {
                println("Couldn't retrieve tracks")
                return
            }
            let tracks = tracksMaybe!

            // Get track count
            var maxIndex = 0;
            for key in tracks.keys {
                let keyInt = key.toInt()
                if (keyInt != nil && keyInt > maxIndex) {
                    maxIndex = keyInt!
                }
            }
            
            // Validate all tracks
            var validTracks = [AnyObject]()
            for index in 0...maxIndex {
                if let track: AnyObject = tracks[String(index)] {
                    validTracks.append(track)
                }
            }
            
            // Print track titles to screen
            var output = ""
            for track in validTracks {
                let artist = track["artist"]
                let title = track["title"]
                if (artist != nil && title != nil) {
                    let a: AnyObject? = artist
                    let t: AnyObject? = title
                    output += "\(a!) - \(t!)\n"
                } else {
                    println("Couldn't get artist or title for \(index)")
                }
            }
            self.outputView.text = output
            
            // Get an mp3 url for each track
            for track in validTracks {
                // TODO
            }
        }
    }
}
