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
        let queue = NSOperationQueue.mainQueue()
        let feedUrl = NSURL(string: "http://hypem.com/playlist/popular/3day/json/1/data.js")
        let request = NSURLRequest(URL: feedUrl)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue) { (response, jsonData, error) in
            let httpResponse = response as NSHTTPURLResponse

            // Parse JSON data
            let tracks = JSON(string: NSString(data: jsonData, encoding: NSUTF8StringEncoding))
            
            // Get track count
            var maxIndex = 0;
            for (key, value) in tracks {
                // HypeM track numbers are strings. Try to cast them to ints.
                if let k = (key as String).toInt() {
                    if k > maxIndex {
                        maxIndex = k
                    }
                }
            }
            
            // Validate all tracks
            var validTracks = [JSON]()
            for index in 0...maxIndex {
                let indexString = String(index)
                validTracks.append(tracks[indexString])
            }
            
            // Print track titles to screen
            var output = ""
            for track in validTracks {
                let artist = track["artist"]
                let title = track["title"]
                output += "\(artist) - \(title)\n"
            }
            self.outputView.text = output
            
            // Get an mp3 url for each track
            for track in validTracks {
                // TODO
            }
        }
    }
}
