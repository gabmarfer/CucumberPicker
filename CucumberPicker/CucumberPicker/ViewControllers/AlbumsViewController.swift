//
//  AlbumsViewController.swift
//  CucumberPicker
//
//  Created by gabmarfer on 27/01/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import UIKit
import Photos

class AlbumsViewController: UITableViewController, GalleryPickerProtocol {
    
    weak var galleryDelegate: GalleryPickerDelegate?
    
    var numberOfSelectableAssets: Int {
        return CucumberManager.Custom.maxImages - imageCache.imageURLs.count
    }
    
    var takenPhotos: Int!
    var imageCache: ImageCache!
    
    fileprivate enum Section: Int {
        case allPhotos = 0
        case smartAlbums
        case userCollections
        
        static let count = 3
    }
    
    fileprivate enum SegueIdentifier: String {
        case showAllPhotos
        case showCollection
        case showAllPhotosNoAnimation
    }
    
    fileprivate var sectionLocalizedTitles = ["", NSLocalizedString("Smart Albums", comment: ""), NSLocalizedString("Albums", comment: "")]
    fileprivate let assetHelper = AssetHelper()
    
    // MARK: ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Albums", comment: "")
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:)))
        navigationItem.rightBarButtonItem = doneButton
        
        registerForNotifications()
        
        configureGalleryToolbar()

        performSegue(withIdentifier: SegueIdentifier.showAllPhotosNoAnimation.rawValue, sender: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.clearsSelectionOnViewWillAppear = true
        
        updateGalleryToolbarTitle(selected: imageCache.imageURLs.count, of: CucumberManager.Custom.maxImages)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        unregisterForNotifications()
    }
    
    // MARK: Actions
    
    func done(_ sender: AnyObject) {
        galleryDelegate?.galleryPickerControllerDidFinishPickingAssets(self)
    }
    
    // MARK: Supplementary methods
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

    // MARK: Table view

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .allPhotos: return 1
        case .smartAlbums: return assetHelper.filteredSmartAlbums.count
        case .userCollections: return assetHelper.filteredUserAlbums.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = String(describing: AlbumViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! AlbumViewCell

        switch Section(rawValue: indexPath.section)! {
            
        case .allPhotos:
            cell.nameLabel!.text = NSLocalizedString("All Photos", comment: "")
            cell.countLabel!.text = String(assetHelper.allPhotos.count)
            
            let scale = UIScreen.main.scale
            let thumbnailSize = CGSize(width: cell.coverImageView!.bounds.width * scale, height: cell.coverImageView!.bounds.height * scale)
            PHImageManager.default().requestImage(for: assetHelper.allPhotos.lastObject!, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { (image, _) in
                cell.coverImageView!.image = image
            })
            
        case .smartAlbums:
            let smartAlbum = assetHelper.filteredSmartAlbums[indexPath.row]
            configure(cell, with: smartAlbum)
            
        case .userCollections:
            let userCollection = assetHelper.filteredUserAlbums[indexPath.row]
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

    // MARK: Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        // Assure that we are segue to AssetGridController
        guard let assetGridViewController = segue.destination as? AssetGridViewController else {
                fatalError("Unexpected view controller for segue")
        }
        
        // Configure basic properties of AssetGridController
        assetGridViewController.galleryDelegate = galleryDelegate
        assetGridViewController.imageCache = imageCache

        switch SegueIdentifier(rawValue: segue.identifier!)! {
            case .showAllPhotos, .showAllPhotosNoAnimation:
                assetGridViewController.fetchResult = assetHelper.allPhotos
                assetGridViewController.title = NSLocalizedString("All Photos", comment: "")
            
        case .showCollection:
            
            guard let cell = sender as? AlbumViewCell else {
                return
            }
            
            // Get the asset collection for the selected row
            let indexPath = tableView.indexPath(for: cell)!
            let collection: PHCollection
            switch Section(rawValue: indexPath.section)! {
                case .smartAlbums:
                    collection = assetHelper.filteredSmartAlbums[indexPath.row]
                case .userCollections:
                    collection = assetHelper.filteredUserAlbums[indexPath.row]
                default: return // not reached; all photos section already handled by other segue
            }
            
            // Configure the view controller with the asset collection
            guard let assetCollection = collection as? PHAssetCollection
                else { fatalError("expected asset collection") }
            assetGridViewController.fetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
            assetGridViewController.title = cell.nameLabel?.text
        }
    }
}

// MARK: - AlbumsViewController + Notifications
extension AlbumsViewController {
    func registerForNotifications() {
        NotificationCenter.default.addObserver(forName: AssetHelper.AssetManagerNotification.didUpdateSmartAlbums.name,
                                               object: nil, queue: OperationQueue.main) { [weak self] (notification) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.tableView.reloadSections(IndexSet(integer: Section.smartAlbums.rawValue), with: .automatic)
        }
        
        NotificationCenter.default.addObserver(forName: AssetHelper.AssetManagerNotification.didUpdateUserAlbums.name,
                                               object: nil,
                                               queue: OperationQueue.main) { [weak self] (notification) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.tableView.reloadSections(IndexSet(integer: Section.userCollections.rawValue), with: .automatic)
                                                
        }
    }
    
    func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: AssetHelper.AssetManagerNotification.didUpdateSmartAlbums.name,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: AssetHelper.AssetManagerNotification.didUpdateUserAlbums.name,
                                                  object: nil)
    }
}
