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
        let homeUrl = NSURL(string: "http://hypem-com-sy61nts0plpb.runscope.net/popular/1")
        
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
                var output = ""
                for track in tracks! {
                    let id = track["id"]
                    let key = track["key"]
                    let artist = track["artist"]
                    let title = track["song"]

                    let mediaUrl = NSURL(string: "http://hypem-com-sy61nts0plpb.runscope.net/serve/source/\(id)/\(key)")
                    let mediaRequest = NSMutableURLRequest(URL: mediaUrl)
                    mediaRequest.HTTPMethod = "POST"
                    
                    NSURLConnection.sendAsynchronousRequest(mediaRequest, queue: queue) { (response, jsonData, error) in
                        let jsonString: String = NSString(data: jsonData, encoding: NSUTF8StringEncoding)
                        let jsonData = JSON(string: jsonString)
                        let streamUrl = jsonData["url"]
                        println("\(artist) - \(title): \(streamUrl)")
                    }
                    
                    output += "\(artist) - \(title)\n"
                }
                self.outputView.text = output
            } else {
                println("Failure on splitting start")
            }
        }
    }
}
