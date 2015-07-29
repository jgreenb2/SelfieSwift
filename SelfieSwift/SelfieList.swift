//
//  SelfieList.swift
//  SelfieSwift
//
//  Created by Jeff Greenberg on 7/28/15.
//  Copyright © 2015 Jeff Greenberg. All rights reserved.
//

import Foundation
import UIKit


class SelfieList {
    
    private struct Constants {
        static let OrderDictKey = "orderDict"
        static let OrderKey = "_displayOrder_"
    }
    
    typealias orderDict = [String:Int]

    private let defaults = NSUserDefaults.standardUserDefaults()
    private var elements = [SelfieItem]()
    private var displayOrder = orderDict()
    private var thumbSize:CGSize?
    
    func loadExistingSelfies(thumbSize thumbSize:CGSize)  {
        self.thumbSize = thumbSize
        let fileManager = NSFileManager()
        let documentsUrl = try! fileManager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask,appropriateForURL: nil, create: true)
        let docPath = documentsUrl.path
        let filePaths = try! fileManager.contentsOfDirectoryAtPath(docPath!)
        for path in filePaths {
            if let image = UIImage(contentsOfFile: docPath!+"/"+path) {
                let fileName = path.lastPathComponent.stringByDeletingPathExtension
                let newSelfie = SelfieItem(fileName: fileName, photo: image, thumbSize: thumbSize)
                elements.append(newSelfie)
            }
        }
        
        // sort them into the correct order for display
        displayOrder = getDisplayOrder()
        elements.sortInPlace {return self.compareSelfies($0, $1)}
    }
    
    private func compareSelfies(a: SelfieItem, _ b: SelfieItem) -> Bool {
        return displayOrder[a.orderKey] < displayOrder[b.orderKey]
    }
    
    func getDisplayOrder() -> orderDict {
        if let storedOrder = defaults.dictionaryForKey(Constants.OrderDictKey) as? orderDict {
            return storedOrder
        } else {
            var defaultOrder=orderDict()
            for (index, selfie) in elements.enumerate() {
                defaultOrder[selfie.orderKey]=index
            }
            defaults.setObject(defaultOrder, forKey: Constants.OrderDictKey)
            return defaultOrder
        }
    }
    
    func appendSelfie(withImage image:UIImage?) {
        // get the time&date at which the image was created
        let currentTime = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = SelfieItem.Constants.DateToFileNameFormatString
        let dateStr = formatter.stringFromDate(currentTime)
        // create a new selfie item and append it to the selfie array
        // using the formatted date as the file name
        if image != nil {
            let newSelfie = SelfieItem(fileName: dateStr, photo: image!, thumbSize: thumbSize!)
            elements.append(newSelfie)
        }
    }
    
    func removeAtIndex(index: Int) {
        let s = elements[index]
        defaults.removeObjectForKey(s.orderKey)
        s.delete()
        elements.removeAtIndex(index)
    }
    
    func swapElements(from from: Int, to: Int) {
        swap(&displayOrder[elements[from].orderKey],&displayOrder[elements[to].orderKey])
        swap(&elements[from], &elements[to])
        defaults.setObject(displayOrder, forKey: Constants.OrderDictKey)

    }
    
    var count: Int {
        return elements.count
    }
        
    subscript(index: Int) -> SelfieItem {
        get {
            return elements[index]
        }
    }
}

extension SelfieItem {
    var orderKey:String {
        return fileName+SelfieList.Constants.OrderKey
    }
}
