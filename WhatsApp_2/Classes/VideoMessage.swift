//
//  VideoMessage.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/23/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class VideoMessage: JSQMediaItem {
    
    var image: UIImage?
    var videoImageView: UIImageView?
    var status: Int?
    var fileURL: NSURL?
    
    
    init(withFileURL: NSURL, maskOutgoing: Bool) {
        
        super.init(maskAsOutgoing: maskOutgoing)
        
        fileURL = withFileURL
        videoImageView = nil
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    //MARK: icon is our 'PLAY' icon button on the 'PREVIEW' image made when the user sends a VIDEO message

    override func mediaView() -> UIView! {
        if let stat = status {
            
            if stat == 1 {
                // our video is not ready to be played: is not status of 1
                return nil
            }
            
            if stat == 2 && (self.videoImageView == nil) {
                // if astatus is 2: ready to >> play <<
                let size = self.mediaViewDisplaySize()
                let outgoing = self.appliesMediaViewMaskAsOutgoing /// check if our video msg is 'OUTGOING' or 'INCOMING;
                
                
                /// make white 'PLAY' button -> white color
                // icon is our 'PLAY' icon button on the 'PREVIEW' image made when the user sends a VIDEO message
                let icon = UIImage.jsq_defaultPlay()?.jsq_imageMasked(with: .white)
                let iconView = UIImageView(image: icon) /// put our icon created in our imageView
                
                iconView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height) ///put our 'PLAY' button in corner of screen
                iconView.contentMode = .center
                
                /// set our thumbnail
                let imageView = UIImageView(image: self.image!)
                
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true  /// so it doesnt go outside our imageVIew bounds
                imageView.addSubview(iconView)  /// add our icon on top of our imageVIew *our video 'Preview'*
                
                
                // 2nd pt
                JSQMessagesMediaViewBubbleImageMasker.applyBubbleImageMask(toMediaView: imageView, isOutgoing: outgoing)
                
                
                /// now
                // instantiated our custom image view iwth our play button and set to a video image
                self.videoImageView = imageView
            
            
            }
        }
        return self.videoImageView
    }
    
    
}
