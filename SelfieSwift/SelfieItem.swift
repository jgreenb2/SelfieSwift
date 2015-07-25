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
    private let thumbImage:UIImage?
    private let isChecked = false
    
    private struct SelfieConstants {
        static let CacheSubDir = "selfieThumb"
        static let JpegQuality:CGFloat = 0.75
    }
   
    init(fileName:String, fullSizsePhotoPath:String, thumbHeight: Int, thumbWidth: Int) {
        photoPath = fullSizsePhotoPath
        thumbPath = SelfieItem.getThumbPath(fullSizsePhotoPath)
        thumbImage = SelfieItem.newThumb(targetH: thumbHeight, targetW: thumbWidth,
                                         imageJPEGPath: fullSizsePhotoPath, thumbPath: thumbPath)
    }
    
    private var label:String {
        get {
            let defaults = NSUserDefaults.standardUserDefaults()
            if let storedLabel = defaults.stringForKey(photoPath.lastPathComponent) {
                return storedLabel
            } else {
                return photoPath.lastPathComponent
            }
        }
        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setValue(newValue, forKey: photoPath.lastPathComponent)
        }
    }
    
    
    private class func getThumbPath(imagePath: String) -> String {
        let fileManager = NSFileManager()
        let cacheUrl = try! fileManager.URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        let cachePath = cacheUrl.path! + "/" + SelfieConstants.CacheSubDir
        
        // if the thumbNail subdirectory doesn't exist, create it
        if !fileManager.fileExistsAtPath(cachePath) {
            try! fileManager.createDirectoryAtPath(cachePath, withIntermediateDirectories: true, attributes: nil)
        }
        // if the thumbNail exists, just read it from the cache
        // otherwise create one
        return cachePath+"/"+imagePath.lastPathComponent
    }
    
    private class func newThumb(targetH targetH:Int, targetW:Int, imageJPEGPath:String, thumbPath:String) -> UIImage? {
        let thumbImage:UIImage?
        let fileManager = NSFileManager()
        if fileManager.fileExistsAtPath(thumbPath) {
            thumbImage = UIImage(contentsOfFile: thumbPath)
        } else {
            if let originalImage = UIImage(contentsOfFile: imageJPEGPath) {
                let scaleFactor = min(originalImage.size.width/CGFloat(targetW), originalImage.size.height/CGFloat(targetH))
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

func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
    image.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
    let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage
}
