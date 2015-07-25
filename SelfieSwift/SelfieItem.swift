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
    let photoImage:UIImage
    let isChecked = false
    
    private struct SelfieConstants {
        static let CacheSubDir = "selfieThumb"
        static let PhotoQuality:CGFloat = 0.9
        static let ThumbNailQuality:CGFloat = 0.75
    }
   
    init(fileName:String, photo:UIImage, thumbSize:CGSize) {
        // store the photo as JPEG in the user documents folder
        let fileManager = NSFileManager()
        let documentsUrl = try! fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask,appropriateForURL: nil, create: true)
        photoPath = documentsUrl.path! + fileName + ".jpg"
        thumbPath = SelfieItem.getThumbPath(fileName)
        thumbImage = SelfieItem.newThumb(targetSize: thumbSize, imageJPEGPath: photoPath, thumbPath: thumbPath)
        photoImage = photo
        // save the photo
        if let jpegData = UIImageJPEGRepresentation(photoImage, SelfieConstants.PhotoQuality) {
            jpegData.writeToFile(photoPath, atomically: true)
        }
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
    
    private class func getThumbPath(fileName: String) -> String {
        let fileManager = NSFileManager()
        let cacheUrl = try! fileManager.URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        let cachePath = cacheUrl.path! + "/" + SelfieConstants.CacheSubDir
        
        // if the thumbNail subdirectory doesn't exist, create it
        if !fileManager.fileExistsAtPath(cachePath) {
            try! fileManager.createDirectoryAtPath(cachePath, withIntermediateDirectories: true, attributes: nil)
        }
        return cachePath+"/"+fileName+".jpg"
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
                if let jpegData = UIImageJPEGRepresentation(thumbImage!, SelfieConstants.ThumbNailQuality) {
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
