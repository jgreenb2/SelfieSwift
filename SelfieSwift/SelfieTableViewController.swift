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

    var selfies = SelfieList()
    
    struct Constants {
        static let SelfieResuseID = "Selfie"
        static let ThumbSize = CGSize(width: 48, height: 48)
        static let ShowImageSegue = "show selfie"
        static let DeleteActionLabel = "Delete"
        static let SendActionLabel = "Send"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // get any stored selfies
        selfies.loadExistingSelfies(thumbSize: Constants.ThumbSize)

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
        selfies.appendSelfie(withImage: image)
        tableView.reloadData()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
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
    
//    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
//        return UITableViewCellEditingStyle.Delete
//    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .Destructive, title: Constants.DeleteActionLabel) { (action, indexPath) -> Void in
            self.selfies.removeAtIndex(indexPath.row)
            tableView.reloadData()
            print("custom delete action")
        }
        let sendAction = UITableViewRowAction(style: .Normal, title: Constants.SendActionLabel) { (action, indexPath) -> Void in
            tableView.setEditing(false, animated: true)
            print("send row \(indexPath.row)")
        }
        
        return [deleteAction, sendAction]
    }
    
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        selfies.swapElements(from: fromIndexPath.row, to: toIndexPath.row)
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
