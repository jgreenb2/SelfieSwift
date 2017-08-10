//
//  SelfieList.swift
//  SelfieSwift
//
//  Created by Jeff Greenberg on 7/28/15.
//  Copyright © 2015 Jeff Greenberg. All rights reserved.
//

import Foundation
import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
//fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
//  switch (lhs, rhs) {
//  case let (l?, r?):
//    return l < r
//  case (nil, _?):
//    return true
//  default:
//    return false
//  }
//}



final class SelfieList: Sequence {
    
    fileprivate struct Constants {
        static let OrderDictKey = "orderDict"
        static let OrderKey = "_displayOrder_"
    }
    
    typealias orderDict = [String:Int]
    
    fileprivate let defaults = UserDefaults.standard
    fileprivate var elements = [SelfieItem]()
    fileprivate var displayOrder = orderDict()
    fileprivate var thumbSize:CGSize?
    
    func loadExistingSelfies(thumbSize:CGSize)  {
        self.thumbSize = thumbSize
        let fileManager = FileManager()
        let documentsUrl = try! fileManager.url(for: .documentDirectory, in: .userDomainMask,appropriateFor: nil, create: true)
        let docPath = documentsUrl.path
        let filePaths = try! fileManager.contentsOfDirectory(atPath: docPath)
        for path in filePaths {
            if fileManager.fileExists(atPath: docPath+"/"+path) {
                let fileName = path.lastPathComponent.stringByDeletingPathExtension
                let newSelfie = SelfieItem(fileName: fileName, thumbSize: thumbSize)
                elements.append(newSelfie)
            }
        }
        
        // sort them into the correct order for display
        displayOrder = getDisplayOrder()
        elements.sort {return self.compareSelfies($0, $1)}
    }
    
    fileprivate func compareSelfies(_ a: SelfieItem, _ b: SelfieItem) -> Bool {
        return displayOrder[a.orderKey]! < displayOrder[b.orderKey]!
    }
    
    fileprivate func getDisplayOrder() -> orderDict {
        if let storedOrder = defaults.dictionary(forKey: Constants.OrderDictKey) as? orderDict {
            return storedOrder
        } else {
            return currentElementOrdering()
        }
    }
        
    func appendSelfie(withImage image:UIImage?) {
        // get the time&date at which the image was created
        let currentTime = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = SelfieItem.Constants.DateToFileNameFormatString
        let dateStr = formatter.string(from: currentTime)
        // create a new selfie item and append it to the selfie array
        // using the formatted date as the file name
        if image != nil {
            let newSelfie = SelfieItem(fileName: dateStr, photo: image!, thumbSize: thumbSize!)
            elements.append(newSelfie)
            displayOrder[newSelfie.orderKey] = (displayOrder.values.max() ?? 0) + 1
            defaults.set(displayOrder, forKey: Constants.OrderDictKey)
        }
    }
    
    
    func removeAtIndex(_ index: Int) {
        let s = elements[index]
        removeOrderEntry(s.orderKey)
        elements.remove(at: index)
        s.delete()
    }
    
    func removeCheckedItems() {
        for (i,e) in elements.enumerated().reversed() {
            if e.isChecked {
                removeAtIndex(i)
            }
        }
    }
    
    func checkItem(atIndex: Int) -> Int {
        elements[atIndex].isChecked = true
        return numOfCheckedItems()
    }
    
    func unCheckItem(atIndex: Int) -> Int {
        elements[atIndex].isChecked = false
        return numOfCheckedItems()
    }
    
    fileprivate func removeOrderEntry(_ key: String) {
        displayOrder.removeValue(forKey: key)
        defaults.set(displayOrder, forKey: Constants.OrderDictKey)
    }
    
    func moveElement(from: Int, to: Int) {
        if from != to {
            // move the element to a new position
            elements.insert(elements.remove(at: from), at: to)
            displayOrder = currentElementOrdering()
        }
    }
    
    func currentElementOrdering() -> orderDict {
        var order = orderDict()
        for (i,e) in elements.enumerated() {
            order[e.orderKey] = i
        }
        defaults.set(order, forKey: Constants.OrderDictKey)
        return order
    }
    
    func checkAll() -> Int {
        for selfie in elements {
            selfie.isChecked = true
        }
        return elements.count
    }
    
    func unCheckAll() -> Int {
        for selfie in elements {
            selfie.isChecked = false
        }
        return 0
    }
    
    func numOfCheckedItems() -> Int {
        return elements.reduce(0) { return $0 + ($1.isChecked ? 1 : 0)}
    }
    
    var count: Int {
        return elements.count
    }
    
    subscript(index: Int) -> SelfieItem {
        get {
            return elements[index]
        }
    }
    
    // MARK: -- Sequence Generation
    struct SelfieListGenerator: IteratorProtocol {
        var value: SelfieList
        var index = 0
        
        init(value: SelfieList) {
            self.value = value
        }
        
        mutating func next() -> SelfieItem? {
            if index < value.count {
                let element = value.elements[index]
                index += 1
                return element
            } else {
                return nil
            }
        }
    }
    
    func makeIterator() -> SelfieListGenerator {
        return SelfieListGenerator(value: self)
    }

}

extension SelfieItem {
    var orderKey:String {
        return fileName+SelfieList.Constants.OrderKey
    }
}
