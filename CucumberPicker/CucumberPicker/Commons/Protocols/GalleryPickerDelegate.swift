//
//  GalleryPickerDelegate.swift
//  CucumberPicker
//
//  Created by gabmarfer on 21/02/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import Foundation
import UIKit
import Photos

protocol GalleryPickerDelegate: class {
    func galleryPickerController<VC: UIViewController>(_ viewController: VC, didPickAssets assets: [PHAsset]?) where VC: GalleryPickerProtocol
}

protocol GalleryPickerProtocol: class {
    weak var galleryDelegate: GalleryPickerDelegate? { get set }
}
