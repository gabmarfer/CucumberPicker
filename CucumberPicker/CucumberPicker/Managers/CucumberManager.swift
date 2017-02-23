//
//  CucumberManager.swift
//  CucumberPicker
//
//  Created by gabmarfer on 26/01/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import Foundation
import Photos

protocol CucumberDelegate: class {
    func cumberManager(_ manager: CucumberManager, didFinishPickingImagesWithURLs urls: [URL])
}

open class CucumberManager: NSObject {
    
    /// The maximum number of images to pick
    enum Custom {
        static let maxImages = 5
    }
    
    weak var delegate: CucumberDelegate?

    fileprivate var cameraManager: CameraManager!
    fileprivate var imageURLs = Array<URL>()
    fileprivate var selectedAssets = Array<PHAsset>()
    fileprivate var viewController: UIViewController!
    fileprivate var senderButton: UIBarButtonItem!

    public init(_ viewController: UIViewController) {
        self.viewController = viewController
        
        cameraManager = CameraManager(viewController)
    }
    
    // MARK: Public methods
    
    func showImagePicker(fromButton button: UIBarButtonItem) {
        senderButton = button
        
        cameraManager.delegate = self
        cameraManager.showCamera(fromButton: button)
    }
    
    // MARK: Private methods
    
    fileprivate func showCustomGalleryPicker() {
        let storyboard = UIStoryboard.cucumberPickerStoryboard()
        let viewControllerIdentifier = String(describing: AlbumsViewController.self)
        let albumsViewController = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier) as! AlbumsViewController
        
        // Load cached assets
        albumsViewController.galleryDelegate = self
        albumsViewController.selectedAssets = selectedAssets
        albumsViewController.takenPhotos = (imageURLs.count - selectedAssets.count)
        
        let albumsNavigationController = UINavigationController(rootViewController: albumsViewController)
        self.viewController.present(albumsNavigationController, animated: false, completion: nil)
    }
    
    fileprivate func showEditViewController() {
        let storyboard = UIStoryboard.cucumberPickerStoryboard()
        let viewControllerIdentifier = String(describing: EditViewController.self)
        let editViewController = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier) as! EditViewController
        editViewController.imageURLs = imageURLs
        editViewController.delegate = self
        
        self.viewController.present(editViewController, animated: false, completion: nil)
    }
}

// MARK: - CameraManagerDelegate
extension CucumberManager: CameraManagerDelegate {
    func cameraManager(_ manager: CameraManager, didPickImageAtURL url: URL) {
        manager.delegate = nil
        
        imageURLs.append(url)
        
        showEditViewController()
    }
    
    func cameraManagerDidSelectOpenGallery(_ manager: CameraManager) {
        manager.delegate = nil
        showCustomGalleryPicker()
    }
}

// MARK: - Notifications from Custom Gallery
extension CucumberManager: GalleryPickerDelegate {
    func galleryPickerController<VC : UIViewController>(_ viewController: VC, didPickAssets assets: [PHAsset]?, withImageAtURLs urls: [URL]?) where VC : GalleryPickerProtocol {
        self.viewController.dismiss(animated: false) { [weak self] in
            viewController.galleryDelegate = nil
            
            guard let strongSelf = self else { return }
            
            if let pickedUrls = urls, let pickedAssets = assets {
                strongSelf.imageURLs.append(contentsOf: pickedUrls)
                strongSelf.selectedAssets = pickedAssets
            }
            
            strongSelf.showEditViewController()
        }
    }
}

// MARK: 
extension CucumberManager: EditViewControllerDelegate {
    func editViewControllerDidCancel(_ editViewController: EditViewController) {
        viewController.dismiss(animated: true) { 
            editViewController.delegate = nil
        }
    }
    
    func editViewController(_ editViewController: EditViewController, didDoneWithItemsAt urls: [URL]) {
        delegate?.cumberManager(self, didFinishPickingImagesWithURLs: imageURLs)
        
        viewController.dismiss(animated: true) {
            editViewController.delegate = nil
        }
    }
    
    func editViewControllerWillAddNewItem(_ editViewController: EditViewController, withCurrentItemsAt urls: [URL]) {
        imageURLs = urls
        
        viewController.dismiss(animated: false) { [weak self] in
            editViewController.delegate = nil
            
            guard let strongSelf = self else {
                return
            }
            strongSelf.showImagePicker(fromButton: strongSelf.senderButton)
        }
    }
}
