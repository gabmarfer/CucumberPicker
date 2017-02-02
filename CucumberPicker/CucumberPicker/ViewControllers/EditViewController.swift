//
//  EditViewController.swift
//  CucumberPicker
//
//  Created by gabmarfer on 01/02/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import UIKit
import Photos

protocol editViewControllerDelegate {
    func editViewControllerDidCancel(_ editViewController: EditViewController)
    func editViewController(_ editViewController: EditViewController, didDoneWithItemsAt urls: [URL])
}

class EditViewController: UIViewController {
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate var selectedAssets = [PHAsset]()
    fileprivate let imageManager = PHImageManager()
    fileprivate var thumbnailSize: CGSize!
    fileprivate var selectedImageSize: CGSize!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.allowsSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Determine the size of the thumbnails to request from the PHCachingImageManager
        let scale = UIScreen.main.scale
        let cellSize = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        selectedImageSize = CGSize(width: imageView.bounds.width * scale, height: imageView.bounds.height * scale)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Actions
    @IBAction func cancelEditing(_ sender: Any) {
    }


    @IBAction func doneEditing(_ sender: Any) {
    }
    
    func addImage(_ sender: Any) {
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension EditViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: EditAssetViewCell.self),
                                                            for: indexPath) as? EditAssetViewCell else { fatalError() }
        
        let asset = selectedAssets[indexPath.item]
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil) { (image, _) in
            cell.imageView.image = image
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = selectedAssets[indexPath.item]
        imageManager.requestImage(for: asset, targetSize: selectedImageSize, contentMode: .aspectFit, options: nil) {
            [weak self] (image, _) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.imageView.image = image
        }
    }
}

extension EditViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                         withReuseIdentifier: String(describing: EditAssetReusableView.self),
                                                                         for: indexPath) as? EditAssetReusableView else { fatalError() }
        
        footerView.addImageButton.addTarget(self, action: #selector(addImage(_:)), for: .touchUpInside)
        
        return footerView
    }
}
