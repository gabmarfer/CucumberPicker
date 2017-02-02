//
//  AlbumsViewController.swift
//  CucumberPicker
//
//  Created by gabmarfer on 27/01/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import UIKit
import Photos

class AlbumsViewController: UITableViewController {
    
    // MARK: Types for managing sections, cell and segue identifiers
    enum Section: Int {
        case allPhotos = 0
        case smartAlbums
        case userCollections
        
        static let count = 3
    }
    
    enum SegueIdentifier: String {
        case showAllPhotos
        case showCollection
    }
    
    // MARK: Properties
    var selectedAssets = [PHAsset]()

    fileprivate var allPhotos: PHFetchResult<PHAsset>!
    fileprivate var smartAlbums: PHFetchResult<PHAssetCollection>!
    fileprivate var userCollections: PHFetchResult<PHAssetCollection>!
    fileprivate var sectionLocalizedTitles = ["", NSLocalizedString("Smart Albums", comment: ""), NSLocalizedString("Albums", comment: "")]
    
    fileprivate var filteredSmartAlbums = Array<PHAssetCollection>()
    fileprivate var filteredUserCollections = Array<PHAssetCollection>()
    
    fileprivate var onlyImagesOption: PHFetchOptions {
        let onlyImagesOption = PHFetchOptions()
        onlyImagesOption.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        onlyImagesOption.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        return onlyImagesOption
    }
    
    // MARK: ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()

        loadAssets()
        
        PHPhotoLibrary.shared().register(self)
        
        goToAllPhotos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.clearsSelectionOnViewWillAppear = true
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Setup UI
    func setupUI() {
        self.title = NSLocalizedString("Albums", comment: "")
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        self.navigationItem.rightBarButtonItem = doneButton
    }
    
    // MARK: - Actions
    func done(_ sender: AnyObject) {
        let userInfo = [CucumberManager.CucumberNotificationObject.selectedAssets.rawValue: selectedAssets]
        NotificationCenter.default.post(name: CucumberManager.CucumberNotification.didFinishPickingAssets.name,
                                        object: nil,
                                        userInfo: userInfo)
    }
    
    // MARK: - Supplementary methods
    func goToAllPhotos() {
        let viewControllerIdentifier = String(describing: AssetGridViewController.self)
        let assetGridViewController = storyboard?.instantiateViewController(withIdentifier: viewControllerIdentifier) as! AssetGridViewController
        assetGridViewController.delegate = self
        assetGridViewController.fetchResult = allPhotos
        assetGridViewController.title = NSLocalizedString("All Photos", comment: "")
        navigationController?.pushViewController(assetGridViewController, animated: false)
    }
    
    // MARK: - Process Albums
    func loadAssets(){
        loadAllPhotos()
        loadSmartAlbums()
        loadUserCollections()
    }
    
    func loadAllPhotos() {
        allPhotos = PHAsset.fetchAssets(with: self.onlyImagesOption)
    }
    
    func loadSmartAlbums() {
        // Clean filtered collections.
        filteredSmartAlbums.removeAll()
        
        // Get fetch result.
        let smartAlbumOptions = PHFetchOptions()
        smartAlbumOptions.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]
        
