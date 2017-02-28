//
//  AssetGridViewController.swift
//  CucumberPicker
//
//  Created by gabmarfer on 27/01/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

class AssetGridViewController: UICollectionViewController, GalleryPickerProtocol {
    
    var numberOfSelectableAssets: Int {
        return CucumberManager.Custom.maxImages - imageCache.imageURLs.count
    }
    
    weak var galleryDelegate: GalleryPickerDelegate?
    var fetchResult: PHFetchResult<PHAsset>!
    var imageCache: ImageCache!

    fileprivate let assetImageManager = PHCachingImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var previousPreheatRect = CGRect.zero
    fileprivate var photosCompleted = 0
    
    // MARK: - ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetCachedAssets()
        PHPhotoLibrary.shared().register(self)
        
        // Create done button
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        navigationItem.rightBarButtonItem = doneButton

        collectionView?.allowsMultipleSelection = true

        // If we get here without a segue, it's because we're visible at app launch,
        // so match the behaviour of segue from the default "All Photos" view
        if fetchResult == nil {
            let allPhotosOption = PHFetchOptions()
            allPhotosOption.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            allPhotosOption.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            fetchResult = PHAsset.fetchAssets(with: allPhotosOption)
        }
        
        
        // Select previously selected items.
        for asset in Array(imageCache.selectedAssets) {
            let index = fetchResult.index(of: asset)
            if index != NSNotFound {
                let indexPath = IndexPath(item: index, section: 0)
                collectionView?.selectItem(at: indexPath, animated: false, scrollPosition: .bottom)
            }
            
        }
        
        // Scroll down
        // FIXME: We have to repeat scrollToItem in order to assure that the last row is fully visible.
        let lastIndexPath = IndexPath(item: (fetchResult.count - 1), section: 0)
        collectionView?.scrollToItem(at: lastIndexPath, at: .bottom, animated: false)
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.collectionView?.scrollToItem(at: lastIndexPath, at: .bottom, animated: false)
        }
        
        configureGalleryToolbar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale = UIScreen.main.scale
        let cellSize = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        
        updateGalleryToolbarTitle(selected: imageCache.imageURLs.count, of: CucumberManager.Custom.maxImages)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    func done(_ sender: AnyObject) {
        galleryDelegate?.galleryPickerControllerDidFinishPickingAssets(self)
    }
    
    // MARK: UICollectionView
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: GridViewCell.self),
                                                            for: indexPath) as? GridViewCell else { fatalError() }
        
        let asset = fetchResult.object(at: indexPath.item)
        
        // Request an image for the asset from the PHCachingManager.
        cell.representedAssetIdentifier = asset.localIdentifier
        assetImageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil) { (image, _) in
            // The cell may have been recycled by the time this handler gets called;
            // Set the cell's thumbnail image only if it's still showing the same asset.
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return numberOfSelectableAssets > 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = fetchResult.object(at: indexPath.item)
        
        // Cache image
        imageCache.saveImageFromAsset(asset) { [weak self] (url) in
            // Update the toolbar
            guard let strongSelf = self else { return }
            strongSelf.updateGalleryToolbarTitle(selected: strongSelf.imageCache.imageURLs.count, of: CucumberManager.Custom.maxImages)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let asset = fetchResult.object(at: indexPath.item)
        
        // Remove cached image
        imageCache.removeImageFromAsset(asset)
        
        // Update the toolbar
        updateGalleryToolbarTitle(selected: imageCache.imageURLs.count, of: CucumberManager.Custom.maxImages)
    }
}

// MARK: - Asset caching
extension AssetGridViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
    fileprivate func resetCachedAssets() {
        assetImageManager.stopCachingImagesForAllAssets()
        previousPreheatRect = .zero
    }
    
    fileprivate func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        
        // The preheat window is twice the height of the visible rect.
        let preheatRect = view!.bounds.insetBy(dx: 0, dy: -0.5 * view!.bounds.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView!.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        assetImageManager.startCachingImages(for: addedAssets, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        assetImageManager.stopCachingImages(for: removedAssets, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
    
    fileprivate func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY, width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY, width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY, width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY, width: new.width, height: new.minY - old.minY)]
            }
            return(added, removed)
        } else {
            return ([new], [old])
        }
    }
}

// MARK: - PHPhotoLibraryChangeObserver
extension AssetGridViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: fetchResult) else { return }
        
        // Change notificatios may be made on a background queue. Re-dispatch to the main queue before 
        // acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Hang on the new fetch results. 
            fetchResult = changes.fetchResultAfterChanges
            if changes.hasIncrementalChanges {
                // If we have incremental diffs, animate them in the collection view.
                guard let collectionView = self.collectionView else { fatalError() }
                collectionView.performBatchUpdates({
                    // For indexes to make sense, updates must in this order:
                    // delete, insert, reload, move
                    if let removed = changes.removedIndexes, removed.count > 0 {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let inserted = changes.insertedIndexes, inserted.count > 0 {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: 0) }))
                    }
                    if let changed = changes.changedIndexes, changed.count > 0 {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: 0) }))
                    }
                    changes.enumerateMoves({ (fromIndex, toIndex) in
                        collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0),
                                                to: IndexPath(item: toIndex, section: 0))
                    })
                }, completion: nil)
            } else {
                // Reload the collection view if incremental diffs are not available
                collectionView!.reloadData()
            }
            resetCachedAssets()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension AssetGridViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfColums = 4
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let spacing = flowLayout.minimumInteritemSpacing * CGFloat(numberOfColums - 1)
        let availableWidth = collectionView.bounds.width - (flowLayout.sectionInset.left + flowLayout.sectionInset.right + spacing)
        let cellWidth = ceil(availableWidth / CGFloat(numberOfColums))
        return CGSize(width: cellWidth, height: cellWidth)
    }
}
