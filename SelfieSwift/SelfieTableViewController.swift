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

class SelfieTableViewController:    UIViewController,
                                    UITableViewDataSource,
                                    UITableViewDelegate,
                                    UIImagePickerControllerDelegate,
                                    UINavigationControllerDelegate,
                                    MFMailComposeViewControllerDelegate,
                                    UITextFieldDelegate {

    var selfies = SelfieList()
    var currentlyEditedSelfie:SelfieItem?
    var nSelected:Int=0 {
        didSet {
            if tableView.editing {
                title = "\(nSelected) Selected"
            }
            if nSelected ==  0 {
                trashButton.enabled = false
                shareButton.enabled = false
            } else {
                trashButton.enabled = true
                shareButton.enabled = true
            }
        }
    }
    
    var keyboardVisible: Bool = false
    var kbdShowObserver: NSObjectProtocol?
    var kbdHideObserver: NSObjectProtocol?
    let notifier = UILocalNotification()
    
    struct Constants {
        static let SelfieResuseID = "Selfie"
        static let ThumbSize = CGSize(width: 48, height: 48)
        static let ShowImageSegue = "show selfie"
        static let DeleteActionLabel = "Delete"
        static let MoreActionLabel = "More"
        static let ActionTitle = "Selfie Actions"
        static let SendActionLabel = "Send"
        static let RenameActionLabel = "Rename"
        static let ResetActionLabel = "Reset Label"
        static let MailSubjectLine = "Selfie Images"
        static let CancelActionLabel = "Cancel"
        static let MarkItemsLabel = "Mark All"
        static let UnMarkItemsLabel = "Unmark All"
        static let DeleteAlertLabel = "Delete"
        static let OKLabel = "Ok"
        static let DeleteAlertMessage = "%d items will be deleted. This action cannot be undone."
        static let NotificationAlertTitle = "Time for a Selfie!"
        static let NotificationAlertBody = "Take a Selfie"
        static let NotificationInterval = NSCalendarUnit.Hour
        static let NotificationFirstInstance = 60.0*60.0        // 1 hour
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var toolBar: UIToolbar! {
        didSet {
            toolBar.hidden = true
        }
    }
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var markButton: UIBarButtonItem! {
        didSet {
            markButton.title=Constants.MarkItemsLabel
        }
    }
    @IBOutlet weak var shareButton: UIBarButtonItem! {
        didSet {
            shareButton.enabled=false
        }
    }
    @IBOutlet weak var trashButton: UIBarButtonItem! {
        didSet {
            trashButton.enabled=false
        }
    }
    
    @IBAction func markOrUnmarkItems(sender: UIBarButtonItem) {
        if sender.title == Constants.MarkItemsLabel {
            sender.title = Constants.UnMarkItemsLabel
            selfies.checkAll()
            nSelected = selfies.count
            if let visiblePaths = tableView.indexPathsForVisibleRows {
                for index in visiblePaths {
                    tableView.selectRowAtIndexPath(index, animated: true, scrollPosition: UITableViewScrollPosition.None)
                }
            }
        } else {
            selfies.unCheckAll()
            nSelected = 0
            if let visiblePaths = tableView.indexPathsForVisibleRows {
                for index in visiblePaths {
                    tableView.deselectRowAtIndexPath(index, animated: true)                }
            }
            sender.title = Constants.MarkItemsLabel
        }
    }

    @IBAction func trashItems(sender: AnyObject) {

        let message = String.localizedStringWithFormat(Constants.DeleteAlertMessage, nSelected)
        let alert = UIAlertController(title: Constants.DeleteAlertLabel, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: Constants.DeleteActionLabel, style: .Destructive) {(action) -> Void in
            self.selfies.removeCheckedItems()
            self.setEditing(false, animated: true)
            self.tableView.reloadData()
            })
        alert.addAction(UIAlertAction(title: Constants.CancelActionLabel, style: .Cancel) { (action) -> Void in
            return
            })
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func shareItems(sender: UIBarButtonItem) {
        emailSelfies(selfies)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // get any stored selfies
        selfies.loadExistingSelfies(thumbSize: Constants.ThumbSize)

        // ensure the rows are auto-sized
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: footerView.frame.height, right: 0)
        // display the table
        tableView.reloadData()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItems?.insert(self.editButtonItem(), atIndex: 0)
        
        // draw a border around the footerView
        footerView.layer.borderWidth=0.5
        footerView.layer.borderColor = UIColor.grayColor().CGColor
        
    }
    
    // MARK: - Selfie Creation
    @IBAction func takeNewSelfie(sender: UIBarButtonItem) {
        // acquire a new image
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            UIApplication.sharedApplication().applicationIconBadgeNumber=0
            let picker = UIImagePickerController()
            picker.sourceType = .Camera
            picker.mediaTypes = [(kUTTypeImage as String)]
            picker.delegate = self
            picker.allowsEditing=true
            presentViewController(picker, animated: true, completion: nil)
        }
    }

    @IBOutlet weak var notificationSwitch: UISwitch! {
        didSet {
            if notificationSwitch.on {
                startNotifications()
            }
        }
    }
    @IBAction func manageNotificationState(sender: UISwitch) {
        if sender.on {
            // configure notifications
            startNotifications()
        } else {
            // disable notifications
            stopNotifications()
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
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return selfies.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.SelfieResuseID, forIndexPath: indexPath) as! SelfieTableViewCell
        cell.selfie = selfies[indexPath.row]

        if tableView.editing {
            if selfies[indexPath.row].isChecked {
                tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.None)
            } else {
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
        return cell
    }

    // MARK: -- Table Editing
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            selfies.removeAtIndex(indexPath.row)
            tableView.reloadData()
        }
    }
    
    func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        cameraButton.enabled=true
        selfies.unCheckAll()
    }
    
    func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        cameraButton.enabled=false
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .Destructive, title: Constants.DeleteActionLabel) { (action, indexPath) -> Void in
            self.selfies.removeAtIndex(indexPath.row)
            tableView.reloadData()
        }
        
        let moreAction = UITableViewRowAction(style: .Normal, title: Constants.MoreActionLabel) {
            (action, indexPath) -> Void in
            self.createActionSheet(self.selfies,indexPath: indexPath)
        }
        
        return [deleteAction, moreAction]
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selfies[indexPath.row].isChecked = true
        if markButton.title == Constants.MarkItemsLabel {
            markButton.title = Constants.UnMarkItemsLabel
        }
        nSelected++
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        selfies[indexPath.row].isChecked = false
        nSelected--
        if selfies.numOfCheckedItems() == 0 {
            markButton.title = Constants.MarkItemsLabel
        }
    }
    
    func createActionSheet(selfie: SelfieList, indexPath: NSIndexPath) {
        let alert = UIAlertController(title: Constants.ActionTitle, message: nil, preferredStyle: .ActionSheet)
        // send
        alert.addAction(UIAlertAction(
            title: Constants.SendActionLabel,
            style: UIAlertActionStyle.Default) { (action) -> Void in
                self.tableView.setEditing(false, animated: true)
                selfie[indexPath.row].isChecked = true
                self.emailSelfies(self.selfies)
            }
        )
        // rename
        alert.addAction(UIAlertAction(
            title: Constants.RenameActionLabel,
            style: UIAlertActionStyle.Default) { (action) -> Void in
                self.tableView.setEditing(false, animated: true)
                self.renameSelfie(selfie, indexPath: indexPath)
            }
        )
        // reset the label to defaul
        alert.addAction(UIAlertAction(
            title: Constants.ResetActionLabel,
            style: UIAlertActionStyle.Default) { (action) -> Void in
                self.tableView.setEditing(false, animated: true)
                selfie[indexPath.row].resetLabel()
                self.tableView.reloadData()
            }
        )
        // cancel
        alert.addAction(UIAlertAction(
            title: Constants.CancelActionLabel,
            style: UIAlertActionStyle.Cancel) { (action) -> Void in
                self.tableView.setEditing(false, animated: true)
            }
        )
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // Override to support rearranging the table view.
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        selfies.swapElements(from: fromIndexPath.row, to: toIndexPath.row)
        tableView.reloadData()
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            tableView.allowsMultipleSelectionDuringEditing=true
            markButton.title=Constants.MarkItemsLabel
            tableView.editing = true
            footerView.hidden=true
            toolBar.hidden = false
            title="0 Selected"
            cameraButton.enabled=false
        } else {
            selfies.unCheckAll()
            tableView.allowsMultipleSelectionDuringEditing=false
            tableView.editing = false
            footerView.hidden = false
            toolBar.hidden = true
            title=""
            cameraButton.enabled=true
        }
    }
    
    // MARK: -- Email
    private func emailSelfies(selfies: SelfieList) {
        let mailController = MFMailComposeViewController()
        mailController.mailComposeDelegate = self
        mailController.setSubject(Constants.MailSubjectLine)
        for selfie in selfies {
            if selfie.isChecked {
                mailController.addAttachmentData(NSData(contentsOfFile: selfie.photoPath)!, mimeType: "image/jpeg", fileName: selfie.label+".jpg")
            }
        }
        presentViewController(mailController, animated: true, completion: nil)
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        dismissViewControllerAnimated(true, completion: nil)
        if tableView.editing {
            if result != MFMailComposeResultCancelled {
                setEditing(false, animated: true)
            }
        }
    }
    
    // MARK: -- Rename
    private func renameSelfie(selfies: SelfieList, indexPath: NSIndexPath) {
        currentlyEditedSelfie = selfies[indexPath.row]
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SelfieTableViewCell
        // enable cell editing
        cell.selfieEditView.enabled=true
        // set delegate
        cell.selfieEditView.delegate = self
        // register for notification when the keyboard displays
        var previousInset: UIEdgeInsets?
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        
        // when the keyboard displays inset it by the height of the keyboard
        kbdShowObserver = notificationCenter.addObserverForName(UIKeyboardWillShowNotification, object: nil, queue: queue) { notification in
            // inset the tableView by the height of the keyboard
            previousInset = self.tableView.contentInset
            if let info = notification.userInfo {
                let kbdFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
                self.tableView.contentInset = UIEdgeInsetsMake(0, 0, kbdFrame.height, 0)
                self.keyboardVisible = true
                self.tableView.allowsSelection = false
            }
        }
        
        // when the keyboard hides return the inset to its previous value
        kbdHideObserver = notificationCenter.addObserverForName(UIKeyboardWillHideNotification, object: nil, queue: queue) { notification in
            // inset the tableView by the height of the keyboard
            self.tableView.contentInset = previousInset!
            self.keyboardVisible=false
            self.tableView.allowsSelection = true
        }
        
        cell.selfieEditView.becomeFirstResponder()
    }
        
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.text?.characters.count > 0 {
            textField.resignFirstResponder()
            textField.enabled = false
            if let selfie=currentlyEditedSelfie {
                selfie.label = textField.text!
                currentlyEditedSelfie=nil
            }
            // remove the keyboard observers now that we don't need them
            if let observer = kbdShowObserver {
                NSNotificationCenter.defaultCenter().removeObserver(observer)
            }
            if let observer = kbdHideObserver {
                NSNotificationCenter.defaultCenter().removeObserver(observer)
            }
            return true
        } else {
            return false
        }
    }
    
    
    // MARK: - Navigation
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if (identifier == Constants.ShowImageSegue && tableView.editing) || keyboardVisible {
            return false
        } else {
            return true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.ShowImageSegue {
            if let sivc = segue.destinationViewController.contentViewController as? ScrollableImageViewController {
                if let cell = sender as? SelfieTableViewCell {
                    sivc.selfieImage = cell.selfie?.photoImage
                    sivc.title = cell.selfie?.label
                }
            }
        }
    }
    
    // MARK: -- Notifications
    private func startNotifications() {
        // assume notifications have been registered in AppDelegate

        notifier.fireDate = NSDate(timeIntervalSinceNow: Constants.NotificationFirstInstance)
        notifier.soundName = UILocalNotificationDefaultSoundName
        notifier.alertTitle = Constants.NotificationAlertTitle
        notifier.alertBody = Constants.NotificationAlertBody
        notifier.applicationIconBadgeNumber = 1
        notifier.repeatInterval = Constants.NotificationInterval

        UIApplication.sharedApplication().scheduleLocalNotification(notifier)
    }
    
    private func stopNotifications() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
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
