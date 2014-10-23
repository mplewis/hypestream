//
//  HypeTrackCell.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/23/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import UIKit

class HypeTrackCell: UITableViewCell {
    var artist: String
    var title: String
    
    required init(coder aDecoder: NSCoder) {
        self.artist = ""
        self.title = ""
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
