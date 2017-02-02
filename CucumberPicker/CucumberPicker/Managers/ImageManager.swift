//
//  ImageManager.swift
//  CucumberPicker
//
//  Created by gabmarfer on 31/01/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import Foundation
import UIKit
import Photos

class ImageManager: NSObject {
    
    var cachedURLs = Array<URL>()
    
    var cachedAssets = [PHAsset]()
    
    fileprivate var assetURLs = Dictionary<String, URL>() // <asset localIdentifier, fileURL>
    
    fileprivate var assetImageManager = PHImageManager()
    
    @discardableResult func saveImage(_ image: UIImage) -> Bool {
        guard let data = UIImagePNGRepresentation(image) else {
            return false
        }
        
        do {
            let filename = randomImageKey()
            let fileURL = temporaryURL(for: filename)
            try data.write(to: fileURL)
            // Save the path
            cachedURLs.append(fileURL)
            return true
        } catch { return false }
    }
    
    func removeAllImages() {
        for URL in cachedURLs {
            try? FileManager.default.removeItem(at: URL)
        }
        cachedURLs.removeAll()
    }
    
    @discardableResult func removeImage(at URL: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: URL)
            // Remove cached path
            if let index = cachedURLs.index(of: URL) {
                cachedURLs.remove(at: index)
            }
            return true
        } catch {
            return false
        }
    }
    
    func setAssets(_ assets: [PHAsset]) {
        // Remove cached assets that aren't contained in the new set of selected assets
        for cachedAsset in cachedAssets {
            if !assets.contains(cachedAsset) {
                removeAsset(cachedAsset)
            }
        }
        
        // Save new assets
        for selectedAsset in assets {
            if !cachedAssets.contains(selectedAsset) {
                saveAsset(selectedAsset)
            }
        }
    }
    
    fileprivate func randomImageKey() -> String {
        return NSUUID().uuidString + ".png"
    }
    
    fileprivate func temporaryURL(for filename: String) -> URL {
        return NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)!
    }
    
    fileprivate func saveAsset(_ asset: PHAsset) {
        assetImageManager.requestImageData(for: asset, options: nil) { [weak self] (imageData, dataUTI, orientation, info) in
            guard let strongSelf = self else {
                return
            }
            
            let filename = strongSelf.randomImageKey()
            let fileURL = strongSelf.temporaryURL(for: filename)
            try? imageData?.write(to: fileURL)
            
            // Save the path
            strongSelf.cachedURLs.append(fileURL)
            
            // Save the asset url
            strongSelf.assetURLs[asset.localIdentifier] = fileURL
        }
    }
    
    fileprivate func removeAsset(_ asset: PHAsset) {
        // Remove cached image
        if let fileURL = assetURLs[asset.localIdentifier] {
            removeImage(at: fileURL)
        }
        
        // Remove cached URL
        assetURLs.removeValue(forKey: asset.localIdentifier)
        
        // Remove cached asset
        if let idx = cachedAssets.index(of: asset) {
            cachedAssets.remove(at: idx)
        }
    }
    
    
}
