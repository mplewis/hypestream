//
//  Scraper.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/21/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import Foundation

class Scraper {
    class func getPopularTracks(callback: (tracks: [JSON]?, error: NSError?) -> Void) {
        let homeUrl = NSURL(string: "http://hypem.com/popular/1")
        let bundleIdent = NSBundle.mainBundle().bundleIdentifier!
        
        NSURLConnection.sendAsynchronousRequest(NSURLRequest(URL: homeUrl), queue: queue) { (response, htmlData, error) in
            if (htmlData == nil) {
                callback(tracks: nil, error: Helper.makeError("Couldn't scrape HTML from Hype Machine", code: -100)); return
            }
            if let givenError = error {
                callback(tracks: nil, error: givenError); return
            }
            
            let htmlString = NSString(data: htmlData, encoding: NSUTF8StringEncoding)
            let startScript = "<script type=\"application/json\" id=\"displayList-data\">"
            let endScript = "</script>"
            if let partial = htmlString.componentsSeparatedByString(startScript)[1] as? String {
                let script = partial.componentsSeparatedByString(endScript)[0]
                let scriptJson = JSON(string: script)
                if let retrieved = scriptJson["tracks"].asArray {
                    callback(tracks: retrieved, error: nil); return
                } else {
                    callback(tracks: nil, error: Helper.makeError("Couldn't load tracks from Hype Machine JSON", code: -101)); return
                }
            } else {
                callback(tracks: nil, error: Helper.makeError("Couldn't parse JSON from Hype Machine", code: -102)); return
            }
        }
    }
    
    class func getSourceURLForTrack(id: String, key: String, callback: (url: String?, error: NSError?) -> Void) {
        let mediaUrl = NSURL(string: "http://hypem.com/serve/source/\(id)/\(key)")
        let mediaRequest = NSMutableURLRequest(URL: mediaUrl)
        mediaRequest.HTTPMethod = "POST"
        
        NSURLConnection.sendAsynchronousRequest(mediaRequest, queue: queue) { (response, jsonData, error) in
            let httpResponse = response as NSHTTPURLResponse
            if (httpResponse.statusCode != 200) {
                callback(url: nil, error: Helper.makeError("Got a non-200 status code: \(httpResponse.statusCode)", code: -201)); return
            }
            if (jsonData == nil) {
                callback(url: nil, error: Helper.makeError("Couldn't retrieve stream URL", code: -202)); return
            }
            let jsonData = JSON(string: NSString(data: jsonData, encoding: NSUTF8StringEncoding))
            if let streamUrlString = jsonData["url"].asString {
                callback(url: streamUrlString, error: nil); return
            } else {
                callback(url: nil, error: Helper.makeError("Couldn't parse URL from response data", code: -203)); return
            }
        }
    }
}
