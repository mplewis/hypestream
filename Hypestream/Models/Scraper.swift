//
//  Scraper.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/21/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import Foundation
import CoreData

let queue = NSOperationQueue.mainQueue()

class Scraper {
    
    // MARK: - Web Scraping
    
    class func getPopularTracks(onTracks: ([JSON]) -> Void, onError: (NSError) -> Void) {
        let homeUrl = NSURL(string: "http://hypem.com/popular/1")!
        let bundleIdent = NSBundle.mainBundle().bundleIdentifier!
        
        NSURLConnection.sendAsynchronousRequest(NSURLRequest(URL: homeUrl), queue: queue) { (response, htmlData, error) in
            if (error != nil) {
                onError(error); return
            }

            if (htmlData == nil) {
                onError(Helper.makeError("Couldn't scrape HTML from Hype Machine", code: -104)); return
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
                    onError(Helper.makeError("Couldn't load tracks from JSON", code: -101)); return
                }
            } else {
                onError(Helper.makeError("Couldn't parse JSON", code: -102)); return
            }
        }
    }
    
    class func getSourceURLForTrack(#id: String, key: String, onURL: (String) -> Void, onError: (NSError) -> Void) {
        let mediaUrl = NSURL(string: "http://hypem.com/serve/source/\(id)/\(key)")!
        let mediaRequest = NSMutableURLRequest(URL: mediaUrl)
        mediaRequest.HTTPMethod = "POST"
        
        NSURLConnection.sendAsynchronousRequest(mediaRequest, queue: queue) { (response, rawJsonData, error) in
            if (error != nil) {
                onError(error); return
            }

            let httpResponseOp = response as? NSHTTPURLResponse
            if (httpResponseOp == nil) {
                onError(Helper.makeError("Got a nil HTTP response", code: -204)); return
            }
            let httpResponse = httpResponseOp!

            if (httpResponse.statusCode != 200) {
                let info = ["statusCode": httpResponse.statusCode];
                onError(Helper.makeError("Got a non-200 status code", code: -201, info: info)); return
            }
            if (rawJsonData == nil) {
                onError(Helper.makeError("Couldn't parse JSON", code: -202)); return
            }
            let json = JSON(string: NSString(data: rawJsonData, encoding: NSUTF8StringEncoding)!)

            if let streamUrlString = json["url"].asString {
                onURL(streamUrlString); return
            } else {
                onError(Helper.makeError("Couldn't find stream URL in JSON", code: -203)); return
            }
        }
    }
    
    // MARK: - Inserting Scraped Data into DB
    
    class func insertTrackObjFromJSON(rawTrack: JSON, onTrack: (Track) -> Void, onError: (NSError) -> Void) {
        let context = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext!
        let idOp = rawTrack["id"].asString
        let keyOp = rawTrack["key"].asString
        let artistOp = rawTrack["artist"].asString
        let titleOp = rawTrack["song"].asString
        if (idOp != nil && keyOp != nil && artistOp != nil && titleOp != nil) {
            let id = idOp!
            let key = keyOp!
            let artist = artistOp!
            let title = titleOp!

            Scraper.getSourceURLForTrack(id: id, key: key, onURL: { url in
                let track = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: context) as Track
                track.hypem_id = id
                track.artist = artist
                track.title = title
                track.source_url = url
                track.state = .ToDownload
                var error: NSError?
                context.save(&error)
                if (error == nil) {
                    onTrack(track); return
                } else {
                    onError(error!); return
                }
            }, onError: onError)
        } else {
            let info = ["rawTrack": rawTrack.toString(pretty: false)]
            onError(Helper.makeError("Track JSON id, key, artist or title were nil", code: -301, info: info)); return
        }
    }
    
    class func addNewTracksToDB(onSuccess: (added: [Track], skipped: [Track], errors: [NSError]) -> Void, onError: (NSError) -> Void) {
        let context = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext!
        Scraper.getPopularTracks({ jsonTracks in
            var added = [Track]()
            var skipped = [Track]()
            var errors = [NSError]()

            let addedLock = NSLock()
            let skippedLock = NSLock()
            let errorsLock = NSLock()

            let queue = dispatch_get_global_queue(0, 0)
            let group = dispatch_group_create()
            
            for jsonTrack in jsonTracks {
                dispatch_group_async(group, queue) {
                    let idOp = jsonTrack["id"].asString
                    if let id = idOp {
                        let request = NSFetchRequest(entityName: "Track")
                        request.predicate = NSPredicate(format: "hypem_id = %@", id)

                        var error: NSError?
                        let resultsOp = context.executeFetchRequest(request, error: &error)
                        if error != nil {
                            onError(error!); return
                        }
                        let results = resultsOp!
                        
                        if results.count > 0 {
                            skippedLock.lock()
                            skipped.append(results[0] as Track)
                            skippedLock.unlock()
                        } else {
                            let sem = dispatch_semaphore_create(0)
                            Scraper.insertTrackObjFromJSON(jsonTrack, onTrack: { track in
                                dispatch_semaphore_signal(sem)
                                addedLock.lock()
                                added.append(track)
                                addedLock.unlock()
                            }, onError: { error in
                                dispatch_semaphore_signal(sem)
                                errorsLock.lock()
                                errors.append(error)
                                errorsLock.unlock()
                            })
                            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
                        }
                        
                    } else {
                        let info = ["track": jsonTrack.toString(pretty: false)]
                        errorsLock.lock()
                        errors.append(Helper.makeError("No ID found for track", code: -401, info: info))
                        errorsLock.unlock()
                    }
                }
            }
            
            dispatch_group_notify(group, queue) {
                onSuccess(added: added, skipped: skipped, errors: errors); return
            }
        }, onError: onError)
    }
}
