//
//  Scraper.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/21/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import Foundation

let queue = NSOperationQueue.mainQueue()

class Scraper {
    class func getPopularTracks(onTracks: ([JSON]) -> Void, onError: (NSError) -> Void) {
        let homeUrl = NSURL(string: "http://hypem.com/popular/1")!
        let bundleIdent = NSBundle.mainBundle().bundleIdentifier!
        
        NSURLConnection.sendAsynchronousRequest(NSURLRequest(URL: homeUrl), queue: queue) { (response, htmlData, error) in
            if let givenError = error {
                onError(givenError); return
            }
            if (htmlData == nil) {
                onError(Helper.makeError("Couldn't scrape HTML from Hype Machine", code: -100)); return
            }
            
            let htmlString = NSString(data: htmlData, encoding: NSUTF8StringEncoding)!
            let startScript = "<script type=\"application/json\" id=\"displayList-data\">"
            let endScript = "</script>"
            if let partial = htmlString.componentsSeparatedByString(startScript)[1] as? String {
                let script = partial.componentsSeparatedByString(endScript)[0]
                let scriptJson = JSON(string: script)
                if let retrieved = scriptJson["tracks"].asArray {
                    onTracks(retrieved); return
                } else {
                    onError(Helper.makeError("Couldn't load tracks from Hype Machine JSON", code: -101)); return
                }
            } else {
                onError(Helper.makeError("Couldn't parse JSON from Hype Machine", code: -102)); return
            }
        }
    }
    
    class func getSourceURLForTrack(id: String, key: String, onURL: (String) -> Void, onError: (NSError) -> Void) {
        let mediaUrl = NSURL(string: "http://hypem.com/serve/source/\(id)/\(key)")!
        let mediaRequest = NSMutableURLRequest(URL: mediaUrl)
        mediaRequest.HTTPMethod = "POST"
        
        NSURLConnection.sendAsynchronousRequest(mediaRequest, queue: queue) { (response, jsonData, error) in
            let httpResponseOp = response as? NSHTTPURLResponse
            if (httpResponseOp == nil) {
                onError(Helper.makeError("Got a nil HTTP response", code: -204)); return
            }
            let httpResponse = httpResponseOp!

            if (httpResponse.statusCode != 200) {
                onError(Helper.makeError("Got a non-200 status code: \(httpResponse.statusCode)", code: -201)); return
            }
            if (jsonData == nil) {
                onError(Helper.makeError("Couldn't retrieve stream URL", code: -202)); return
            }
            let jsonData = JSON(string: NSString(data: jsonData, encoding: NSUTF8StringEncoding)!)

            if let streamUrlString = jsonData["url"].asString {
                onURL(streamUrlString); return
            } else {
                onError(Helper.makeError("Couldn't parse URL from response data", code: -203)); return
            }
        }
    }
}
