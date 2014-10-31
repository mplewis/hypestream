//
//  Track.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/30/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import Foundation
import CoreData

enum TrackState: Int {
    case NotDownloaded = 1, Downloading, DownloadFailed, Inbox, Favorite, Trash, Deleted
}

class Track: NSManagedObject {
    
    @NSManaged var artist: String
    @NSManaged var title: String
    @NSManaged var hypem_id: String
    @NSManaged var state_raw: NSNumber
    @NSManaged var source_url: String
    @NSManaged var local_file_url: String
    @NSManaged var last_accessed: NSDate
    @NSManaged var download_attempts: NSNumber
    var state: TrackState? {
        set {
            if let targetState = newValue {
                self.state_raw = targetState.rawValue
            } else {
                self.state_raw = 0
            }
        }
        get {
            return TrackState(rawValue: self.state_raw.integerValue)
        }
    }
    
}
