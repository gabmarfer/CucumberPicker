//
//  EditViewController.swift
//  CucumberPicker
//
//  Created by gabmarfer on 01/02/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import UIKit
import Photos

protocol EditViewControllerDelegate: class {
    func editViewControllerDidCancel(_ editViewController: EditViewController)
    func editViewControllerDidFinishEditing(_ editViewController: EditViewController)
    func editViewControllerWillAddNewItem(_ editViewController: EditViewController)
}

class EditViewController: UIViewController {
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var delegate: EditViewControllerDelegate?
    var imageCache: ImageCache!
    
    fileprivate var selectedIndexPath: IndexPath!
    
    // MARK: ViewController lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.allowsSelection = true
        
        // Select firs item.
        selectItemAtIndexPath(IndexPath(item: 0, section: 0))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide delete button if we only have one image
        deleteButton.isHidden = !(imageCache.imageURLs.count > 1)
        
        collectionView.reloadData()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: Actions
    @IBAction func cancelEditing(_ sender: Any) {
        delegate?.editViewControllerDidCancel(self)
    }


    @IBAction func doneEditing(_ sender: Any) {
        delegate?.editViewControllerDidFinishEditing(self)
    }
    
    @IBAction func deleteImage(_ sender: Any) {
        let fileURL = imageCache.imageURLs[selectedIndexPath.item]
        imageCache.removeImage(named: fileURL.lastPathComponent)
        collectionView.deleteItems(at: [selectedIndexPath])
        
        // Select the new first item
        selectItemAtIndexPath(IndexPath(item: 0, section: 0))
        
        // Hide delete button if we only have one image
        deleteButton.isHidden = !(imageCache.imageURLs.count > 1)
    }
    
    func addImage(_ sender: Any) {
        delegate?.editViewControllerWillAddNewItem(self)
    }
    
    // MARK: Supplementary methods
    fileprivate func selectItemAtIndexPath(_ indexPath: IndexPath) {
        if selectedIndexPath != nil && selectedIndexPath.compare(indexPath) != .orderedSame {
            // Deselect old indexPath
            collectionView.deselectItem(at: selectedIndexPath, animated: true)
        }
        
        selectedIndexPath = indexPath
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .left)
        let fileURL = imageCache.imageURLs[indexPath.item]
        imageView.image = UIImage(contentsOfFile: fileURL.path)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension EditViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageCache.imageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: EditAssetViewCell.self),
                                                            for: indexPath) as? EditAssetViewCell else { fatalError() }
        
        let fileURL = imageCache.imageURLs[indexPath.item]
        if let image = UIImage(contentsOfFile: fileURL.path) {
            cell.imageView.image = imageCache.thumbnailImageFromImage(image, of: Int(cell.imageView.bounds.width))
        }
        
        cell.isSelected = indexPath.compare(selectedIndexPath) == .orderedSame
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectItemAtIndexPath(indexPath)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension EditViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                         withReuseIdentifier: String(describing: EditAssetReusableView.self),
                                                                         for: indexPath) as? EditAssetReusableView else { fatalError() }
        
        footerView.addImageButton.addTarget(self, action: #selector(addImage(_:)), for: .touchUpInside)
        
        return footerView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        // Hide add button if we have reached the images limit
        return imageCache.imageURLs.count < CucumberManager.Custom.maxImages ? flowLayout.headerReferenceSize : CGSize.zero
    }
}
