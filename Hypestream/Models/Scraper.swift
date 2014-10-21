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
                let info = [NSLocalizedDescriptionKey: "Couldn't scrape HTML from Hype Machine"]
                let error = NSError(domain: bundleIdent, code: -100, userInfo: info)
                callback(tracks: nil, error: error)
                return
            }
            if let givenError = error {
                callback(tracks: nil, error: givenError)
                return
            }
            
            let htmlString = NSString(data: htmlData, encoding: NSUTF8StringEncoding)
            let startScript = "<script type=\"application/json\" id=\"displayList-data\">"
            let endScript = "</script>"
            if let partial = htmlString.componentsSeparatedByString(startScript)[1] as? String {
                let script = partial.componentsSeparatedByString(endScript)[0]
                let scriptJson = JSON(string: script)
                if let retrieved = scriptJson["tracks"].asArray {
                    callback(tracks: retrieved, error: nil)
                    return
                } else {
                    let info = [NSLocalizedDescriptionKey: "Couldn't load tracks from Hype Machine JSON"]
                    let error = NSError(domain: bundleIdent, code: -101, userInfo: info)
                    callback(tracks: nil, error: error)
                    return
                }
            } else {
                let info = [NSLocalizedDescriptionKey: "Couldn't parse JSON from Hype Machine"]
                let error = NSError(domain: bundleIdent, code: -102, userInfo: info)
                callback(tracks: nil, error: error)
                return
            }
        }
    }
}