        // Filter to retrieve only smart albums with images.
        let allSmartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: smartAlbumOptions)
        allSmartAlbums.enumerateObjects(using: { [weak self] (obj, idx, stop) in
            guard let strongSelf = self else {
                return
            }
            
            let assets = PHAsset.fetchAssets(in: obj, options: strongSelf.onlyImagesOption)
            if assets.count > 0 {
                strongSelf.filteredSmartAlbums.append(obj)
            }
        })
    }
    
    func loadUserCollections() {
        // Clean filtered collections.
        filteredUserCollections.removeAll()

        // Get fetch result.
        let userCollectionOptions = PHFetchOptions()
        userCollectionOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
        userCollectionOptions.sortDescriptors = [NSSortDescriptor(key: "localizedTitle", ascending: true)]

        // Filter to retrieve only user collections with images
        let allUserCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: userCollectionOptions)
        allUserCollections.enumerateObjects(using: { [weak self] (obj, idx, stop) in
            guard let strongSelf = self else {
                return
            }
            let assets = PHAsset.fetchAssets(in: obj, options: strongSelf.onlyImagesOption)
            if assets.count > 0 {
                strongSelf.filteredUserCollections.append(obj)
            }
        })
        
    }
    
    func configure(_ cell: AlbumViewCell, with assetCollection: PHAssetCollection) {
        cell.nameLabel!.text = assetCollection.localizedTitle
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let assets = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
        cell.countLabel!.text = String(assets.count)
        
        let scale = UIScreen.main.scale
        let thumbnailSize = CGSize(width: cell.coverImageView!.bounds.width * scale, height: cell.coverImageView!.bounds.height * scale)
        PHImageManager.default().requestImage(for: assets.lastObject!, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { (image, _) in
            cell.coverImageView!.image = image
        })
    }

    // MARK: - Table view

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .allPhotos: return 1
        case .smartAlbums: return filteredSmartAlbums.count
        case .userCollections: return filteredUserCollections.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = String(describing: AlbumViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! AlbumViewCell

        switch Section(rawValue: indexPath.section)! {
            
        case .allPhotos:
            cell.nameLabel!.text = NSLocalizedString("All Photos", comment: "")
            cell.countLabel!.text = String(allPhotos.count)
            
            let scale = UIScreen.main.scale
            let thumbnailSize = CGSize(width: cell.coverImageView!.bounds.width * scale, height: cell.coverImageView!.bounds.height * scale)
            PHImageManager.default().requestImage(for: allPhotos.lastObject!, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { (image, _) in
                cell.coverImageView!.image = image
            })
            
        case .smartAlbums:
            let smartAlbum = filteredSmartAlbums[indexPath.row]
            configure(cell, with: smartAlbum)
            
        case .userCollections:
            let userCollection = filteredUserCollections[indexPath.row]
            configure(cell, with: userCollection)
            
        }
        
        return cell

    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionLocalizedTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if indexPath.section == Section.allPhotos.rawValue {
            self.performSegue(withIdentifier: SegueIdentifier.showAllPhotos.rawValue, sender: cell)
        } else {
            self.performSegue(withIdentifier: SegueIdentifier.showCollection.rawValue, sender: cell)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        guard let destination = segue.destination as? AssetGridViewController
            else { fatalError("Unexpected view controller for segue") }
        
        guard let cell = sender as? AlbumViewCell else {
            return
        }
        
        destination.delegate = self
        destination.title = cell.nameLabel?.text
        
        switch SegueIdentifier(rawValue: segue.identifier!)! {
            case .showAllPhotos:
                destination.fetchResult = allPhotos
            
        case .showCollection:
            
            // Get the asset collection for the selected row
            let indexPath = tableView.indexPath(for: cell)!
            let collection: PHCollection
            switch Section(rawValue: indexPath.section)! {
                case .smartAlbums:
                    collection = filteredSmartAlbums[indexPath.row]
                case .userCollections:
                    collection = filteredUserCollections[indexPath.row]
                default: return // not reached; all photos section already handled by other segue
            }
            
            // Configure the view controller with the asset collection
            guard let assetCollection = collection as? PHAssetCollection
                else { fatalError("expected asset collection") }
            destination.fetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
        }
        
        destination.selectedAssets = selectedAssets
    }

}

// MARK: PHPhotoLibraryChangeObserver
extension AlbumsViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Change notifications may be made on a background queue. Re-dispatch to the main queue
        // before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Check of the three top-level fetches for changes.
            if let changeDetails = changeInstance.changeDetails(for: allPhotos) {
                // Update the cached fetch result.
                allPhotos = changeDetails.fetchResultAfterChanges
                // (The table row for this one doesn't need updating, it always say "All Photos".)
            }
            
            // Update the cached fetch results, and reload the table sections to match.
            if let changeDetails = changeInstance.changeDetails(for: smartAlbums) {
                smartAlbums = changeDetails.fetchResultAfterChanges
                tableView.reloadSections(IndexSet(integer: Section.smartAlbums.rawValue), with: .automatic)
            }
            
            if let changeDetails = changeInstance.changeDetails(for: userCollections) {
                userCollections = changeDetails.fetchResultAfterChanges
                tableView.reloadSections(IndexSet(integer: Section.userCollections.rawValue), with: .automatic)
            }
        }
    }
}

// MARK: AssetGridViewControllerDelegate
extension AlbumsViewController: AssetGridViewControllerDelegate {
    func assetGridViewController(_ assetGridViewController: AssetGridViewController, didSelectAssets assets: [PHAsset]) {
        assetGridViewController.delegate =  nil
        selectedAssets = assets
    }
}
