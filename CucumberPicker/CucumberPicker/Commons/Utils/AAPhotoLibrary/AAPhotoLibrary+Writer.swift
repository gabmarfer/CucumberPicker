//
//  AAPhotoLibrary.swift
//  Depositphotos
//
//  Created by Armen Abrahamyan on 4/26/16.
//  Copyright © 2016 Depositphotos Inc. All rights reserved.
//

import Foundation
import Photos

/**
 ** This extension is responsible for writing items into photo library
 **/
extension PHPhotoLibrary {
    
    // MARK: Public save into album methods
    
    /**
     * Check and decide what to do based on Authorization Status
     */
    @objc
    public final class func addNewImage(_ folderName: String, image: UIImage, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        checkAuthorizationStatusAndSaveImage(folderName, image: image, videoFileUrl: nil, completion: completion)
    }
    
    /**
     * Accepts folder name and image data and stores in appropriate folder
     */
    @objc
    public class func addNewImage(_ folderName: String, itemData: Data, completion:@escaping (_ success: Bool, _ error: Error?) -> Void) {
        
        if let image = convertDataToImage(itemData) {
            addNewImage(folderName, image: image, completion: completion)
        } else {
            completion(false, AAPLErrorHandler.aaDataNotConvertible.rawValue.error)
        }
    }
    
    /**
    * Add a new video into library
    */
    @objc
    public class func addNewVideo (_ folderName: String, videoFileUrl: URL, completion:@escaping (_ success: Bool, _ error: Error?) -> Void) {
        checkAuthorizationStatusAndSaveImage(folderName, image: nil, videoFileUrl: videoFileUrl, completion: completion)
    }
    
    /**
     * Removes Asset from Library
     */
    @objc
    public class func deleteItemFromFolder (_ itemAssetId: String, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        checkAuthorizationStatus { (authorizationStatus, error) in
            shared().performChanges({
                let options = PHFetchOptions()
                options.predicate = NSPredicate(format: "localIdentifier=%@", itemAssetId)
                let assetsToDelete = PHAsset.fetchAssets(with: options)
                
                if assetsToDelete.count > 0 {
                    PHAssetChangeRequest.deleteAssets(assetsToDelete)
                } else {
                    completion(false, AAPLErrorHandler.aaUnableDeleteAsset.rawValue.error)
                }
                
            }) { (completed: Bool, error: Error?) in
                completion(completed, error)
            }
        }
    }
    
    /**
    * Removes folder by Id
    */
    @objc
    public class func deleteFolderById (_ folderId: String, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        shared().performChanges({
            
            let collections = findCollectionById(folderId)
            if collections != nil {
                PHAssetCollectionChangeRequest.deleteAssetCollections(collections!)
            } else {
                completion(false, AAPLErrorHandler.aaUnableDeleteCollection.rawValue.error)
            }
            
        }) { (completed: Bool, error: Error?) in
            completion(completed, error)
        }
    }
    
    /**
    * Removes folder by Name
    * WARNING - Will remove first found folder of that name. Won't remove any folder from SmartAlbum. It is recommended that you use 'deleteFolderById' instead.
    */
    @objc
    public class func deleteFolderByName (_ folderName: String, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        shared().performChanges({
            
            let collections = findCollectionByName(folderName)
            if collections != nil {
                PHAssetCollectionChangeRequest.deleteAssetCollections(collections!)
            } else {
                completion(false, AAPLErrorHandler.aaUnableDeleteCollection.rawValue.error)
            }
            
        }) { (completed: Bool, error: Error?) in
            completion(completed, error)
        }
    }

    
    // MARK: Private helper methods
    
