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
    static let maxImages = 6
    
    enum CucumberNotification: String {
        case didFinishPickingAssets

        var name: Notification.Name {
            return Notification.Name(rawValue: self.rawValue)
        }
    }
    
    enum CucumberNotificationObject: String {
        case selectedAssets
    }
    
    weak var delegate: CucumberDelegate?
    
    fileprivate var cameraManager: CameraManager!
    fileprivate var viewController: UIViewController!
    
    fileprivate var imageURLs = Array<URL>()
    fileprivate var selectedAssets = Array<PHAsset>()
    
    public init(_ viewController: UIViewController) {
        self.viewController = viewController
        
        cameraManager = CameraManager(viewController)
    }
    
    // MARK: Public methods
    
    func showImagePicker(fromButton button: UIBarButtonItem) {
        cameraManager.delegate = self
        cameraManager.showCamera(fromButton: button)
    }
    
    // MARK: Private methods
    
    fileprivate func showCustomGalleryPicker() {
        let storyboard = UIStoryboard.cucumberPickerStoryboard()
        let viewControllerIdentifier = String(describing: AlbumsViewController.self)
        let albumsViewController = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier) as! AlbumsViewController
        
        // Load cached assets
//        albumsViewController.selectedAssets = imageManager.cachedAssets
        
        // Listen for notifications
        registerForPickingAssetsNotifications()
        
        let albumsNavigationController = UINavigationController(rootViewController: albumsViewController)
        self.viewController.present(albumsNavigationController, animated: true, completion: nil)
    }
    
    fileprivate func showEditViewController() {
        let storyboard = UIStoryboard.cucumberPickerStoryboard()
        let viewControllerIdentifier = String(describing: EditViewController.self)
        let editViewController = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier) as! EditViewController
        editViewController.imageURLs = imageURLs
        
        self.viewController.present(editViewController, animated: true, completion: nil)
    }
}

// MARK: CameraManagerDelegate
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

// MARK: Notifications from Custom Gallery
extension CucumberManager {
    func registerForPickingAssetsNotifications() {
        NotificationCenter.default.addObserver(self, selector:
            #selector(didFinishPickingAssets(notification:)),
                                               name: CucumberNotification.didFinishPickingAssets.name,
                                               object: nil)
    }
    
    func unregisterForPickingAssetsNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: CucumberNotification.didFinishPickingAssets.name,
                                                  object: nil)
    }
    
    func didFinishPickingAssets(notification: Notification) {
        unregisterForPickingAssetsNotifications()
        
        // Cache selected assets
        let selectedAssets = notification.userInfo?[CucumberNotificationObject.selectedAssets.rawValue] as! [PHAsset]
//        imageManager.setAssets(selectedAssets)
        
        // TODO: Go to edit controller
//        delegate?.cumberManager(self, didFinishPickingImagesWithURLs: imageManager.cachedURLs)
        
        // Dismiss controller
        viewController.dismiss(animated: true)
    }
}
