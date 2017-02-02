//
//  EditAssetViewCell.swift
//  CucumberPicker
//
//  Created by gabmarfer on 01/02/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import UIKit

class EditAssetViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectedOverlayView: UIView!
    
    override var isSelected: Bool {
        didSet {
            selectedOverlayView.isHidden = !isSelected
        }
    }
    
}
