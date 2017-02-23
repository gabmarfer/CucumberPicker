//
//  AssetManager.swift
//  CucumberPicker
//
//  Created by gabmarfer on 07/02/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import Foundation
import Photos

class AssetHelper: NSObject {
    
    let cucumberAlbumName = "Cucumber"
    
    enum AssetManagerNotification: String {
        case didUpdateAllPhotos
        case didUpdateSmartAlbums
        case didUpdateUserAlbums
        
        var name: NSNotification.Name {
            return NSNotification.Name(rawValue: self.rawValue)
        }
    }
    
    // All Photos
    var allPhotos: PHFetchResult<PHAsset>!
    
    // Smart Albums that contains images and have one or more assets.
    var filteredSmartAlbums = Array<PHAssetCollection>()
    
    // User Albums that contains images and have one or more assets.
    var filteredUserAlbums = Array<PHAssetCollection>()
    
    fileprivate var smartAlbums: PHFetchResult<PHAssetCollection>!
    fileprivate var userAlbums: PHFetchResult<PHAssetCollection>!
    

    
    fileprivate var onlyImagesOption: PHFetchOptions {
        let onlyImagesOption = PHFetchOptions()
        onlyImagesOption.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        onlyImagesOption.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        return onlyImagesOption
    }
    
    override init() {
        super.init()
        
        PHPhotoLibrary.shared().register(self)

        loadAssets()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: - Manage assets
    
    // Get a collection by its name
    fileprivate func getUserAlbumWithName(_ name: String, completionHandler: ((PHAssetCollection?, Error?) -> Void)? = nil) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title=%@", name)
        
        var userAlbum = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if !(userAlbum.count > 0) {
            var albumPlaceholder: PHObjectPlaceholder?
            // Create a new album with the given name
            PHPhotoLibrary.shared().performChanges({ 
                let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
                albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { (success, error) in
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "localIdentifier=%@", albumPlaceholder!.localIdentifier)
                userAlbum = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
                completionHandler?(userAlbum.firstObject, error)
            })
        } else {
            completionHandler?(userAlbum.firstObject, nil)
        }
    }
    
    
    // MARK: - Process Albums
    fileprivate func loadAssets(){
        loadAllPhotos()
        loadSmartAlbums()
        loadUserAlbums()
    }
    
    fileprivate func loadAllPhotos() {
        allPhotos = PHAsset.fetchAssets(with: self.onlyImagesOption)
    }
    
    fileprivate func loadSmartAlbums() {
        // Get fetch result.
        let smartAlbumOptions = PHFetchOptions()
        smartAlbumOptions.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: smartAlbumOptions)
        
        // Filter collections
        filteredSmartAlbums = filterFetchResult(smartAlbums)
    }
    
    fileprivate func loadUserAlbums() {
        // Get fetch result.
        let userAlbumsOptions = PHFetchOptions()
        userAlbumsOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
        userAlbumsOptions.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: userAlbumsOptions)
        
        // Filter collections
        filteredUserAlbums = filterFetchResult(userAlbums)
    }
    
    fileprivate func filterFetchResult(_ fetchResult: PHFetchResult<PHAssetCollection>) -> [PHAssetCollection] {
        // Filter to retrieve only user collections with images
        var filteredResult = [PHAssetCollection]()
        fetchResult.enumerateObjects(using: { [weak self] (obj, idx, stop) in
            guard let strongSelf = self else {
                return
            }
            let assets = PHAsset.fetchAssets(in: obj, options: strongSelf.onlyImagesOption)
            if assets.count > 0 {
                filteredResult.append(obj)
            }
        })
        return filteredResult
    }
}

// MARK: PHPhotoLibraryChangeObserver
extension AssetHelper: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Change notifications may be made on a background queue. Re-dispatch to the main queue
        // before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Check of the three top-level fetches for changes.
            if let changeDetails = changeInstance.changeDetails(for: allPhotos) {
                // Update the cached fetch result.
                allPhotos = changeDetails.fetchResultAfterChanges
                NotificationCenter.default.post(name: AssetManagerNotification.didUpdateAllPhotos.name, object: nil)
            }
            
            // Update the cached fetch results, and reload the table sections to match.
            if let changeDetails = changeInstance.changeDetails(for: smartAlbums) {
                smartAlbums = changeDetails.fetchResultAfterChanges
                filteredSmartAlbums = filterFetchResult(smartAlbums)
                NotificationCenter.default.post(name: AssetManagerNotification.didUpdateSmartAlbums.name, object: nil)
            }
            
            if let changeDetails = changeInstance.changeDetails(for: userAlbums) {
                userAlbums = changeDetails.fetchResultAfterChanges
                filteredUserAlbums = filterFetchResult(userAlbums)
                 NotificationCenter.default.post(name: AssetManagerNotification.didUpdateUserAlbums.name, object: nil)
            }
        }
    }
}
