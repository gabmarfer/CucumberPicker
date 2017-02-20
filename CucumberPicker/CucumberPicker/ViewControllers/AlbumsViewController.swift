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
    
    var selectedAssets = [PHAsset]()
    
    fileprivate enum Section: Int {
        case allPhotos = 0
        case smartAlbums
        case userCollections
        
        static let count = 3
    }
    
    fileprivate enum SegueIdentifier: String {
        case showAllPhotos
        case showCollection
    }
    
    fileprivate var sectionLocalizedTitles = ["", NSLocalizedString("Smart Albums", comment: ""), NSLocalizedString("Albums", comment: "")]
    
    fileprivate let assetManager = AssetManager()
    
    // MARK: ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        NotificationCenter.default.addObserver(forName: AssetManager.AssetManagerNotification.didUpdateSmartAlbums.name,
                                               object: nil, queue: OperationQueue.main) { [weak self] (notification) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.tableView.reloadSections(IndexSet(integer: Section.smartAlbums.rawValue), with: .automatic)
        }
        
        NotificationCenter.default.addObserver(forName: AssetManager.AssetManagerNotification.didUpdateUserAlbums.name,
                                               object: nil,
                                               queue: OperationQueue.main) { [weak self] (notification) in
                                                guard let strongSelf = self else { return }
                                                strongSelf.tableView.reloadSections(IndexSet(integer: Section.userCollections.rawValue), with: .automatic)
        }

        goToAllPhotos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.clearsSelectionOnViewWillAppear = true
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
        assetGridViewController.fetchResult = assetManager.allPhotos
        assetGridViewController.title = NSLocalizedString("All Photos", comment: "")
        navigationController?.pushViewController(assetGridViewController, animated: false)
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
        case .smartAlbums: return assetManager.filteredSmartAlbums.count
        case .userCollections: return assetManager.filteredUserAlbums.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = String(describing: AlbumViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! AlbumViewCell

        switch Section(rawValue: indexPath.section)! {
            
        case .allPhotos:
            cell.nameLabel!.text = NSLocalizedString("All Photos", comment: "")
            cell.countLabel!.text = String(assetManager.allPhotos.count)
            
            let scale = UIScreen.main.scale
            let thumbnailSize = CGSize(width: cell.coverImageView!.bounds.width * scale, height: cell.coverImageView!.bounds.height * scale)
            PHImageManager.default().requestImage(for: assetManager.allPhotos.lastObject!, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { (image, _) in
                cell.coverImageView!.image = image
            })
            
        case .smartAlbums:
            let smartAlbum = assetManager.filteredSmartAlbums[indexPath.row]
            configure(cell, with: smartAlbum)
            
        case .userCollections:
            let userCollection = assetManager.filteredUserAlbums[indexPath.row]
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
                destination.fetchResult = assetManager.allPhotos
            
        case .showCollection:
            
            // Get the asset collection for the selected row
            let indexPath = tableView.indexPath(for: cell)!
            let collection: PHCollection
            switch Section(rawValue: indexPath.section)! {
                case .smartAlbums:
                    collection = assetManager.filteredSmartAlbums[indexPath.row]
                case .userCollections:
                    collection = assetManager.filteredUserAlbums[indexPath.row]
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

// MARK: AssetGridViewControllerDelegate
extension AlbumsViewController: AssetGridViewControllerDelegate {
    func assetGridViewController(_ assetGridViewController: AssetGridViewController, didSelectAssets assets: [PHAsset]) {
        assetGridViewController.delegate =  nil
        selectedAssets = assets
    }
}
