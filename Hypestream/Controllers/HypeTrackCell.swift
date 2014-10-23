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
    var artist: String {
        set {
            self.artist = newValue
            self.artistLabel.text = newValue
        }
        get {
            return self.artist
        }
    }
    var title: String {
        set {
            self.title = newValue
            self.titleLabel.text = newValue
        }
        get {
            return self.title
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.artist = ""
        self.title = ""
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
