//
//  PicturesCollectionViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/30/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import IDMPhotoBrowser


//private let reuseIdentifier = "Cell"

class PicturesCollectionViewController: UICollectionViewController {

    ///VARS
    var allImages: [UIImage] = []
    var allImageLinks: [String] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "All Pictures"
        
        if allImageLinks.count > 0 {
            // we have image and
            // we need to > Download it <
            downloadImages()
            
        }
     
    }



    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // # return the number of sections our collection view has
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items in each section
        /// do this by counting number of images in our array of UI images
        return allImages.count
    }

    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! pictureCollectionViewCell
        
        cell.generateCell(image: allImages[indexPath.row])
    
        // Configure the cell
    
        return cell /// will present all our images
    }

    
    
    
    // MARK: UICollectionViewDelegate
    /// every time our user clicks an image in "All Pictures" we want the picture to get bigger and be able to swipe through all the UIimage array elemtents
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let photos = IDMPhoto.photos(withImages: allImages)
        
        // instantiate the browser (idm browser)
        let browser = IDMPhotoBrowser(photos: photos)
        browser?.displayDoneButton = false          /// dont want to see "Done" button
        browser?.setInitialPageIndex(UInt(indexPath.row))       /// set the initial image. method asks for a UInt. allows to swipe thru all images
        
        // present our browser
        self.present(browser!, animated: true, completion: nil)
        
    }
   
    
    //MARK: Download Images
    func downloadImages() {
        // for every image, download image link
        for imageLink in allImageLinks {
            downloadImage(imageUrl: imageLink) { (image) in
                
                if image != nil {
                    self.allImages.append(image!)
                    
                    self.collectionView.reloadData()
                }
            }
        }
    }

}
