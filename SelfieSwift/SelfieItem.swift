//
//  SelfieItem.swift
//  SelfieSwift
//
//  Created by Jeff Greenberg on 7/24/15.
//  Copyright © 2015 Jeff Greenberg. All rights reserved.
//
//  SelfieItem is a non-UI class to hold all data related to a Selfie
//
import Foundation

class SelfieItem {
    private var label:String
    private let photoPath:String
    private let thumbPath:String
    
    init(fileName:String, photoPath:String, thumbHeight: Int, thumbWidth: Int) {
        self.photoPath = photoPath
        
    }
    
    private func newThumb(targetH:Int, targetW:Int, imageJPEGPath:String) -> NSData {
        let fileManager = NSFileManager()
        let cacheUrl: NSURL?
        do {
            cacheUrl = try fileManager.URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        } catch _ {
            print("couldn't get cache dir")
        }
        
    }
    
}
