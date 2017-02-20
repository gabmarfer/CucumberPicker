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
    
    var imageURLs = Array<URL>()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.allowsSelection = true
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

}

extension EditViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: EditAssetViewCell.self),
                                                            for: indexPath) as? EditAssetViewCell else { fatalError() }
        
        let fileURL = imageURLs[indexPath.item]
        // TODO: Generate thumbnail
        cell.imageView.image = UIImage(contentsOfFile: fileURL.path)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! EditAssetViewCell
        imageView.image = cell.imageView.image
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
