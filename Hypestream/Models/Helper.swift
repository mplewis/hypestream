//
//  Helper.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/21/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import Foundation
import CoreData

let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString

class Helper {
    
    // MARK: - Core Data
    
    class func getTracksWithPredicate(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> (tracks: [Track]?, error: NSError?) {
        let context = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext!
        let request = NSFetchRequest(entityName: "Track")
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        var error: NSError?
        let resultsOp = context.executeFetchRequest(request, error: &error)
        if error != nil {
            return(nil, error)
        }
        let results = resultsOp!
        let tracks = results as? [Track]
        return (tracks, nil)
    }
    
    class func getAllTracks(#sortDescriptors: [NSSortDescriptor]?) -> (tracks: [Track]?, error: NSError?) {
        return getTracksWithPredicate(nil, sortDescriptors: sortDescriptors)
    }
    
    class func getTracksWithId(id: String, sortDescriptors: [NSSortDescriptor]?) -> (tracks: [Track]?, error: NSError?) {
        return getTracksWithPredicate(NSPredicate(format: "hypem_id = %@", id), sortDescriptors: sortDescriptors)
    }
    
    class func getTracksWithState(state: TrackState, sortDescriptors: [NSSortDescriptor]?) -> (tracks: [Track]?, error: NSError?) {
        return getTracksWithPredicate(NSPredicate(format: "state_raw = %i", state.rawValue), sortDescriptors: sortDescriptors)
    }
    
    // MARK: - Error Builders
    
    class func makeError(description: String, code: Int) -> NSError {
        let bundleIdent = NSBundle.mainBundle().bundleIdentifier!
        let info = [NSLocalizedDescriptionKey: description]
        return NSError(domain: bundleIdent, code: code, userInfo: info)
    }
    
    class func makeError(description: String, code: Int, info: NSDictionary) -> NSError {
        let bundleIdent = NSBundle.mainBundle().bundleIdentifier!
        let infoCopy = info.mutableCopy() as NSMutableDictionary
        infoCopy[NSLocalizedDescriptionKey] = description
        let infoFrozen = NSDictionary(dictionary: infoCopy)
        return NSError(domain: bundleIdent, code: code, userInfo: infoFrozen)
    }

}
