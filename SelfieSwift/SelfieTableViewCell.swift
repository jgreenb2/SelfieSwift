//
//  SelfieTableViewCell.swift
//  SelfieSwift
//
//  Created by Jeff Greenberg on 7/25/15.
//  Copyright © 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

class SelfieTableViewCell: UITableViewCell {

    @IBOutlet weak var selfieThumbNailView: UIImageView!
    @IBOutlet weak var selfieLabelView: UILabel!

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
