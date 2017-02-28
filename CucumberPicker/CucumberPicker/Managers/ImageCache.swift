//
//  ImageCache.swift
//  CucumberPicker
//
//  Created by gabmarfer on 31/01/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//
//  Cache images in a temporary folder. Load them using its URLs.

import Foundation
import UIKit
import Photos

class ImageCache: NSObject {
    
    var maximumImageSize = CGSize(width: 1024.0, height: 1024.0)
    var mininumImageSize = CGSize(width: 400.0, height: 400.0)
    
    /// Ordered list of selected image URLs
    private(set) var imageURLs = Array<URL>()
    
    /// Set of selected assets to allow deselect them
    private(set) var selectedAssets = Set<PHAsset>()
    
    var images: [UIImage] {
        var images = [UIImage]()
        do {
            for fileURL in imageURLs {
                let data = try Data(contentsOf: fileURL)
                if let image = UIImage(data: data) {
                    images.append(image)
                }
            }
        } catch { print("Error \(error)") }
        
        return images
    }
    
    var numberOfTakenPhotos: Int {
        return imageURLs.count - selectedAssets.count
    }

    fileprivate var cachedURLs = Dictionary<String, URL>() // <imageKey, fileURL>
    fileprivate let imageExtension = ".jpg"
    fileprivate var assetIdentifierKeys = Dictionary<String, String>() // <assetLocalIdentifier, imageKey>
    
    // MARK: Utils
    func thumbnailImageFromAsset(_ asset: PHAsset, of width: Int) -> UIImage? {
        guard let imageKey = assetIdentifierKeys[asset.localIdentifier], let fileURL = cachedURLs[imageKey] else {
            return nil
        }
        
        guard let image = UIImage(contentsOfFile: fileURL.path) else {
            return nil
        }
        
        return thumbnailImageFromImage(image, of: width)
    }
    
    func thumbnailImageFromImage(_ image: UIImage, of width: Int) -> UIImage {
        return image.thumbnailImage(width, transparentBorder: 0, cornerRadius: 0, interpolationQuality: .high)
    }

    // MARK: Cache assets
    func saveImageFromAsset(_ asset: PHAsset, resultHandler: ((URL?) -> Void)?) {
        let requestOptions = PHImageRequestOptions()
        requestOptions.resizeMode = .exact
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isSynchronous = false
        
        PHImageManager.default().requestImage(for: asset, targetSize: maximumImageSize, contentMode: .aspectFill, options: requestOptions, resultHandler: {
            [weak self] (image, info) in
            
            guard let strongSelf = self else { return }
            
            if let imageToSave = image, let url = strongSelf.saveImage(imageToSave, named: strongSelf.keyForAsset(asset)) {
                guard let strongSelf = self else { return }
                strongSelf.selectedAssets.insert(asset)
                resultHandler?(url)
            } else {
                resultHandler?(nil)
            }
        })
    }
    
    func urlsForAssets(_ assets: [PHAsset]) -> [URL] {
        var urls = Array<URL>()
        for asset in assets {
            if let imageKey = assetIdentifierKeys[asset.localIdentifier], let fileURL = cachedURLs[imageKey] {
                urls.append(fileURL)
            }
        }
        return urls
    }
    
    @discardableResult func removeImageFromAsset(_ asset: PHAsset) -> Bool {
        let key = keyForAsset(asset)
        selectedAssets.remove(asset)
        return removeImage(named: key)
    }
    
    // MARK: Cache images
    @discardableResult func saveImage(_ image: UIImage) -> URL? {
        return saveImage(image, named: randomImageKey())
    }
    
    @discardableResult func removeImage(named filename: String) -> Bool {
        do {
            let fileURL = getURL(for: filename)
            try FileManager.default.removeItem(at: fileURL)
            cachedURLs.removeValue(forKey: filename)
            if let urlIdx = imageURLs.index(of: fileURL) {
                imageURLs.remove(at: urlIdx)
            }
//            print("Removed image in path: \(fileURL)")
            return true
        } catch { return false }
    }
    
    @discardableResult func removeAllImages() -> Bool {
        var result = true
        for (filename, _) in cachedURLs {
            result = removeImage(named: filename)
        }
        selectedAssets.removeAll()
        return result
    }
    
    // MARK: Private methods
    
    @discardableResult fileprivate func saveImage(_ image: UIImage, named filename: String) -> URL? {
        // Scale the image before saving
        let newSize = (image.size.width > maximumImageSize.width || image.size.height > maximumImageSize.height) ? maximumImageSize : image.size
        var compressedImage = image.resizedImageWithContentMode(.scaleAspectFill, bounds: newSize, interpolationQuality: .medium)
        if (compressedImage.size.width < mininumImageSize.width || compressedImage.size.height < mininumImageSize.height) {
            compressedImage = compressedImage.resizedImageWithContentMode(.scaleAspectFill, bounds: mininumImageSize, interpolationQuality: .high)
        }
        
        guard let data = UIImageJPEGRepresentation(compressedImage, 1.0) else { return nil }
        
        do {
            let fileURL = getURL(for: filename)
            try data.write(to: fileURL)
            // Save the path
            cachedURLs[filename] = fileURL
            imageURLs.append(fileURL)
//            print("Saved image in path: \(fileURL)")
            return fileURL
        } catch {
            print("error saving file: \(error)")
            return nil
        }
    }
    
    fileprivate func randomImageKey() -> String {
        return NSUUID().uuidString + imageExtension
    }
    
    fileprivate func keyForAsset(_ asset: PHAsset) -> String {
        // If asset is already saved, just return its imageKey
        if let imageKey = assetIdentifierKeys[asset.localIdentifier] {
            return imageKey
        }
        
        // Save imageKey
        let newImageKey = randomImageKey()
        assetIdentifierKeys[asset.localIdentifier] = newImageKey
        
        return newImageKey
    }
    
    fileprivate func getURL(for filename: String) -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
    }
}
