//
//  UserStrings.swift
//  SelfieSwift
//
//  Created by Jeff Greenberg on 8/28/15.
//  Copyright © 2015 Jeff Greenberg. All rights reserved.
//

import Foundation
// User-visible text that should be localized
struct UserText {
    static let DeleteLabel = NSLocalizedString(
        "Delete",
        comment: "delete a file or entry"
    )
    static let MoreActionLabel = NSLocalizedString(
        "More",
        comment: " more items to select"
    )
    static let ActionTitle = NSLocalizedString(
        "Selfie Actions",
        comment: "actions on this item"
    )
    static let SendActionLabel = NSLocalizedString(
        "Send",
        comment: "send by email"
    )
    static let RenameActionLabel = NSLocalizedString(
        "Rename",
        comment: "change the name"
    )
    static let ResetActionLabel = NSLocalizedString(
        "Reset Label",
        comment: "change label back to default"
    )
    static let MailSubjectLine = NSLocalizedString(
        "Selfie Images",
        comment: "name of the images"
    )
    static let CancelActionLabel = NSLocalizedString(
        "Cancel",
        comment: "don't do it!"
    )
    static let MarkItemsLabel = NSLocalizedString(
        "Mark All",
        comment: "marks all items as selected"
    )
    static let UnMarkItemsLabel = NSLocalizedString(
        "Unmark All",
        comment: "removes selection from all items"
    )
    static let OKLabel = NSLocalizedString(
        "Ok",
        comment: "let's do it!"
    )
    static let DeleteAlertMessage = NSLocalizedString(
        "%d items will be deleted. This action cannot be undone.",
        comment: "deletion warning"
    )
    static let SelectionHeader = NSLocalizedString(
        "%d Selected",
        comment: "number selected items"
    )
    static let NotificationAlertTitle = NSLocalizedString(
        "Time for a Selfie!",
        comment: "notification for new selfie"
    )
    static let NotificationAlertBody = NSLocalizedString(
        "Take a Selfie",
        comment: "notification message"
    )
}
