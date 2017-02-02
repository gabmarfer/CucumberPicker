//
//  GridViewCell.swift
//  CucumberPicker
//
//  Created by gabmarfer on 27/01/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import UIKit

class GridViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var checkmark: UIImageView!
    @IBOutlet weak var selectedOverlayView: UIView!
    
    var representedAssetIdentifier: String!
    var thumbnailImage: UIImage! {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    
    override var isSelected: Bool {
        didSet {
            checkmark.isHidden = !isSelected
            selectedOverlayView.isHidden = !isSelected
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        checkmark.isHidden = true
        selectedOverlayView.isHidden = true
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    func commonInit() {
        checkmark.isHidden = true
        selectedOverlayView.isHidden = true
        
    }
    
    
}
