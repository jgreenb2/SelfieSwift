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
    let photoPath:String
    private let thumbPath:String
    private let defaultLabel:String
    let thumbImage:UIImage?

    var photoImage:UIImage? {
        if let photo = UIImage(contentsOfFile: self.photoPath) {
            return photo
        } else {
            return nil
        }
    }
    
    var isChecked = false
    var fileName:String
    
    struct Constants {
        static let CacheSubDir = "selfieThumb"
        static let PhotoQuality:CGFloat = 0.9
        static let ThumbNailQuality:CGFloat = 0.75
        static let DateToFileNameFormatString = "EEE_MMM_dd_yyyy_HH:mm:ss"
    }
    
    // create selfie from an existing image
    init(fileName:String, photo:UIImage, thumbSize:CGSize) {
        // store the photo as JPEG in the user documents folder
        (photoPath, thumbPath) = SelfieItem.createPaths(fileName)
        // save the photo
        if let jpegData = UIImageJPEGRepresentation(photo, Constants.PhotoQuality) {
            jpegData.writeToFile(photoPath, atomically: true)
        }
        thumbImage = SelfieItem.newThumb(targetSize: thumbSize, imageJPEGPath: photoPath, thumbPath: thumbPath)
        
        defaultLabel = SelfieItem.createDefaultLabel(fileName)
        
        // save the filename as a property
        self.fileName = fileName
    }
    
    // create selfie from an existing jpg file
    init(fileName:String, thumbSize:CGSize) {
        // store the photo as JPEG in the user documents folder
        (photoPath, thumbPath) = SelfieItem.createPaths(fileName)
        thumbImage = SelfieItem.newThumb(targetSize: thumbSize, imageJPEGPath: photoPath, thumbPath: thumbPath)
        defaultLabel = SelfieItem.createDefaultLabel(fileName)
        
        // save the filename as a property
        self.fileName = fileName        
    }
    
    private class func createPaths(fileName: String) -> (photo: String, thumb: String) {
        let fileManager = NSFileManager()
        let documentsUrl = try! fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask,appropriateForURL: nil, create: true)
        let photo = documentsUrl.path! + "/" + fileName + ".jpg"
        let thumb = SelfieItem.getThumbPath(fileName)
        return (photo, thumb)
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
    
    func resetLabel() {
        label = defaultLabel
    }
    
    private var photoFileName:String {
        return photoPath.lastPathComponent.stringByDeletingPathExtension
    }
    
    func delete() {
        // remove the image file
        let fileManager = NSFileManager()
        do {
            try fileManager.removeItemAtPath(photoPath)
        } catch {
            print("error deleting jpeg: \(error)")
        }
        // remove the cached thumbNail
        do {
            try fileManager.removeItemAtPath(thumbPath)
        } catch {
            print("error deleting thumbnail: \(error)")
        }
        
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
        dateFormatter.dateFormat = Constants.DateToFileNameFormatString
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
        let cachePath = cacheUrl.path! + "/" + Constants.CacheSubDir
        
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
                thumbImage = imageWithImage(originalImage, scaledToSize: targetSize)
                if let jpegData = UIImageJPEGRepresentation(thumbImage!, Constants.ThumbNailQuality) {
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
            if fileManager.fileExistsAtPath(docPath!+"/"+path) {
                let fileName = path.lastPathComponent.stringByDeletingPathExtension
                let newSelfie = SelfieItem(fileName: fileName, thumbSize: SelfieTableViewController.Constants.ThumbSize)
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
