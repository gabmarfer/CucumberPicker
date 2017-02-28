//
//  ViewController.swift
//  CucumberPicker
//
//  Created by gabmarfer on 24/01/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import UIKit

class HomeViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    static let HomeCellIdentifier = "HomeCell"
    
    var images = [UIImage]()
    var cucumberManager: CucumberManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        cucumberManager = CucumberManager(self)
        cucumberManager.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: CollectionView
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeViewController.HomeCellIdentifier, for: indexPath) as! HomeCell
        
        cell.imgView.image = images[indexPath.item]
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let width = collectionView.bounds.width - (flowLayout.sectionInset.left + flowLayout.sectionInset.right)
        return CGSize(width: width, height: width*2/3)
    }
    
    // MARK: Actions
    @IBAction func handleTapCameraButton(_ sender: UIBarButtonItem) {
        cucumberManager.showImagePicker(fromButton: sender)
    }
}

extension HomeViewController: CucumberDelegate {
    func cumberManager(_ manager: CucumberManager, didFinishPickingImages images: [UIImage]) {
        self.images = images
        collectionView?.reloadData()
    }
}
