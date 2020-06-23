//
//  PhotoMediaItem.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/17/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class PhotMediaItem: JSQPhotoMediaItem {
    
    override func mediaViewDisplaySize() -> CGSize {
        
        // return different CG image size depending if USER wants Portrait or Landscape IMG sent
        
        let defaultSize: CGFloat = 256
        
        var thumbSize: CGSize = CGSize(width: defaultSize, height: defaultSize)
        
        
        if (self.image != nil && self.image.size.height > 0 && self.image.size.width > 0) {
            
            let aspect: CGFloat = self.image.size.width / self.image.size.height
            
            if (self.image.size.width > self.image.size.height) {
                thumbSize = CGSize(width: defaultSize, height: defaultSize / aspect)
            } else {
                thumbSize = CGSize(width: defaultSize * aspect, height: defaultSize)
            }
            
        }
        
        return thumbSize // return CGsize called thumbSize
        
        
    }
    
    
    
    
    
}
