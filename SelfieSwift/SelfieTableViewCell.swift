//
//  SelfieTableViewCell.swift
//  SelfieSwift
//
//  Created by Jeff Greenberg on 7/25/15.
//  Copyright © 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

final class SelfieTableViewCell: UITableViewCell {

    @IBOutlet weak var selfieThumbNailView: UIImageView!
    @IBOutlet weak var selfieEditView: UITextField!
    
    var selfie:SelfieItem? {
        didSet {
            updateUI()
        }
    }

    fileprivate func updateUI() {
        selfieThumbNailView.image = selfie?.thumbImage
        selfieEditView.text = selfie?.label
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
