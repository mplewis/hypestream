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
    
    // MARK: - UITableViewCell
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.progressBar.showPercentage = false
        self.loading = false
    }

    // MARK: - Settable properties
    
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
