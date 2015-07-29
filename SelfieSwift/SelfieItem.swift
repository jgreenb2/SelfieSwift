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
    private let defaultLabel:String
    let thumbImage:UIImage?
    let photoImage:UIImage
    let isChecked = false
    var fileName:String
    
    private struct SelfieConstants {
        static let CacheSubDir = "selfieThumb"
        static let PhotoQuality:CGFloat = 0.9
        static let ThumbNailQuality:CGFloat = 0.75
    }
   
    init(fileName:String, photo:UIImage, thumbSize:CGSize) {
        // store the photo as JPEG in the user documents folder
        let fileManager = NSFileManager()
        let documentsUrl = try! fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask,appropriateForURL: nil, create: true)
        photoPath = documentsUrl.path! + "/" + fileName + ".jpg"
        thumbPath = SelfieItem.getThumbPath(fileName)
        thumbImage = SelfieItem.newThumb(targetSize: thumbSize, imageJPEGPath: photoPath, thumbPath: thumbPath)
        photoImage = photo
        // save the photo
        if let jpegData = UIImageJPEGRepresentation(photoImage, SelfieConstants.PhotoQuality) {
            jpegData.writeToFile(photoPath, atomically: true)
        }
        
        defaultLabel = SelfieItem.createDefaultLabel(fileName)
        
        // save the filename as a property
        self.fileName = fileName
    }
    
    var label:String {
        get {
            let defaults = NSUserDefaults.standardUserDefaults()
            if let storedLabel = defaults.stringForKey(photoFileName) {
                return storedLabel
            } else {
                return defaultLabel
            }
        }
        set {
            let defaults = NSUserDefaults.standardUserDefaults()
            defaults.setValue(newValue, forKey: photoFileName)
        }
    }
    
    private var photoFileName:String {
        return photoPath.lastPathComponent.stringByDeletingPathExtension
    }
    
    func delete() {
        // remove the image file
        let fileManager = NSFileManager()
        try! fileManager.removeItemAtPath(photoPath)
        // remove the cached thumbNail
        try! fileManager.removeItemAtPath(thumbPath)
        // remove any stored label
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey(photoFileName)
    }
    
    // MARK: - static class functions
    
    private class func createDefaultLabel(fileName:String) -> String {
        // create a default label for the selfie
        //
        // first re-constitute the creation date
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = SelfieTableViewController.Constants.DateToFileNameFormatString
        let selfieCreationDate = dateFormatter.dateFromString(fileName)
        // Now reformat it for display
        //dateFormatter.dateFormat = "EEE MMM dd, yyyy KK:MM:SS a"
        dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        return dateFormatter.stringFromDate(selfieCreationDate!)
    }
    
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
                let newSize = CGSize(width: originalImage.size.width/scaleFactor, height: originalImage.size.height/scaleFactor)
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
    
    class func loadExistingSelfies() -> [SelfieItem] {
        let fileManager = NSFileManager()
        let documentsUrl = try! fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask,appropriateForURL: nil, create: true)
        let docPath = documentsUrl.path
        let filePaths = try! fileManager.contentsOfDirectoryAtPath(docPath!)
        var selfies = [SelfieItem]()
        for path in filePaths {
            if let image = UIImage(contentsOfFile: docPath!+"/"+path) {
                let fileName = path.lastPathComponent.stringByDeletingPathExtension
                let newSelfie = SelfieItem(fileName: fileName, photo: image, thumbSize: SelfieTableViewController.Constants.ThumbSize)
                selfies.append(newSelfie)
            }
        }
        return selfies
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
