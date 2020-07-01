//
//  pictureCollectionViewCell.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/30/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit

class pictureCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    func generateCell(image: UIImage) {
        // pass the image and set the new image
        self.imageView.image = image
    }
    
    
    
}
