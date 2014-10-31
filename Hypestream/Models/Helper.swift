//
//  Helper.swift
//  Hypestream
//
//  Created by Matthew Lewis on 10/21/14.
//  Copyright (c) 2014 Kestrel Development. All rights reserved.
//

import Foundation

let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString

class Helper {
    
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
