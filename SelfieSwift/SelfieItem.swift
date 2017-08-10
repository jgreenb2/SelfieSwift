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

final class SelfieItem {
    let photoPath:String
    fileprivate let thumbPath:String
    fileprivate let defaultLabel:String
    let thumbImage:UIImage?

    var photoImage:UIImage? {
        return UIImage(contentsOfFile: self.photoPath)
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
            try? jpegData.write(to: URL(fileURLWithPath: photoPath), options: [.atomic])
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
    
    var label:String {
        get {
            let defaults = UserDefaults.standard
            if let storedLabel = defaults.string(forKey: photoFileName) {
                return storedLabel
            } else {
                return defaultLabel
            }
        }
        set {
            let defaults = UserDefaults.standard
            defaults.setValue(newValue, forKey: photoFileName)
        }
    }
    
    func resetLabel() {
        label = defaultLabel
    }
    
    fileprivate var photoFileName:String {
        return photoPath.lastPathComponent.stringByDeletingPathExtension
    }
    
    func delete() {
        // remove the image file
        let fileManager = FileManager()
        do {
            try fileManager.removeItem(atPath: photoPath)
        } catch {
            print("error deleting jpeg: \(error)")
        }
        // remove the cached thumbNail
        do {
            try fileManager.removeItem(atPath: thumbPath)
        } catch {
            print("error deleting thumbnail: \(error)")
        }
        
        // remove any stored label
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: photoFileName)
    }
    
    // MARK: - static class functions
    
    fileprivate class func createPaths(_ fileName: String) -> (photo: String, thumb: String) {
        let fileManager = FileManager()
        let documentsUrl = try! fileManager.url(for: .documentDirectory, in: .userDomainMask,appropriateFor: nil, create: true)
        let photo = documentsUrl.path + "/" + fileName + ".jpg"
        let thumb = SelfieItem.getThumbPath(fileName)
        return (photo, thumb)
    }
    
    fileprivate class func createDefaultLabel(_ fileName:String) -> String {
        // create a default label for the selfie
        //
        // first re-constitute the creation date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Constants.DateToFileNameFormatString
        let selfieCreationDate = dateFormatter.date(from: fileName)
        // Now reformat it for display
        //dateFormatter.dateFormat = "EEE MMM dd, yyyy KK:MM:SS a"
        dateFormatter.timeStyle = DateFormatter.Style.medium
        dateFormatter.dateStyle = DateFormatter.Style.medium
        return dateFormatter.string(from: selfieCreationDate!)
    }
    
    fileprivate class func getThumbPath(_ fileName: String) -> String {
        let fileManager = FileManager()
        let cacheUrl = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let cachePath = cacheUrl.path + "/" + Constants.CacheSubDir
        
        // if the thumbNail subdirectory doesn't exist, create it
        if !fileManager.fileExists(atPath: cachePath) {
            try! fileManager.createDirectory(atPath: cachePath, withIntermediateDirectories: true, attributes: nil)
        }
        return cachePath+"/"+fileName+".jpg"
    }
    
    fileprivate class func newThumb(targetSize:CGSize, imageJPEGPath:String, thumbPath:String) -> UIImage? {
        let thumbImage:UIImage?
        let fileManager = FileManager()
        // if the thumbNail exists, just read it from the cache
        // otherwise create one
        if fileManager.fileExists(atPath: thumbPath) {
            thumbImage = UIImage(contentsOfFile: thumbPath)
        } else {
            if let originalImage = UIImage(contentsOfFile: imageJPEGPath) {
                thumbImage = imageWithImage(originalImage, scaledToSize: targetSize)
                if let jpegData = UIImageJPEGRepresentation(thumbImage!, Constants.ThumbNailQuality) {
                    try? jpegData.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                }
            } else {
                thumbImage = nil
            }
        }
        return thumbImage
    }
    
    class func loadExistingSelfies() -> [SelfieItem] {
        let fileManager = FileManager()
        let documentsUrl = try! fileManager.url(for: .documentDirectory, in: .userDomainMask,appropriateFor: nil, create: true)
        let docPath = documentsUrl.path
        let filePaths = try! fileManager.contentsOfDirectory(atPath: docPath)
        var selfies = [SelfieItem]()
        for path in filePaths {
            if fileManager.fileExists(atPath: docPath+"/"+path) {
                let fileName = path.lastPathComponent.stringByDeletingPathExtension
                let newSelfie = SelfieItem(fileName: fileName, thumbSize: SelfieTableViewController.Constants.ThumbSize)
                selfies.append(newSelfie)
            }
        }
        return selfies
    }
}

// MARK: - Non-class helper functions

func imageWithImage(_ image:UIImage, scaledToSize newSize:CGSize) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
    image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
    let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return newImage
}

// MARK: - String Extensions to Compensate for Swift2 changes

extension String {
    var lastPathComponent : String {
        return (self as NSString).lastPathComponent
    }
    
    var stringByDeletingPathExtension : String {
        return (self as NSString).deletingPathExtension
    }
}
