//
//  SelfieTableViewController.swift
//  SelfieSwift
//
//  Created by Jeff Greenberg on 7/25/15.
//  Copyright © 2015 Jeff Greenberg. All rights reserved.
//

import UIKit
import MobileCoreServices
import MessageUI

class SelfieTableViewController:    UITableViewController,
                                    UIImagePickerControllerDelegate,
                                    UINavigationControllerDelegate,
                                    MFMailComposeViewControllerDelegate,
                                    UITextFieldDelegate {

    var selfies = SelfieList()
    var currentlyEditedSelfie:SelfieItem?
    
    struct Constants {
        static let SelfieResuseID = "Selfie"
        static let ThumbSize = CGSize(width: 48, height: 48)
        static let ShowImageSegue = "show selfie"
        static let DeleteActionLabel = "Delete"
        static let MoreActionLabel = "More"
        static let ActionTitle = "Selfie Actions"
        static let SendActionLabel = "Send Selfie"
        static let RenameActionLabel = "Rename Selfie"
        static let ResetActionLabel = "Reset Label"
        static let MailSubjectLine = "Selfie Images"
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
        }
        
        let moreAction = UITableViewRowAction(style: .Normal, title: Constants.MoreActionLabel) {
            (action, indexPath) -> Void in
            self.createActionSheet(self.selfies,indexPath: indexPath)
        }
        
//        let sendAction = UITableViewRowAction(style: .Normal, title: Constants.SendActionLabel) { (action, indexPath) -> Void in
//            self.emailSelfie(self.selfies[indexPath.row])
//            tableView.setEditing(false, animated: true)
//        }
//        
//        let renameAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: Constants.RenameActionLabel) { (action, indexPath) -> Void in
//            self.renameSelfie(self.selfies, indexPath: indexPath)
//        }
//        renameAction.backgroundColor = UIColor.blueColor()

        return [deleteAction, moreAction]
    }
    
    func createActionSheet(selfie: SelfieList, indexPath: NSIndexPath) {
        let alert = UIAlertController(title: Constants.ActionTitle, message: nil, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(
            title: Constants.SendActionLabel,
            style: UIAlertActionStyle.Default) {
            (action) -> Void in
                self.emailSelfie(selfie[indexPath.row])
                self.tableView.setEditing(false, animated: true)
            }
        )
        alert.addAction(UIAlertAction(
            title: Constants.RenameActionLabel,
            style: UIAlertActionStyle.Default){
                (action) -> Void in
                self.renameSelfie(selfie, indexPath: indexPath)
        })
        
        alert.addAction(UIAlertAction(
            title: "Cancel",
            style: UIAlertActionStyle.Cancel) {
                (action) -> Void in
                self.tableView.setEditing(false, animated: true)

        })
        
        presentViewController(alert, animated: true, completion: nil)
    }
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        selfies.swapElements(from: fromIndexPath.row, to: toIndexPath.row)
        tableView.reloadData()
    }
    
    private func emailSelfie(selfie: SelfieItem) {
        let mailController = MFMailComposeViewController()
        mailController.mailComposeDelegate = self
        mailController.setSubject(Constants.MailSubjectLine)
        mailController.addAttachmentData(NSData(contentsOfFile: selfie.photoPath)!, mimeType: "image/jpeg", fileName: selfie.label+".jpg")
        presentViewController(mailController, animated: true, completion: nil)
    }
    
    private func renameSelfie(selfies: SelfieList, indexPath: NSIndexPath) {
        currentlyEditedSelfie = selfies[indexPath.row]
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SelfieTableViewCell
        // remove row editing
        tableView.setEditing(false, animated: true)
        // enable cell editing
        cell.selfieEditView.enabled=true
        // set delegate
        cell.selfieEditView.delegate = self
        // show keyboard
        cell.selfieEditView.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.text?.characters.count > 0 {
            textField.resignFirstResponder()
            if let selfie=currentlyEditedSelfie {
                selfie.label = textField.text!
            }
            return true
        } else {
            return false
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        dismissViewControllerAnimated(true, completion: nil)
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
