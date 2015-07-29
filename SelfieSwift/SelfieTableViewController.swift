//
//  SelfieTableViewController.swift
//  SelfieSwift
//
//  Created by Jeff Greenberg on 7/25/15.
//  Copyright © 2015 Jeff Greenberg. All rights reserved.
//

import UIKit
import MobileCoreServices

class SelfieTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var selfies = [SelfieItem]()
    typealias orderDict = [String:Int]
    var displayOrder = orderDict()
    
    struct Constants {
        static let SelfieResuseID = "Selfie"
        static let ThumbSize = CGSize(width: 48, height: 48)
        static let DateToFileNameFormatString = "EEE_MMM_dd_yyyy_HH:mm:ss"
        static let ShowImageSegue = "show selfie"
        static let OrderDictKey = "orderDict"
        static let OrderKey = "_displayOrder_"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // get any stored selfies
        selfies = SelfieItem.loadExistingSelfies()
        
        // sort them into the correct order for display
        displayOrder = getDisplayOrder()
        selfies.sortInPlace {return self.compareSelfies($0, $1)}
        
        // ensure the rows are auto-sized
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // display the table
        tableView.reloadData()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItems?.insert(self.editButtonItem(), atIndex: 0)
    }
    
    private func compareSelfies(a: SelfieItem, _ b: SelfieItem) -> Bool {
        let keyA = a.fileName+Constants.OrderKey
        let keyB = b.fileName+Constants.OrderKey
        return displayOrder[keyA] < displayOrder[keyB]
    }

    // MARK: - Selfie Creation
    @IBAction func takeNewSelfie(sender: UIBarButtonItem) {
        // acquire a new image
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            let picker = UIImagePickerController()
            picker.sourceType = .Camera
            picker.mediaTypes = [(kUTTypeImage as String)]
            picker.delegate = self
            picker.allowsEditing=true
            presentViewController(picker, animated: true, completion: nil)
        }
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        var image = info[UIImagePickerControllerEditedImage] as? UIImage
        if image == nil {
            image = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
        appendNewSelfie(image)
        tableView.reloadData()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func appendNewSelfie(image:UIImage?) {
        // get the time&date at which the image was created
        let currentTime = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = Constants.DateToFileNameFormatString
        let dateStr = formatter.stringFromDate(currentTime)
        // create a new selfie item and append it to the selfie array
        // using the formatted date as the file name
        if image != nil {
            let newSelfie = SelfieItem(fileName: dateStr, photo: image!, thumbSize: Constants.ThumbSize)
            selfies.append(newSelfie)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return selfies.count
    }
    

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.SelfieResuseID, forIndexPath: indexPath) as! SelfieTableViewCell

        cell.selfie = selfies[indexPath.row]

        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let defaults = NSUserDefaults.standardUserDefaults()
            let s = selfies[indexPath.row]
            let orderKey = s.fileName+Constants.OrderKey
            defaults.removeObjectForKey(orderKey)
            s.delete()
            selfies.removeAtIndex(indexPath.row)
            tableView.reloadData()
        }
    }

    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        swap(&displayOrder[selfies[toIndexPath.row].fileName+Constants.OrderKey],&displayOrder[selfies[fromIndexPath.row].fileName+Constants.OrderKey])
        swap(&selfies[toIndexPath.row], &selfies[fromIndexPath.row])
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(displayOrder, forKey: Constants.OrderDictKey)
        tableView.reloadData()
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.ShowImageSegue {
            if let sivc = segue.destinationViewController.contentViewController as? ScrollableImageViewController {
                if let cell = sender as? SelfieTableViewCell {
                    sivc.selfieImage = cell.selfie?.photoImage
                }
            }
        }
    }
    
    func getDisplayOrder() -> orderDict {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let storedOrder = defaults.dictionaryForKey(Constants.OrderDictKey) as? orderDict {
            return storedOrder
        } else {
            var defaultOrder=orderDict()
            for (index, selfie) in selfies.enumerate() {
                defaultOrder[selfie.fileName+Constants.OrderKey]=index
            }
            defaults.setObject(defaultOrder, forKey: Constants.OrderDictKey)
            return defaultOrder
        }
    }
}

// MARK: - Extentions
extension UIViewController {
    /**
    If the view controller is embedded in a UINavigationController
    return the visible controller in the Navcon. Otherwise just return
    self
    - Returns: the view controller
    */
    var contentViewController: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController!
        } else {
            return self
        }
    }
}
