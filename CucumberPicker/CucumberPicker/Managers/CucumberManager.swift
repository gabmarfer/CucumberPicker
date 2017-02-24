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
        showImagePicker(fromButton: button, animated: true)
    }
    
    // MARK: Private methods
    
    fileprivate func showImagePicker(fromButton button: UIBarButtonItem, animated flag: Bool) {
        showImagePicker(fromButton: button, animated: flag, from: viewController)
    }
    
    fileprivate func showImagePicker(fromButton button: UIBarButtonItem, animated flag: Bool, from viewController: UIViewController) {
        senderButton = button
        cameraManager.delegate = self
        cameraManager.showCamera(fromButton: button, animated: flag, from: viewController)
    }
    
    fileprivate func showCustomGalleryPicker(from viewController: UIViewController) {
        let storyboard = UIStoryboard.cucumberPickerStoryboard()
        let viewControllerIdentifier = String(describing: AlbumsViewController.self)
        let albumsViewController = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier) as! AlbumsViewController
        
        // Load cached assets
        albumsViewController.galleryDelegate = self
        albumsViewController.selectedAssets = selectedAssets
        albumsViewController.takenPhotos = (imageURLs.count - selectedAssets.count)
        
        let albumsNavigationController = UINavigationController(rootViewController: albumsViewController)
        viewController.present(albumsNavigationController, animated: false, completion: nil)
    }
    
    fileprivate func showEditViewController() {
        guard imageURLs.count > 0 else {
            return
        }
        
        let storyboard = UIStoryboard.cucumberPickerStoryboard()
        let viewControllerIdentifier = String(describing: EditViewController.self)
        let editViewController = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier) as! EditViewController
        editViewController.imageURLs = imageURLs
        editViewController.delegate = self
        
        self.viewController.present(editViewController, animated: false, completion: nil)
    }
    
    fileprivate func removeAllImages() {
        selectedAssets.removeAll()
        imageURLs.removeAll()
        ImageCache().removeAllImages()
    }
}

// MARK: - CameraManagerDelegate
extension CucumberManager: CameraManagerDelegate {
    func cameraManagerDidCancel(_ manager: CameraManager) {
        manager.presentingViewController.dismiss(animated: true)
    }
    
    func cameraManagerDidSelectOpenGallery(_ manager: CameraManager) {
        manager.delegate = nil
        
        manager.presentingViewController.dismiss(animated: false) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.showCustomGalleryPicker(from: manager.presentingViewController)
        }
    }
    
    func cameraManager(_ manager: CameraManager, didPickImageAtURL url: URL) {
        manager.delegate = nil
        
        imageURLs.append(url)
        
        let isEditing = manager.presentingViewController is EditViewController
        
        if isEditing {
            // Just update the image urls of the editViewController before dismissing the picker
            let editViewController = manager.presentingViewController as! EditViewController
            editViewController.imageURLs = imageURLs
        }
        
        manager.presentingViewController.dismiss(animated: false) { [weak self] in
            // If editViewController is not displayed, show it now
            if !isEditing {
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.showEditViewController()
            }
        }
    }
    

}

// MARK: - Notifications from Custom Gallery
extension CucumberManager: GalleryPickerDelegate {
    func galleryPickerController<VC : UIViewController>(_ viewController: VC, didPickAssets assets: [PHAsset]?, withImageAtURLs urls: [URL]?) where VC : GalleryPickerProtocol {
        viewController.galleryDelegate = nil
        
        // Update assets & image urls
        if let pickedUrls = urls, let pickedAssets = assets {
            imageURLs.append(contentsOf: pickedUrls)
            selectedAssets = pickedAssets
        }
        
        let isEditing = viewController.presentingViewController is EditViewController
        
        if isEditing {
            // Just update the image urls of the editViewController before dismissing the gallery picker
            let editViewController = viewController.presentingViewController as! EditViewController
            editViewController.imageURLs = imageURLs
        }
        
        
        viewController.presentingViewController?.dismiss(animated: false) { [weak self] in
            // If editViewController is not displayed, show it now
            if !isEditing {
                guard let strongSelf = self else {
                    return
                }
                strongSelf.showEditViewController()
            }
        }
    }
}

// MARK: 
extension CucumberManager: EditViewControllerDelegate {
    func editViewControllerDidCancel(_ editViewController: EditViewController) {
        removeAllImages()
        
        viewController.dismiss(animated: true) { 
            editViewController.delegate = nil
        }
    }
    
    func editViewController(_ editViewController: EditViewController, didDoneWithItemsAt urls: [URL]) {
        delegate?.cumberManager(self, didFinishPickingImagesWithURLs: imageURLs)
        
        viewController.dismiss(animated: true) { [weak self] in
            editViewController.delegate = nil
            
            guard let strongSelf = self else {
                return
            }
            strongSelf.removeAllImages()
        }
    }
    
    func editViewControllerWillAddNewItem(_ editViewController: EditViewController, withCurrentItemsAt urls: [URL]) {
        imageURLs = urls
        
        // Show image picker from editViewController
        showImagePicker(fromButton: senderButton, animated: false, from: editViewController)
        
//        viewController.dismiss(animated: false) { [weak self] in
//            editViewController.delegate = nil
//            
//            guard let strongSelf = self else {
//                return
//            }
//            strongSelf.showImagePicker(fromButton: strongSelf.senderButton, animated: false, from: editViewController)
//        }
    }
}
