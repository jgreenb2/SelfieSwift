//
//  SelfieTableViewController.swift
//  SelfieSwift
//
//  Created by Jeff Greenberg on 7/25/15.
//  Copyright © 2015 Jeff Greenberg. All rights reserved.
//
//  This is the main view controller for the app.
//  
//  Manages a UITableView embedded within a UIView.
//  This allows for a static footer/toolbar (not a UITableView footer)
//
//  The UITableView is a single section with a single cell type that
//  holds a preview thumbnail and a label for a stored image
//
//  The entire controller is also embedded in UISplitView controller as
//  well as a UINavigationController. See the Storyboard for the topology.
//
//  Clicking on a table entry segues to another controller (ScrollableImageController)
//  for displaying the fullsize image.
//
//  Clicking the Edit button in the header opens a multi-row edit view. This also
//  hides the footer and displays a UIToolbar in its place. The toolbar supports
//  global operations on the selected cells. Row re-ording is also supported.
//
//  The header also includes a Camera icon for taking a new picture (Called a "Selfie"
//  but it can be any image)
//
//  Each cell may be edited by itself by swiping to the left. This reveals a "Delete"
//  button and a "More" button. "More" provides access to less commonly used functions
//  that logically apply only to a single cell
//
//  The UI adapts to Regular and Compact layouts via the SplitViewController and by
//  supporting popover controllers when requested.
//
//  Notifications that remind the user to take a new picture each hour are enabled/disabled
//  via a switch located on the footer

import UIKit
import MobileCoreServices
import MessageUI

protocol SelfieImageDelegate {
    func clearSelfieImage()
}

