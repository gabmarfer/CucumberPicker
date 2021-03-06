//
//  CameraManager.swift
//  CucumberPicker
//
//  Created by gabmarfer on 07/02/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//
//  Manage ImagePickerController to take a photo and return a PHAsset

import Foundation
import UIKit
import AVFoundation
import MobileCoreServices
import Photos

protocol CameraManagerDelegate: class {
    func cameraManagerDidCancel(_ manager: CameraManager)
    func cameraManager(_ manager: CameraManager, didPickImageAtURL url: URL)
    func cameraManagerShouldOpenGallery(_ manager: CameraManager)
}

class CameraManager: NSObject {
    
    @IBOutlet var overlayView: UIView!
    
    enum FlashIcon: String {
        case auto = "overlay-flash-auto"
        case on = "overlay-flash-on"
        case off = "overlay-flash-off"
    }
    
    weak var delegate: CameraManagerDelegate?
    weak private(set) var presentingViewController: UIViewController!
    var imageCache: ImageCache!
    
    fileprivate var imagePickerController: UIImagePickerController?
    
    public init(_ presentingViewController: UIViewController, imageCache: ImageCache) {
        self.presentingViewController = presentingViewController
        self.imageCache = imageCache
        
        super.init()
    }
    
    // MARK: Public methods
    
    func showCamera(fromButton button: UIBarButtonItem, animated flag: Bool, from viewController: UIViewController) {
        self.presentingViewController = viewController
        
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
                                                guard let strongSelf = self else { return }
                                                // Allowed access to camera, go ahead and present the UIImagePickerController.
                                                strongSelf.showImagePicker(forSourceType: strongSelf.availableSourceType(), fromButton: button, animated: flag)
                                            }
            })
        } else {
            showImagePicker(forSourceType: availableSourceType(), fromButton: button, animated: flag)
        }
    }
    
    // MARK: Private methods
    
    fileprivate func availableSourceType() -> UIImagePickerControllerSourceType {
        if (UIImagePickerController.isSourceTypeAvailable(.camera)){
            return .camera
        } else if (UIImagePickerController.isSourceTypeAvailable(.photoLibrary)) {
            return .photoLibrary
        } else {
            return .savedPhotosAlbum
        }
    }
    
    fileprivate func showImagePicker(forSourceType sourceType: UIImagePickerControllerSourceType, fromButton button: UIBarButtonItem, animated flag: Bool) {
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
            
            presentingViewController.present(self.imagePickerController!, animated: flag, completion: nil)
        } else {
            delegate?.cameraManagerShouldOpenGallery(self)
        }
    }
    
    // MARK: OverlayView actions
    @IBAction func takePhoto(_ sender: Any) {
        imagePickerController?.takePicture()
    }
    
    @IBAction func pickFromGallery(_ sender: Any) {
        imagePickerController?.delegate = nil;
        
        // Dismiss camera before displaying the gallery
        presentingViewController.dismiss(animated: false) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.cameraManagerShouldOpenGallery(strongSelf)
        }
    }
    
    @IBAction func closeImagePicker(_ sender: Any) {
        imagePickerController?.delegate = nil;
        delegate?.cameraManagerDidCancel(self)
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
extension CameraManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.delegate = nil;
        
        // Save image to disk and notify the CucumberManager
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        let fileURL = imageCache.saveImage(image.fixedOrientation())
        
        delegate?.cameraManager(self, didPickImageAtURL: fileURL!)
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.delegate = nil
        
        delegate?.cameraManagerDidCancel(self)
    }
}
