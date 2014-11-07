//
//  HypeTrackCell.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/23/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import UIKit

class HypeTrackCell: UITableViewCell, TrackDownloadDelegate {
    
    // MARK: - Interface Builder
    
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressBar: M13ProgressViewBar!
    @IBOutlet weak var daysCountLabel: UILabel!
    @IBOutlet weak var daysAgoLabel: UILabel!

    // MARK: - UITableViewCell
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.progressBar.showPercentage = false
        self.loading = false
    }

    // MARK: - All tracks
    
    var artist: String = "" {
        didSet {
            self.artistLabel.text = self.artist
        }
    }
    var title: String = "" {
        didSet {
            self.titleLabel.text = self.title
        }
    }
    
    // MARK: - Download progress
    
    var loading: Bool = false {
        didSet {
            self.progressBar.hidden = !self.loading
        }
    }
    var progress: Float = 0 {
        didSet {
            self.progressBar.setProgress(CGFloat(self.progress), animated: true)
        }
    }
    
    // MARK: - Last Accessed
    
    var lastAccessed: NSDate? {
        didSet {
            if (lastAccessed == nil) {
                daysCountLabel.hidden = true
                daysAgoLabel.hidden = true
            } else {
                let seconds = Int(Double(-lastAccessed!.timeIntervalSinceNow))
                let minutes = seconds / 60
                daysCountLabel.text = String(minutes)
                daysAgoLabel.text = "minutes ago"
                daysCountLabel.hidden = false
                daysAgoLabel.hidden = false
            }
        }
    }
    
    // MARK: - Callable helper functions
    
    func setProgressNow(progress: Float) {
        self.progressBar.setProgress(CGFloat(progress), animated: false)
        self.progress = progress
    }
    
    func resetProgress() {
        self.setProgressNow(0)
    }
    
    // MARK: - TrackDownloadDelegate functions
    
    func trackDidStartDownloading(track: Track) {
        self.resetProgress()
        self.loading = true
    }
    
    func trackDidFinishDownloading(track: Track) {
        self.loading = false
    }
    
    func trackDidUpdateProgress(track: Track, progress: Float) {
        self.progress = progress
    }

}
