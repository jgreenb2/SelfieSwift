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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


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
    
    // Internal constants
    struct Constants {
        static let SelfieResuseID = "Selfie"
        static let ThumbSize = CGSize(width: 48, height: 48)
        static let ShowImageSegue = "show selfie"
        static let NotificationInterval = NSCalendar.Unit.hour
        static let NotificationFirstInstance = 60.0*60.0        // 1 hour
        static let NotificationEnabledKey = "NotificationState"
    }
    
    // model data
    fileprivate var selfies = SelfieList()
    // the SelfieImageDelegate allows this VC to
    // request services from the ScrollableImageViewController
    fileprivate var imageDelegate: SelfieImageDelegate?
    
    var defaults = UserDefaults.standard
    
    // MARK: - View Setup
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var toolBar: UIToolbar! {
        didSet {
            toolBar.isHidden = true
        }
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // get any stored selfies
        // do it async since we have no idea how many of them there are
        // or how long it will take
        spinner.hidesWhenStopped = true
        spinner.startAnimating()
        //let qos = Int(DispatchQoS.QoSClass.userInitiated.rawValue) // legacy qos variable stuff
        DispatchQueue.global(qos: .userInitiated).async { () -> Void in
            self.selfies.loadExistingSelfies(thumbSize: Constants.ThumbSize)
            // display the table
            DispatchQueue.main.async { () -> Void in
                self.spinner.stopAnimating()
                self.tableView.reloadData()
            }
        }
        
        // ensure the rows are auto-sized
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: footerView.frame.height, right: 0)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItems?.insert(self.editButtonItem, at: 0)
        
        // draw a border around the footerView
        footerView.layer.borderWidth=0.5
        footerView.layer.borderColor = UIColor.gray.cgColor
        
        // set the nav delegate so we can be notified of controller state changes
        navigationController?.delegate = self
    }
    
    // MARK: - Creating New Items
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBAction func takeNewSelfie(_ sender: UIBarButtonItem) {
        // acquire a new image
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            setBadge(0)
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = [(kUTTypeImage as String)]
            picker.delegate = self
            picker.allowsEditing=true
            present(picker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var image = info[UIImagePickerControllerEditedImage] as? UIImage
        if image == nil {
            image = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
        selfies.appendSelfie(withImage: image)
        tableView.reloadData()
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selfies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.SelfieResuseID, for: indexPath) as! SelfieTableViewCell
        if selfies.count > indexPath.row {
            cell.selfie = selfies[indexPath.row]
            
            if tableView.isEditing {
                if selfies[indexPath.row].isChecked {
                    tableView.selectRow(at: indexPath, animated: true, scrollPosition: UITableViewScrollPosition.none)
                } else {
                    tableView.deselectRow(at: indexPath, animated: true)
                }
            }
        }
        return cell
    }
    
    // MARK: - Multi-Row Editing
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        nSelected=selfies.unCheckAll()      // start with a clean slate
        if editing {
            tableView.allowsMultipleSelectionDuringEditing=true
            markButton.title=UserText.MarkItemsLabel
            tableView.isEditing = true
            footerView.isHidden=true
            toolBar.isHidden = false
            title=String.localizedStringWithFormat(UserText.SelectionHeader, 0)
            cameraButton.isEnabled=false
        } else {
            tableView.allowsMultipleSelectionDuringEditing=false
            tableView.isEditing = false
            footerView.isHidden = false
            toolBar.isHidden = true
            title=""
            cameraButton.isEnabled=true
        }
    }
    
    // Override to support rearranging the table view.
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        selfies.moveElement(from: fromIndexPath.row, to: toIndexPath.row)
        tableView.reloadData()
    }
    
    // MARK: -- Selecting/Deselecting Rows
    
    // nSelected tracks the number of items selected
    // in Edit Mode
    var nSelected:Int=0 {
        didSet {
            if tableView.isEditing {
                title = String.localizedStringWithFormat(UserText.SelectionHeader, nSelected)
            }
            if nSelected ==  0 {
                trashButton.isEnabled = false
                shareButton.isEnabled = false
            } else {
                trashButton.isEnabled = true
                shareButton.isEnabled = true
            }
        }
    }
    
    @IBOutlet weak var markButton: UIBarButtonItem! {
        didSet {
            markButton.title=UserText.MarkItemsLabel
        }
    }
    
    @IBAction func markOrUnmarkItems(_ sender: UIBarButtonItem) {
        if sender.title == UserText.MarkItemsLabel {
            sender.title = UserText.UnMarkItemsLabel
            nSelected=selfies.checkAll()
            if let visiblePaths = tableView.indexPathsForVisibleRows {
                for index in visiblePaths {
                    tableView.selectRow(at: index, animated: true, scrollPosition: UITableViewScrollPosition.none)
                }
            }
        } else {
            nSelected = selfies.unCheckAll()
            if let visiblePaths = tableView.indexPathsForVisibleRows {
                for index in visiblePaths {
                    tableView.deselectRow(at: index, animated: true)                }
            }
            sender.title = UserText.MarkItemsLabel
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        nSelected = selfies.checkItem(atIndex: indexPath.row)
        
        if markButton.title == UserText.MarkItemsLabel {
            markButton.title = UserText.UnMarkItemsLabel
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        nSelected = selfies.unCheckItem(atIndex: indexPath.row)
        if selfies.numOfCheckedItems() == 0 {
            markButton.title = UserText.MarkItemsLabel
        }
    }
    
    // MARK: -- Share Selected Items
    @IBOutlet weak var shareButton: UIBarButtonItem! {
        didSet {
            shareButton.isEnabled=false
        }
    }
    
    @IBAction func shareItems(_ sender: UIBarButtonItem) {
        emailSelfies(selfies)
    }
    
    fileprivate func emailSelfies(_ selfies: SelfieList) {
        let mailController = MFMailComposeViewController()
        mailController.mailComposeDelegate = self
        mailController.setSubject(UserText.MailSubjectLine)
        for selfie in selfies where selfie.isChecked {
            mailController.addAttachmentData(try! Data(contentsOf: URL(fileURLWithPath: selfie.photoPath)),
                mimeType: "image/jpeg",
                fileName: selfie.label+".jpg")
        }
        present(mailController, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
        if tableView.isEditing {
            if result != MFMailComposeResult.cancelled {
                setEditing(false, animated: true)
            }
        }
    }
    
    // MARK: -- Deleting Items
    @IBOutlet weak var trashButton: UIBarButtonItem! {
        didSet {
            trashButton.isEnabled=false
        }
    }
    
    @IBAction func trashItems(_ sender: AnyObject) {
        let message = String.localizedStringWithFormat(UserText.DeleteAlertMessage, nSelected)
        let alert = UIAlertController(title: UserText.DeleteLabel, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: UserText.DeleteLabel, style: .destructive) {(action) -> Void in
            self.selfies.removeCheckedItems()
            self.setEditing(false, animated: true)
            self.imageDelegate?.clearSelfieImage()
            self.tableView.reloadData()
            })
        alert.addAction(UIAlertAction(title: UserText.CancelActionLabel, style: .cancel) { (action) -> Void in
            return
            })
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Single Row Editing
    
    fileprivate var currentlyEditedSelfie:SelfieItem?       // tracks the row being modified during single row editing
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.delete
    }
    
    // not sure this actually gets called but it has to be overriden for row editing to work
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            selfies.removeAtIndex(indexPath.row)
            self.imageDelegate?.clearSelfieImage()
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        cameraButton.isEnabled=true
        nSelected=selfies.unCheckAll()
        if let editButton = navigationItem.rightBarButtonItems?[0] {
            editButton.isEnabled = true
        }
        
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        cameraButton.isEnabled=false
        if let editButton = navigationItem.rightBarButtonItems?[0] {
            editButton.isEnabled = false
        }
        // if row editing starts in splitview make sure the user is looking at the
        // correct image!
        if let svc = splitViewController {
            if !svc.isCollapsed {
                let cell = tableView.cellForRow(at: indexPath)
                performSegue(withIdentifier: Constants.ShowImageSegue, sender: cell)
            }
        }
    }
    // MARK: -- Single Row Actions
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: UserText.DeleteLabel) { (action, indexPath) -> Void in
//        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle(rawValue: <#Int#>)!, title: UserText.DeleteLabel) { (action, indexPath) -> Void in
            self.selfies.removeAtIndex(indexPath.row)
            self.imageDelegate?.clearSelfieImage()
            tableView.reloadData()
        }
        
        let moreAction = UITableViewRowAction(style: .normal, title: UserText.MoreActionLabel) {
            (action, indexPath) -> Void in
            self.createActionSheet(self.selfies,indexPath: indexPath)
        }
        
        return [deleteAction, moreAction]
    }
    
    func createActionSheet(_ selfie: SelfieList, indexPath: IndexPath) {
        let alert = UIAlertController(title: UserText.ActionTitle, message: nil, preferredStyle: .actionSheet)
        // setup popover parameters for adaptive UI on the iPad
        alert.modalPresentationStyle = UIModalPresentationStyle.popover
        let ppc = alert.popoverPresentationController
        let cell = tableView.cellForRow(at: indexPath)
        ppc?.sourceView = cell?.superview
        ppc?.sourceRect = (cell?.frame)!
        // send
        alert.addAction(UIAlertAction(
            title: UserText.SendActionLabel,
            style: UIAlertActionStyle.default)
            { (action) -> Void in
                self.tableView.setEditing(false, animated: true)
                selfie[indexPath.row].isChecked = true
                self.emailSelfies(self.selfies)
            }
        )
        // rename
        alert.addAction(UIAlertAction(
            title: UserText.RenameActionLabel,
            style: UIAlertActionStyle.default)
            { (action) -> Void in
                self.tableView.setEditing(false, animated: true)
                self.renameSelfie(selfie, indexPath: indexPath)
            }
        )
        // reset the label to defaul
        alert.addAction(UIAlertAction(
            title: UserText.ResetActionLabel,
            style: UIAlertActionStyle.default)
            { (action) -> Void in
                self.tableView.setEditing(false, animated: true)
                selfie[indexPath.row].resetLabel()
                self.tableView.reloadData()
            }
        )
        // cancel
        alert.addAction(UIAlertAction(
            title: UserText.CancelActionLabel,
            style: UIAlertActionStyle.cancel)
            { (action) -> Void in
                self.tableView.setEditing(false, animated: true)
            }
        )
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: -- Rename
    
    var keyboardVisible: Bool = false
    var kbdShowObserver: NSObjectProtocol?
    var kbdHideObserver: NSObjectProtocol?
    
    
    fileprivate func renameSelfie(_ selfies: SelfieList, indexPath: IndexPath) {
        currentlyEditedSelfie = selfies[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) as! SelfieTableViewCell
        // enable cell editing
        cell.selfieEditView.isEnabled=true
        // set delegate
        cell.selfieEditView.delegate = self
        // register for notification when the keyboard displays
        var previousInset: UIEdgeInsets!
        let notificationCenter = NotificationCenter.default
        let queue = OperationQueue.main

        // when the keyboard displays inset the tableView by the height of the keyboard so the cell we're trying to edit
        // is always visible. NOTE: suppress this in PrimaryOverlay displaymode since iOS seems to
        // automatically adjust the primary overlay for the keyboard
        kbdShowObserver = notificationCenter.addObserver(forName: NSNotification.Name.UIKeyboardWillShow, object: nil, queue: queue) { notification in
            previousInset = self.tableView.contentInset
            if let info = notification.userInfo {
                let kbdFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
                if self.splitViewController?.displayMode != UISplitViewControllerDisplayMode.primaryOverlay {
                    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, kbdFrame.height, 0)
                }
                self.footerView.isHidden = true
                self.keyboardVisible = true
                self.tableView.allowsSelection = false
            }
        }
        
        // when the keyboard hides return the inset to its previous value
        kbdHideObserver = notificationCenter.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: queue) { notification in
            self.tableView.contentInset = previousInset
            self.keyboardVisible=false
            self.tableView.allowsSelection = true
            self.footerView.isHidden = false
        }
        
        cell.selfieEditView.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text?.characters.count > 0 {
            textField.resignFirstResponder()
            textField.isEnabled = false
            if let selfie=currentlyEditedSelfie {
                selfie.label = textField.text!
                currentlyEditedSelfie=nil
            }
            // remove the keyboard observers now that we don't need them
            if let observer = kbdShowObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            if let observer = kbdHideObserver {
                NotificationCenter.default.removeObserver(observer)
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
            if let notificationDefault = defaults.object(forKey: Constants.NotificationEnabledKey) {
                let storedNotificationState = notificationDefault as! Bool
                notificationSwitch.isOn = storedNotificationState
            } else {
                defaults.set(notificationSwitch.isOn, forKey: Constants.NotificationEnabledKey)
            }
            if notificationSwitch.isOn {
                startNotifications()
            }
        }
    }
    
    @IBAction func manageNotificationState(_ sender: UISwitch) {
        if sender.isOn {
            startNotifications()
        } else {
            stopNotifications()
        }
        defaults.set(sender.isOn, forKey: Constants.NotificationEnabledKey)
    }
    
    fileprivate func startNotifications() {
        // assume notifications have been registered in AppDelegate
        setBadge(1)
        setNotificationSound(UILocalNotificationDefaultSoundName)
        if let types = currentNotificationTypes(), types.contains(.alert)  {
            notifier.fireDate = Date(timeIntervalSinceNow: Constants.NotificationFirstInstance)
            notifier.alertTitle = UserText.NotificationAlertTitle
            notifier.alertBody = UserText.NotificationAlertBody
            notifier.repeatInterval = Constants.NotificationInterval
            
            UIApplication.shared.scheduleLocalNotification(notifier)
        }
    }
    
    fileprivate func stopNotifications() {
        UIApplication.shared.cancelAllLocalNotifications()
    }
    
    fileprivate func setBadge(_ badge: Int) {
        if let types = currentNotificationTypes(), types.contains(.badge)  {
            notifier.applicationIconBadgeNumber = badge
        }
    }
    
    fileprivate func setNotificationSound(_ soundName: String?) {
        if let types = currentNotificationTypes(), types.contains(.sound)  {
            notifier.soundName = soundName
        }
    }
    
    fileprivate func currentNotificationTypes() -> UIUserNotificationType? {
        return UIApplication.shared.currentUserNotificationSettings?.types
    }
    
    // MARK: - Navigation
    
    // surpress segues to the image view when in edit mode
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if (identifier == Constants.ShowImageSegue && tableView.isEditing) || keyboardVisible {
            return false
        } else {
            return true
        }
    }
    
    // segue to the image view when the user taps on the cell
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.ShowImageSegue {
            if let sivc = segue.destination.contentViewController as? ScrollableImageViewController {
                if let cell = sender as? SelfieTableViewCell {
                    sivc.selfieImage = cell.selfie?.photoImage
                    sivc.title = cell.selfie?.label
                    imageDelegate = sivc
                }
            }
        }
    }
    
    // per Apple interface guidelines the previously selected row should be de-selected when
    // the image is popped off the stack. imageDelegate is only non-nil after a segue
    // to the ScrollableImageController so if it's non-nil when we're popped we must be returning
    // from an sivc. If so, deselect and reset the imageDelegate.
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController == self {
            if imageDelegate is UIViewController {
                if let indexPath = tableView.indexPathForSelectedRow {
                    tableView.deselectRow(at: indexPath, animated: true)
                }
                imageDelegate = nil
            }
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
