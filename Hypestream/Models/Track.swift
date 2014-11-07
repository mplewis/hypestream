//
//  Track.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/30/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Protocols

protocol TrackDownloadDelegate {
    func trackDidStartDownloading(track: Track)
    func trackDidFinishDownloading(track: Track)
    func trackDidUpdateProgress(track: Track, progress: Float)
}

// MARK: - Custom Types

enum TrackState: Int {
    case NotDownloaded = 1, Downloading, DownloadFailed, Inbox, Favorite, Trash, Deleted
}

class Track: NSManagedObject {
    
    // MARK: - NSManaged Variables
    
    @NSManaged var artist: String
    @NSManaged var title: String
    @NSManaged var hypem_id: String
    @NSManaged var state_raw: NSNumber
    @NSManaged var source_url: String
    @NSManaged var local_file_url: String
    @NSManaged var last_accessed: NSDate
    @NSManaged var download_attempts: NSNumber
    
    // MARK: - Custom-Typed Stored Variables
    
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
    
    // MARK: - Download Progress

    var trackDownloadDelegate: TrackDownloadDelegate?
    
    var downloadProgress: Float = 0.0 {
        didSet {
            self.trackDownloadDelegate?.trackDidUpdateProgress(self, progress: self.downloadProgress)
        }
    }

    var downloadInProgress: Bool = false {
        willSet {
            if (newValue != self.downloadInProgress) {
                if (newValue) {
                    self.trackDownloadDelegate?.trackDidStartDownloading(self)
                } else {
                    self.trackDownloadDelegate?.trackDidFinishDownloading(self)
                }
            }
        }
    }
    
}