    /** 
     * Finds collection By Id
     */
    @objc
    public final class func findCollectionById (_ folderIdentifier: String) -> NSFastEnumeration? {
        return PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [folderIdentifier], options: nil)
    }
    
    /**
     * Finds collection By Name
     */
    @objc
    fileprivate final class func findCollectionByName (_ folderName: String) -> NSFastEnumeration? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title=%@", argumentArray: [folderName])
        
        return PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
    }
    
    /**
     * Decide what to save based on authorization status
     */
    @objc
    fileprivate final class func checkAuthorizationStatusAndSaveImage(_ folderName: String, image: UIImage?, videoFileUrl: URL?, completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        
        
        checkAuthorizationStatus { (authorizationStatus, error) in
            
            switch (authorizationStatus) {
                
                case .authorized:
                    saveItemIntoFolder(folderName, image: image, videoFileUrl: videoFileUrl, completion: completion)
                    break
                    
                case .restricted:
                    print("Access is restricted: Maybe parental controls are turned on ?")
                    completion(false, error)
                    break
                    
                case .denied:
                    print("User denied an access to library")
                    completion(false, error)
                    break
                
                default:
                    completion(false, error)
            }

        }
        
    }
    
    /**
     * Accepts folder name and UIImage and stores in appropriate folder
     */
    @objc
    fileprivate class func saveItemIntoFolder (_ folderName: String, image: UIImage?, videoFileUrl: URL?, completion:@escaping (_ success: Bool, _ error: Error?) -> Void) {
        
            var fetchResults: PHFetchResult<PHAsset>?
            findCollectionByName(folderName, collectionType: .album, completed: { (success, collection) in
                
              shared().performChanges({
                
                if success {
                    if collection != nil {
                        var placeHolderObject: PHObjectPlaceholder?
                        
                        if let url = videoFileUrl {
                            placeHolderObject = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)?.placeholderForCreatedAsset
                        } else {
                            placeHolderObject = PHAssetChangeRequest.creationRequestForAsset(from: image!).placeholderForCreatedAsset
                        }
                        if let placeholder = placeHolderObject {
                            fetchResults = PHAsset.fetchAssets(in: collection!, options: nil)
                            if let photoAssets = fetchResults {
                                let folderChangeRequest = PHAssetCollectionChangeRequest(for: collection!, assets: photoAssets)
                                let array: [PHObjectPlaceholder] = [placeholder]
                                folderChangeRequest?.addAssets(array as NSFastEnumeration)
                            }
                        }
                    }

                }
                
            }) { (completed: Bool, error: Error?) in
                if error != nil {
                    completion(false, error)
                } else {
                    completion(true, error)
                }
            }
            })
            
    }
    
    /**
    * Private method, used for saving item into folder.
    */
    @objc
    fileprivate final class func findCollectionByName (_ folderName: String, collectionType: PHAssetCollectionType, completed: @escaping (_ success:Bool, _ collectionName: PHAssetCollection?) -> Void) {
        var collection: PHAssetCollection?
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title=%@", argumentArray: [folderName])
        collection = PHAssetCollection.fetchAssetCollections(with: collectionType, subtype: .any, options: fetchOptions).firstObject
        
        if collection == nil {
            var placeHolder: PHObjectPlaceholder?
            shared().performChanges({
                let albumCreationRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: folderName)
                placeHolder = albumCreationRequest.placeholderForCreatedAssetCollection
            }) { (success: Bool, error: Error?) in
                if success {
                    let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeHolder!.localIdentifier], options: nil)
                    collection = fetchResult.firstObject
                    completed(success, collection)
                } else {
                    completed(false, nil)
                }
            }
        } else {
            completed(true, collection)
        }
    }
    
    /**
    * Converts image data into UIImage
    */
    @objc
    fileprivate final class func convertDataToImage (_ imageData: Data) -> UIImage? {
        return UIImage(data: imageData)
    }
    
    /**
    * Freshen image with new size and JPEG format
    */
    @objc
    fileprivate final class func freshenImageToJPEG (_ image: UIImage) -> UIImage? {
        let imageData = UIImageJPEGRepresentation(image, 1.0)
        return UIImage(data: imageData!)
    }        
    
}



