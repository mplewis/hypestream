//
//  HypeTrackCell.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/23/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import UIKit

class HypeTrackCell: UITableViewCell {
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressBar: M13ProgressViewBar!

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
    
    func resetProgress() {
        self.progressBar.setProgress(0, animated: false)
        self.progress = 0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.progressBar.showPercentage = false
        self.loading = false
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}