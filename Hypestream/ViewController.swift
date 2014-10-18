//
//  ViewController.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/17/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {
    @IBOutlet weak var outputView: UITextView!

    @IBAction func refreshFeed(AnyObject) {
        outputView.text = "Loading..."
        let url = NSURL(string: "http://hypem.com/playlist/popular/3day/json/1/data.js")
        let request = NSURLRequest(URL: url)
        let queue = NSOperationQueue.mainQueue()
        let cookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue) {(response, jsonData, error) in
            let cookies = cookieStorage.cookiesForURL(url)
            println("Cookies: \(cookies)")

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
            if let tracks = data as? Dictionary<String, AnyObject> {
                var maxIndex = 0;
                for key in tracks.keys {
                    let keyInt = key.toInt()
                    if (keyInt != nil && keyInt > maxIndex) {
                            maxIndex = keyInt!
                    }
                }
                var output = ""
                for index in 0...maxIndex {
                    if let track: AnyObject = tracks[String(index)] {
                        let artist = track["artist"]
                        let title = track["title"]
                        if (artist != nil && title != nil) {
                            let a: AnyObject? = artist
                            let t: AnyObject? = title
                            output += "\(index): \(a!) - \(t!)\n"
                        } else {
                            println("Couldn't get artist or title for \(index)")
                        }
                    } else {
                        println("Couldn't get track from String(\(index))")
                    }
                }
                self.outputView.text = output
            } else {
                println("Couldn't cast data to Dictionary<Int, AnyObject>")
            }
        }
    }
}
