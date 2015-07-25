//
//  SelfieItem.swift
//  SelfieSwift
//
//  Created by Jeff Greenberg on 7/24/15.
//  Copyright © 2015 Jeff Greenberg. All rights reserved.
//
//  SelfieItem holds all data related to a Selfie
//
// UIKit is only needed to manage the imageData associated with the Selfie
//
import Foundation
import UIKit

class SelfieItem {
    private let photoPath:String
    private let thumbPath:String
    let thumbImage:UIImage?
    let isChecked = false
    
    private struct SelfieConstants {
        static let CacheSubDir = "selfieThumb"
        static let JpegQuality:CGFloat = 0.75
    }
   
    init(fileName:String, fullSizsePhotoPath:String, thumbSize:CGSize) {
        photoPath = fullSizsePhotoPath
        thumbPath = SelfieItem.getThumbPath(fullSizsePhotoPath)
        thumbImage = SelfieItem.newThumb(targetSize: thumbSize, imageJPEGPath: fullSizsePhotoPath, thumbPath: thumbPath)
    }
    
    var label:String {
        get {
            let defaults = NSUserDefaults.standardUserDefaults()
            if let storedLabel = defaults.stringForKey(photoFileName) {
                return storedLabel
            } else {
                return photoFileName
            }
        }
        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setValue(newValue, forKey: photoFileName)
        }
    }
    
    private var photoFileName:String {
        return photoPath.lastPathComponent
    }
    
    // MARK: - static class functions
    
    private class func getThumbPath(imagePath: String) -> String {
        let fileManager = NSFileManager()
        let cacheUrl = try! fileManager.URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        let cachePath = cacheUrl.path! + "/" + SelfieConstants.CacheSubDir
        
        // if the thumbNail subdirectory doesn't exist, create it
        if !fileManager.fileExistsAtPath(cachePath) {
            try! fileManager.createDirectoryAtPath(cachePath, withIntermediateDirectories: true, attributes: nil)
        }
        return cachePath+"/"+imagePath.lastPathComponent
    }
    
    private class func newThumb(targetSize targetSize:CGSize, imageJPEGPath:String, thumbPath:String) -> UIImage? {
        let thumbImage:UIImage?
        let fileManager = NSFileManager()
        // if the thumbNail exists, just read it from the cache
        // otherwise create one
        if fileManager.fileExistsAtPath(thumbPath) {
            thumbImage = UIImage(contentsOfFile: thumbPath)
        } else {
            if let originalImage = UIImage(contentsOfFile: imageJPEGPath) {
                let scaleFactor = min(originalImage.size.width/targetSize.width, originalImage.size.height/targetSize.height)
                let newSize = CGSize(width: originalImage.size.width*scaleFactor, height: originalImage.size.height*scaleFactor)
                thumbImage = imageWithImage(originalImage, scaledToSize: newSize)
                if let jpegData = UIImageJPEGRepresentation(thumbImage!, SelfieConstants.JpegQuality) {
                    jpegData.writeToFile(thumbPath, atomically: true)
                }
            } else {
                thumbImage = nil
            }
        }
        return thumbImage
    }
    
}

// MARK: - Non-class helper functions

func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
    image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
    let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage
}
