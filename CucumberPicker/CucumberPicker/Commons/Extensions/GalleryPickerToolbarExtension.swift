//
//  GalleryPickerToolbarExtension.swift
//  CucumberPicker
//
//  Created by gabmarfer on 28/02/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import UIKit

extension UIViewController {
    
    fileprivate var galleryToolbarTitleLabel: UILabel {
        let button = toolbarItems?.first
        return button?.customView as! UILabel
    }
    
    func configureGalleryToolbar() {
        navigationController?.setToolbarHidden(false, animated: false)
        
        let frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 44.0)
        let titleLabel = UILabel(frame: frame)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.black
        
        let toolbarTitle = UIBarButtonItem(customView: titleLabel)
        setToolbarItems([toolbarTitle], animated: true)
    }
    
    func updateGalleryToolbarTitle(selected items: Int, of total: Int) {
        galleryToolbarTitleLabel.text = NSLocalizedString("\(items) of \(total) items selected", comment: "")
    }
}
