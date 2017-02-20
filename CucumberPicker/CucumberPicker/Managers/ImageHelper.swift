//
//  ImageHelper.swift
//  CucumberPicker
//
//  Created by gabmarfer on 31/01/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import Foundation
import UIKit
import Photos

class ImageHelper: NSObject {
    
    fileprivate var cachedURLs = Dictionary<String, URL>() // <asset localIdentifier, fileURL>
    
    @discardableResult func saveImage(_ image: UIImage, named filename: String) -> URL? {
        guard let data = UIImagePNGRepresentation(image) else {
            return nil
        }
        
        do {
            let fileURL = getURL(for: filename)
            try data.write(to: fileURL)
            // Save the path
            cachedURLs[filename] = fileURL
            return fileURL
        } catch { return nil }
    }
    
    @discardableResult func saveImage(_ image: UIImage) -> URL? {
        return saveImage(image, named: randomImageKey())
    }
    
    @discardableResult func removeImage(named filename: String) -> Bool {
        do {
            let fileURL = getURL(for: filename)
            try FileManager.default.removeItem(at: fileURL)
            cachedURLs.removeValue(forKey: filename)
            return true
        } catch { return false }
    }
    
    @discardableResult func removeAllImages() -> Bool {
        var result = true
        for (filename, _) in cachedURLs {
            result = removeImage(named: filename)
        }
        return result
    }
    
//    @discardableResult func removeImage(at URL: URL) -> Bool {
//        do {
//            try FileManager.default.removeItem(at: URL)
//            // Remove cached path
//            
//            return true
//        } catch {
//            return false
//        }
//    }
//    
//    func removeAllImages() {
//        for url in cachedURLs {
//            try? FileManager.default.removeItem(at: url)
//        }
//        cachedURLs.removeAll()
//    }

    fileprivate func randomImageKey() -> String {
        return NSUUID().uuidString + ".png"
    }
    
    fileprivate func getURL(for filename: String) -> URL {
        return NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)!
    }
}
