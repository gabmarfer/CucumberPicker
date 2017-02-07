//
//  CucumberManager.swift
//  CucumberPicker
//
//  Created by gabmarfer on 26/01/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MobileCoreServices
import Photos

protocol CucumberDelegate: class {
    func cumberManager(_ manager: CucumberManager, didFinishPickingImagesWithURLs urls: [URL])
}

open class CucumberManager: NSObject {
    
    @IBOutlet var overlayView: UIView!

    enum FlashIcon: String {
        case auto = "overlay-flash-auto"
        case on = "overlay-flash-on"
        case off = "overlay-flash-off"
    }
    
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
    
    fileprivate var imageManager = ImageManager()
    fileprivate var imagePickerController: UIImagePickerController?
    fileprivate var viewController: UIViewController!
    
    fileprivate var selectedAssets = Array<PHAsset>()
    fileprivate var selectedImageURLs = Array<URL>()
    
    public init(_ viewController: UIViewController) {
        self.viewController = viewController
    }
    
    // MARK: Supplementary methods
    func showImagePicker(fromButton button: UIBarButtonItem) {
        // Check for permissions
        let authStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if (authStatus == .denied) {
            // Denies access to camera, alert the user.
            // The user has previously denied access. Remind the user that we need camera access to be useful.
            let alertController = UIAlertController.init(title: "Unable to access camera",
                                                         message: "To enable access, go to Settings > Privacy > Camera and turn on Camera access for this app.",
                                                         preferredStyle: .alert)
            let okAction = UIAlertAction.init(title: "OK",
                                              style: .default,
                                              handler: nil)
            alertController.addAction(okAction)
            viewController.present(alertController, animated: true, completion: nil)
        } else if (authStatus == .notDetermined) {
            // The user has not yet been presented with the option to grant access to the camera hardware.
            // Ask for it.
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo,
                                          completionHandler: { [weak self] (granted) in
                                            // If access was denied, we do not set the setup error message since access was just denied.
                                            if (granted) {
                                                guard let strongSelf = self else {
                                                    return
                                                }
                                                // Allowed access to camera, go ahead and present the UIImagePickerController.
                                                strongSelf.showImagePicker(forSourceType: strongSelf.availableSourceType(), fromButton: button)
                                            }
            })
        } else {
            showImagePicker(forSourceType: availableSourceType(), fromButton: button)
        }
    }
    
    private func availableSourceType() -> UIImagePickerControllerSourceType {
        if (UIImagePickerController.isSourceTypeAvailable(.camera)){
            return .camera
        } else if (UIImagePickerController.isSourceTypeAvailable(.photoLibrary)) {
            return .photoLibrary
        } else {
           return .savedPhotosAlbum
        }
    }
    
    fileprivate func showImagePicker(forSourceType sourceType: UIImagePickerControllerSourceType, fromButton button: UIBarButtonItem) {
        if (sourceType == .camera) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.modalPresentationStyle = .currentContext
            imagePickerController.sourceType = sourceType
            imagePickerController.mediaTypes = [kUTTypeImage as String]
            imagePickerController.delegate = self
            imagePickerController.modalPresentationStyle = (sourceType == .camera) ? .fullScreen : .popover
            
            let presentationController = imagePickerController.popoverPresentationController
            presentationController?.barButtonItem = button // display popover from the UIBarButtonItem as an anchor
            presentationController?.permittedArrowDirections = .any
            
            // Set flash to auto mode.
            imagePickerController.cameraFlashMode = .auto

            // The user wants to use the camera interface. Set up our custom overlay view for the camera
            imagePickerController.showsCameraControls = false
            
            /*
             Load the overlay view from the OverlayView nib file. Self is the File's Owner for the nib file, so the overlayView outlet is set to the main view in the nib. Pass that view to the image picker controller to use as its overlay view, and set self's reference to the view to nil.
             */
            Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)
            overlayView.frame = imagePickerController.cameraOverlayView!.frame
            debugPrint(NSStringFromCGRect(overlayView.frame))
            imagePickerController.cameraOverlayView = overlayView
            // adjust the cameraView's position
            imagePickerController.cameraViewTransform = CGAffineTransform(translationX: 0.0, y: 64.0)
            overlayView = nil
            
            self.imagePickerController = imagePickerController
            
            viewController.present(self.imagePickerController!, animated: true, completion: nil)
        } else {
            showCustomGalleryPicker()
        }
    }
    
    fileprivate func showCustomGalleryPicker() {
        let storyboard = UIStoryboard.cucumberPickerStoryboard()
        let viewControllerIdentifier = String(describing: AlbumsViewController.self)
        let albumsViewController = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier) as! AlbumsViewController
        
        // Load cached assets
        albumsViewController.selectedAssets = imageManager.cachedAssets
        
        // Listen for notifications
        registerForPickingAssetsNotifications()
        
        let albumsNavigationController = UINavigationController(rootViewController: albumsViewController)
        self.viewController.present(albumsNavigationController, animated: true, completion: nil)
    }
    
    // MARK: --- OverlayView actions
    @IBAction func takePhoto(_ sender: Any) {
        imagePickerController?.takePicture()
    }
    
    @IBAction func pickFromGallery(_ sender: Any) {
        viewController.dismiss(animated: true) { [weak self] in
            self?.imagePickerController?.delegate = nil;
        }
        showCustomGalleryPicker()
    }
    
    @IBAction func closeImagePicker(_ sender: Any) {
        viewController.dismiss(animated: true) {
            [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.imagePickerController?.delegate = nil;
        }
    }
    
    @IBAction func turnOnOffFlash(_ sender: Any) {
        let flashMode = imagePickerController!.cameraFlashMode as UIImagePickerControllerCameraFlashMode
        let button = sender as! UIButton
        var iconName: String
        switch flashMode {
        case .auto:
            imagePickerController?.cameraFlashMode = .on
            iconName = FlashIcon.on.rawValue
        case .on:
            imagePickerController?.cameraFlashMode = .off
            iconName = FlashIcon.off.rawValue
        case .off:
            imagePickerController?.cameraFlashMode = .auto
            iconName = FlashIcon.auto.rawValue
        }
        button.setImage(UIImage(named: iconName), for: .normal)
    }
}

// MARK: UIImagePickerControllerDelegate
extension CucumberManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageManager.saveImage(image)
        
        // TODO: Go to edit controller
        delegate?.cumberManager(self, didFinishPickingImagesWithURLs: imageManager.cachedURLs)
        
        viewController.dismiss(animated: true) {
            picker.delegate = nil;
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        viewController.dismiss(animated: true) {
            picker.delegate = nil;
        }
    }
}

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
        imageManager.setAssets(selectedAssets)
        
        // TODO: Go to edit controller
        delegate?.cumberManager(self, didFinishPickingImagesWithURLs: imageManager.cachedURLs)
        
        // Dismiss controller
        viewController.dismiss(animated: true)
    }
}
