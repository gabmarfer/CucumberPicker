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


open class CucumberManager: NSObject, UIImagePickerControllerDelegate,
UINavigationControllerDelegate {
    
    @IBOutlet var overlayView: UIView!

    enum FlashIcon: String {
        case auto = "overlay-flash-auto"
        case on = "overlay-flash-on"
        case off = "overlay-flash-off"
    }
    
    var imagePickerController: UIImagePickerController?
    var viewController: UIViewController!
    
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
            self.viewController.present(alertController, animated: true, completion: nil)
        } else if (authStatus == .notDetermined) {
            // The user has not yet been presented with the option to grant access to the camera hardware.
            // Ask for it.
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo,
                                          completionHandler: { (granted) in
                                            // If access was denied, we do not set the setup error message since access was just denied.
                                            if (granted) {
                                                // Allowed access to camera, go ahead and present the UIImagePickerController.
                                                self.showImagePicker(forSourceType: self.availableSourceType(), fromButton: button)
                                            }
            })
        } else {
            self.showImagePicker(forSourceType: self.availableSourceType(), fromButton: button)
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
    
    private func showImagePicker(forSourceType sourceType: UIImagePickerControllerSourceType, fromButton button: UIBarButtonItem) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.modalPresentationStyle = .currentContext
        imagePickerController.sourceType = sourceType
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        imagePickerController.delegate = self
        imagePickerController.modalPresentationStyle = (sourceType == .camera) ? .fullScreen : .popover
        imagePickerController.cameraFlashMode = .auto
        
        let presentationController = imagePickerController.popoverPresentationController
        presentationController?.barButtonItem = button // display popover from the UIBarButtonItem as an anchor
        presentationController?.permittedArrowDirections = .any
        
        if (sourceType == .camera) {
            // The user wants to use the camera interface. Set up our custom overlay view for the camera
            imagePickerController.showsCameraControls = false
            
            /*
             Load the overlay view from the OverlayView nib file. Self is the File's Owner for the nib file, so the overlayView outlet is set to the main view in the nib. Pass that view to the image picker controller to use as its overlay view, and set self's reference to the view to nil.
             */
            Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)
            self.overlayView.frame = imagePickerController.cameraOverlayView!.frame
            debugPrint(NSStringFromCGRect(self.overlayView.frame))
            imagePickerController.cameraOverlayView = self.overlayView
            // adjust the cameraView's position
            imagePickerController.cameraViewTransform = CGAffineTransform(translationX: 0.0, y: 64.0)
            self.overlayView = nil
        }
        
        self.imagePickerController = imagePickerController
        
        self.viewController.present(self.imagePickerController!, animated: true, completion: nil)
    }
    
    // MARK: --- OverlayView actions
    @IBAction func takePhoto(_ sender: Any) {
        self.imagePickerController?.takePicture()
    }
    
    @IBAction func pickFromGallery(_ sender: Any) {
        // TODO: Open custom gallery
    }
    
    @IBAction func closeImagePicker(_ sender: Any) {
        self.viewController.dismiss(animated: true) {
            [weak self] in
            self?.imagePickerController?.delegate = nil;
        }
    }
    
    @IBAction func turnOnOffFlash(_ sender: Any) {
        let flashMode = self.imagePickerController!.cameraFlashMode as UIImagePickerControllerCameraFlashMode
        let button = sender as! UIButton
        var iconName: String
        switch flashMode {
        case .auto:
            self.imagePickerController?.cameraFlashMode = .on
            iconName = FlashIcon.on.rawValue
        case .on:
            self.imagePickerController?.cameraFlashMode = .off
            iconName = FlashIcon.off.rawValue
        case .off:
            self.imagePickerController?.cameraFlashMode = .auto
            iconName = FlashIcon.auto.rawValue
        }
        button.setImage(UIImage(named: iconName), for: .normal)
    }
    
    // MARK: Delegates
    // MARK: --- UIImagePickerControllerDelegate
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // TODO: Make something with the captured image
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        self.viewController.dismiss(animated: true) {
            picker.delegate = nil;
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.viewController.dismiss(animated: true) {
            picker.delegate = nil;
        }
    }

    
}