final class SelfieTableViewController:    UIViewController,
                                    UITableViewDataSource,
                                    UITableViewDelegate,
                                    UIImagePickerControllerDelegate,
                                    UINavigationControllerDelegate,
                                    MFMailComposeViewControllerDelegate,
                                    UITextFieldDelegate {
    //MARK: - Constants
    // User-visible text that should be localized 
    private struct UserText {
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
    }
    
    // Internal constants
    struct Constants {
        static let SelfieResuseID = "Selfie"
        static let ThumbSize = CGSize(width: 48, height: 48)
        static let ShowImageSegue = "show selfie"
        static let NotificationInterval = NSCalendarUnit.Hour
        static let NotificationFirstInstance = 60.0*60.0        // 1 hour
        static let NotificationEnabledKey = "NotificationState"
    }
 
    // model data
    private var selfies = SelfieList()
    // the SelfieImageDelegate allows this VC to
    // request services from the ScrollableImageViewController
    private var imageDelegate: SelfieImageDelegate?
    
    var defaults = NSUserDefaults.standardUserDefaults()
    
    // MARK: - View Setup
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var toolBar: UIToolbar! {
        didSet {
            toolBar.hidden = true
        }
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
        
        // manage the split view controller
        if let svc = splitViewController {
            svc.preferredDisplayMode = UISplitViewControllerDisplayMode.AllVisible
        }
    }
    
    // MARK: - Creating New Items   
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBAction func takeNewSelfie(sender: UIBarButtonItem) {
        // acquire a new image
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            setBadge(0)
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
    
    // MARK: - Multi-Row Editing
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        nSelected=selfies.unCheckAll()      // start with a clean slate
        if editing {
            tableView.allowsMultipleSelectionDuringEditing=true
            markButton.title=UserText.MarkItemsLabel
            tableView.editing = true
            footerView.hidden=true
            toolBar.hidden = false
            title="0 Selected"
            cameraButton.enabled=false
        } else {
            tableView.allowsMultipleSelectionDuringEditing=false
            tableView.editing = false
            footerView.hidden = false
            toolBar.hidden = true
            title=""
            cameraButton.enabled=true
        }
    }
    
    // Override to support rearranging the table view.
    func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        selfies.swapElements(from: fromIndexPath.row, to: toIndexPath.row)
        tableView.reloadData()
    }
    
    // MARK: -- Selecting/Deselecting Rows
    
    // nSelected tracks the number of items selected
    // in Edit Mode
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
    
    @IBOutlet weak var markButton: UIBarButtonItem! {
        didSet {
            markButton.title=UserText.MarkItemsLabel
        }
    }
    
    @IBAction func markOrUnmarkItems(sender: UIBarButtonItem) {
        if sender.title == UserText.MarkItemsLabel {
            sender.title = UserText.UnMarkItemsLabel
            nSelected=selfies.checkAll()
            if let visiblePaths = tableView.indexPathsForVisibleRows {
                for index in visiblePaths {
                    tableView.selectRowAtIndexPath(index, animated: true, scrollPosition: UITableViewScrollPosition.None)
                }
            }
        } else {
            nSelected = selfies.unCheckAll()
            if let visiblePaths = tableView.indexPathsForVisibleRows {
                for index in visiblePaths {
                    tableView.deselectRowAtIndexPath(index, animated: true)                }
            }
            sender.title = UserText.MarkItemsLabel
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        nSelected = selfies.checkItem(atIndex: indexPath.row)
        
        if markButton.title == UserText.MarkItemsLabel {
            markButton.title = UserText.UnMarkItemsLabel
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        nSelected = selfies.unCheckItem(atIndex: indexPath.row)
        if selfies.numOfCheckedItems() == 0 {
            markButton.title = UserText.MarkItemsLabel
        }
    }
    
    // MARK: -- Share Selected Items
    @IBOutlet weak var shareButton: UIBarButtonItem! {
        didSet {
            shareButton.enabled=false
        }
    }
    
    @IBAction func shareItems(sender: UIBarButtonItem) {
        emailSelfies(selfies)
    }
        
    private func emailSelfies(selfies: SelfieList) {
        let mailController = MFMailComposeViewController()
        mailController.mailComposeDelegate = self
        mailController.setSubject(UserText.MailSubjectLine)
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
    
    // MARK: -- Deleting Items
    @IBOutlet weak var trashButton: UIBarButtonItem! {
        didSet {
            trashButton.enabled=false
        }
    }

    @IBAction func trashItems(sender: AnyObject) {
        
        let message = String.localizedStringWithFormat(UserText.DeleteAlertMessage, nSelected)
        let alert = UIAlertController(title: UserText.DeleteAlertLabel, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: UserText.DeleteActionLabel, style: .Destructive) {(action) -> Void in
            self.selfies.removeCheckedItems()
            self.setEditing(false, animated: true)            
            self.imageDelegate?.clearSelfieImage()
            self.tableView.reloadData()
            })
        alert.addAction(UIAlertAction(title: UserText.CancelActionLabel, style: .Cancel) { (action) -> Void in
            return
            })
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Single Row Editing
    
    private var currentlyEditedSelfie:SelfieItem?       // tracks the row being modified during single row editing
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.Delete
    }
    
    // not sure this actually gets called but it has to be overriden for row editing to work
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            selfies.removeAtIndex(indexPath.row)
            self.imageDelegate?.clearSelfieImage()
            tableView.reloadData()
        }
    }
    
    func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        cameraButton.enabled=true
        nSelected=selfies.unCheckAll()
        if let editButton = navigationItem.rightBarButtonItems?[0] {
            editButton.enabled = true
        }
        
    }
    
    func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        cameraButton.enabled=false
        if let editButton = navigationItem.rightBarButtonItems?[0] {
            editButton.enabled = false
        }
        // if row editing starts in splitview make sure the user is looking at the 
        // correct image!
        if let svc = splitViewController {
            if !svc.collapsed {
                let cell = tableView.cellForRowAtIndexPath(indexPath)
                performSegueWithIdentifier(Constants.ShowImageSegue, sender: cell)
            }
        }
    }
    // MARK: -- Single Row Actions
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .Destructive, title: UserText.DeleteActionLabel) { (action, indexPath) -> Void in
            self.selfies.removeAtIndex(indexPath.row)
            self.imageDelegate?.clearSelfieImage()
            tableView.reloadData()
        }
        
        let moreAction = UITableViewRowAction(style: .Normal, title: UserText.MoreActionLabel) {
            (action, indexPath) -> Void in
            self.createActionSheet(self.selfies,indexPath: indexPath)
        }
        
        return [deleteAction, moreAction]
    }
    
    func createActionSheet(selfie: SelfieList, indexPath: NSIndexPath) {
        let alert = UIAlertController(title: UserText.ActionTitle, message: nil, preferredStyle: .ActionSheet)
        // setup popover parameters for adaptive UI on the iPad
        alert.modalPresentationStyle = UIModalPresentationStyle.Popover
        let ppc = alert.popoverPresentationController
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        ppc?.sourceView = cell?.superview
        ppc?.sourceRect = (cell?.frame)!
        // send
        alert.addAction(UIAlertAction(
            title: UserText.SendActionLabel,
            style: UIAlertActionStyle.Default) { (action) -> Void in
                self.tableView.setEditing(false, animated: true)
                selfie[indexPath.row].isChecked = true
                self.emailSelfies(self.selfies)
            }
        )
        // rename
        alert.addAction(UIAlertAction(
            title: UserText.RenameActionLabel,
            style: UIAlertActionStyle.Default) { (action) -> Void in
                self.tableView.setEditing(false, animated: true)
                self.renameSelfie(selfie, indexPath: indexPath)
            }
        )
        // reset the label to defaul
        alert.addAction(UIAlertAction(
            title: UserText.ResetActionLabel,
            style: UIAlertActionStyle.Default) { (action) -> Void in
                self.tableView.setEditing(false, animated: true)
                selfie[indexPath.row].resetLabel()
                self.tableView.reloadData()
            }
        )
        // cancel
        alert.addAction(UIAlertAction(
            title: UserText.CancelActionLabel,
            style: UIAlertActionStyle.Cancel) { (action) -> Void in
                self.tableView.setEditing(false, animated: true)
            }
        )
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: -- Rename

    var keyboardVisible: Bool = false
    var kbdShowObserver: NSObjectProtocol?
    var kbdHideObserver: NSObjectProtocol?
    

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
        
        // when the keyboard displays inset the tableView by the height of the keyboard so the cell we're trying to edit
        // is always visible
        kbdShowObserver = notificationCenter.addObserverForName(UIKeyboardWillShowNotification, object: nil, queue: queue) { notification in
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
    
    // MARK: - Notifications
    
    let notifier = UILocalNotification()
    
    @IBOutlet weak var notificationSwitch: UISwitch! {
        didSet {
            if let notificationDefault = defaults.objectForKey(Constants.NotificationEnabledKey) {
                let storedNotificationState = notificationDefault as! Bool
                notificationSwitch.on = storedNotificationState
            } else {
                defaults.setBool(notificationSwitch.on, forKey: Constants.NotificationEnabledKey)
            }
            if notificationSwitch.on {
                startNotifications()
            }
        }
    }
    
    @IBAction func manageNotificationState(sender: UISwitch) {
        if sender.on {
            startNotifications()
        } else {
            stopNotifications()
        }
        defaults.setBool(sender.on, forKey: Constants.NotificationEnabledKey)
    }
    
    private func startNotifications() {
        // assume notifications have been registered in AppDelegate
        setBadge(1)
        setNotificationSound(UILocalNotificationDefaultSoundName)
        if let settings = UIApplication.sharedApplication().currentUserNotificationSettings() {
            if settings.types.contains(UIUserNotificationType.Alert) {
                notifier.fireDate = NSDate(timeIntervalSinceNow: Constants.NotificationFirstInstance)
                notifier.alertTitle = UserText.NotificationAlertTitle
                notifier.alertBody = UserText.NotificationAlertBody
                notifier.repeatInterval = Constants.NotificationInterval
                
                UIApplication.sharedApplication().scheduleLocalNotification(notifier)
            }
        }
    }
    
    private func setBadge(badge: Int) {
        if let settings = UIApplication.sharedApplication().currentUserNotificationSettings() {
            if settings.types.contains(UIUserNotificationType.Badge) {
                notifier.applicationIconBadgeNumber = badge
            }
        }
    }
    
    private func setNotificationSound(soundName: String?) {
        if let settings = UIApplication.sharedApplication().currentUserNotificationSettings() {
            if settings.types.contains(UIUserNotificationType.Sound) {
                notifier.soundName = soundName
            }
        }
   }
    
    private func stopNotifications() {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
   
    // MARK: - Navigation
    
    // surpress segues to the image view when in edit mode
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if (identifier == Constants.ShowImageSegue && tableView.editing) || keyboardVisible {
            return false
        } else {
            return true
        }
    }
    
    // segue to the image view when the user taps on the cell
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.ShowImageSegue {
            if let sivc = segue.destinationViewController.contentViewController as? ScrollableImageViewController {
                if let cell = sender as? SelfieTableViewCell {
                    sivc.selfieImage = cell.selfie?.photoImage
                    sivc.title = cell.selfie?.label
                    imageDelegate = sivc
                }
            }
        }
    }
    // per Apple interface guidelines the previously selected row should be de-selected when
    // the image is popped off the stack
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
}

// MARK: - Extensions
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
