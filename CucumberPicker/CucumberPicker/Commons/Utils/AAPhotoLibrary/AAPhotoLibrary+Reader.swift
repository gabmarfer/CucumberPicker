//
//  AAPhotoLibrary+Reader.swift
//  AAPhotoLibrary
//
//  Created by Armen Abrahamyan on 5/7/16.
//  Copyright © 2016 Armen Abrahamyan. All rights reserved.
//

import Foundation
import Photos

/**
** This extension is responsible for reading photo library content
**/
extension PHPhotoLibrary {
    
    // MARK: Public methods    
    /**
    * Fetch All Collections
    */
    @objc
    public final class func fetchCollectionsByType(_ type:PHAssetCollectionType, includeHiddenAssets: Bool, sortByName: Bool, completion: @escaping (_ fetchResults: PHFetchResult<PHAssetCollection>?, _ error: NSError?) -> Void) {
    
        checkAuthorizationStatus { (authorizationStatus, error) in
            
            guard authorizationStatus == .authorized else {
                completion(nil, error)
                print("Impossible to access the Photo Library, please make sure that you don't expilicitly deneid access or there is no specific parenthal control enabled !")
                return
            }
            
            let options = PHFetchOptions()
            options.includeHiddenAssets = includeHiddenAssets
            
            if sortByName {
                options.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
            }
            
            let collection = PHAssetCollection.fetchAssetCollections(with: type, subtype: .any, options: options)
            completion(collection, nil)
            
        }
        
    }
    
    /**
    * Fetches all images from collection
    */
    @objc
    public final class func fetchAllItemsFromCollection(_ collectionType: PHAssetCollectionType, collectionId: String, sortByDate: Bool, completion: @escaping (_ fetchResult: PHFetchResult<PHAsset>?, _ error: NSError?) -> Void) {
        
        checkAuthorizationStatus { (authorizationStatus, error) in
            let collection = findCollectionById(collectionId, collectionType: collectionType)
            if collection != nil {
                let options = PHFetchOptions()
                
                if sortByDate {
                    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                }
                
                let fetchResult = PHAsset.fetchAssets(in: collection!, options: options)
                completion(fetchResult, error)
            }
        }
    }
    
    /**
    * Get an image from asset identifier
    //PHImageManagerMaximumSize
    */
    @objc
    public class func imageFromAssetIdentifier(_ asstItemIdentifeir: String, size: CGSize, completion: @escaping (_ image: UIImage?, _ info:[AnyHashable: Any]?) -> Void) {
        checkAuthorizationStatus { (authorizationStatus, error) in
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "localIdentifier=%@", asstItemIdentifeir)
            let fetchResult = PHAsset.fetchAssets(with: options)
            
            if let asset = fetchResult.firstObject {
                imageFromAsset(asset, size: size, completion: completion)
            }
        }
    }
    
    
    /**
     * TODO: MOVE REQUEST OPTIONS AS ARGUMENTS
     * Retrieves an original image from an asset object
     */
    @objc
    public class func imageFromAsset(_ asset: PHAsset, size: CGSize, completion: @escaping (_ image: UIImage?, _ info: [AnyHashable: Any]?) -> Void) {
       checkAuthorizationStatus { (authorizationStatus, error) in
        if asset.mediaType == .image {
            let requestOptions = PHImageRequestOptions()
            requestOptions.resizeMode = .exact
            requestOptions.deliveryMode = .highQualityFormat
            requestOptions.isSynchronous = false
            
            PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: requestOptions, resultHandler: { (image, info) in
                completion(image, info)
            })
        } else {
            completion(nil, ["error": "Asset is not of an image type."])
        }
       }
    }
    
    /**
    * Retrieves a video from an Asset object
    */
    @objc
    public class func videoFromAsset(_ asset: PHAsset, completion: @escaping (_ avplayerItem: AVPlayerItem?, _ info: [AnyHashable: Any]?) -> Void) {
        checkAuthorizationStatus { (authorizationStatus, error) in
            if asset.mediaType == .video {
                let requestOptions = PHVideoRequestOptions()
                requestOptions.deliveryMode = .highQualityFormat
                
                PHImageManager.default().requestPlayerItem(forVideo: asset, options: requestOptions, resultHandler: { (avplayerItem, info) in
                    completion(avplayerItem, info)
                })
            } else {
                completion(nil, ["error": "Asset is not of an image type."])
            }
        }
    }
    
    /**
     * Check Authorization status
     */
    @objc
    public final class func checkAuthorizationStatus(_ completion: @escaping (_ authorizationStatus: PHAuthorizationStatus, _ error: NSError?) -> Void) {
        
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch (status) {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) in
                completion(status, AAPLErrorHandler.aaForceAccessDenied.rawValue.error)
            })
            break
            
        case .authorized:
            completion(status, nil)
            break
            
        case .restricted:
            print("Access is restricted: Maybe parental controls are turned on ?")
            completion(status, AAPLErrorHandler.aaRestricted.rawValue.error)
            break
            
        case .denied:
            print("User denied an access to library")
            completion(status, AAPLErrorHandler.aaDenied.rawValue.error)
            break
            
        }
    }
    
    // MARK: Private Helpers
    /**
     * Search Collection By Local Stored Identifeir
     */
    @objc
    fileprivate final class func findCollectionById (_ folderIdentifier: String, collectionType: PHAssetCollectionType) -> PHAssetCollection? {
        var collection: PHAssetCollection?
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "localIdentifier=%@", folderIdentifier)
        collection = PHAssetCollection.fetchAssetCollections(with: collectionType, subtype: .any, options: fetchOptions).firstObject 
        
        return collection
    }
}
