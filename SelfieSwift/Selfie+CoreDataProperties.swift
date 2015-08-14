//
//  Selfie+CoreDataProperties.swift
//  SelfieSwift
//
//  Created by jeff greenberg on 8/14/15.
//  Copyright © 2015 Jeff Greenberg. All rights reserved.
//
//  Delete this file and regenerate it using "Create NSManagedObject Subclass…"
//  to keep your implementation up to date with your model.
//

import Foundation
import CoreData

extension Selfie {

    @NSManaged var creationDateTime: NSDate?
    @NSManaged var storedLabel: String?
    @NSManaged var defaultLabel: String?
    @NSManaged var imageData: NSData?

}
