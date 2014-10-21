//
//  Helper.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/21/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import Foundation

class Helper {
    class func makeError(description: String, code: Int) -> NSError {
        let bundleIdent = NSBundle.mainBundle().bundleIdentifier!
        let info = [NSLocalizedDescriptionKey: description]
        return NSError(domain: bundleIdent, code: code, userInfo: info)
    }
}
