//
//  Camara.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/16/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import Foundation
import UIKit // for camara
import MobileCoreServices // for camara


class Camara {
    
    
    
    
    
    var delegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate
    
    
    
    // initialize camara class
    init(delegate_: UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
        delegate = delegate_
    }
    
    
    
    
    
    
    func PresentPhotoLibrary(target: UIViewController, canEdit: Bool) {
        
        
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) &&
            !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.savedPhotosAlbum) {
            return
        }
        
        
        
        
        let type = kUTTypeImage as String
        let imagePicker = UIImagePickerController()
        
        
        // indicates whether device supports image...
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {   // check if we have a photo library
            imagePicker.sourceType = .photoLibrary  // if yes, set source type to photoLibrary
            
            // returns array of available media types (eg photos)
            // cehk available types
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary){
                // check if available type contains our type : which is an "image" type
                if (availableTypes as NSArray).contains(type) {
                    /* Set up defaults */
                    imagePicker.mediaTypes = [type]     // save array of photo
                    imagePicker.allowsEditing = canEdit // user can edit after taking picture
                }
            }
        } else if (UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum)) {
            // set the source type to our "saved album"
            imagePicker.sourceType = .savedPhotosAlbum
            
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .savedPhotosAlbum) {
               // if there is saved album we set for photo
                if (availableTypes as NSArray).contains(type) {
                    imagePicker.mediaTypes = [type]
                }
            }
        } else {
            return
        }
        
        
        imagePicker.allowsEditing = canEdit
        imagePicker.delegate = delegate     // allows us to present
        target.present(imagePicker, animated: true, completion: nil) // PRESENTS the imagePicker to the user
        return
    }
    
    
    
    
    
    
    
    func PresentMultyCamara(target: UIViewController, canEdit: Bool) {
        let builtInCamara = UIImagePickerController.SourceType.camera
        if !UIImagePickerController.isSourceTypeAvailable(builtInCamara) {
            return
        }
        
        let type1 = kUTTypeImage as String
        let type2 = kUTTypeImage as String
        
        let imagePicker = UIImagePickerController()
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
                if (availableTypes as NSArray).contains(type1) {
                    imagePicker.mediaTypes = [type1, type2]
                    //imagePicker.sourceType = UIImagePickerController.SourceType.camera
                    imagePicker.sourceType = builtInCamara
                }
            }
            
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.rear
            }
            else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.front
            }
        } else {
            // show *Alert, no camera available
            return
        }
        
        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true  // show camera controlls
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil) // presents the imagePicker to the User
        
    }
    
    
    
    
    
    func PresentPhotoCamera(target: UIViewController, canEdit: Bool) {
        
        
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            return
        }
        
        let type1 = kUTTypeImage as String
        let imagePicker = UIImagePickerController()
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
                
                
                if (availableTypes as NSArray).contains(type1) {
                    
                    imagePicker.mediaTypes = [type1]
                    imagePicker.sourceType = UIImagePickerController.SourceType.camera
                }
            }
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.rear
            }
            else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.front
            }
        } else {
            // show alert that NO CAMERA
            return
        }
        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil)
        
    }
        
        
        
    
    
    // MARK: Video Camera
    func PresentVideoCamera(target: UIViewController,  canEdit: Bool) {
        
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            return
        }
        
        let type1 = kUTTypeMovie as String
        
        let imagePicker = UIImagePickerController()
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
                
                if (availableTypes as NSArray).contains(type1) {
                    
                    imagePicker.mediaTypes = [type1]
                    imagePicker.sourceType = UIImagePickerController.SourceType.camera
                    imagePicker.videoMaximumDuration = kMAXDURATION
                }
            }
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.rear
            }
            else if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = UIImagePickerController.CameraDevice.front
            }
        } else {
            //show alert, no camera available
            return
        }
        
        imagePicker.allowsEditing = canEdit
        imagePicker.showsCameraControls = true
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil) // presents the imagepicker to the user
    }
    
    //video library
    func PresentVideoLibrary(target: UIViewController, canEdit: Bool) {
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) && !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.savedPhotosAlbum) {
            return
        }
        
        let type = kUTTypeMovie as String
        let imagePicker = UIImagePickerController()
        
        imagePicker.videoMaximumDuration = kMAXDURATION
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            
            imagePicker.sourceType = .photoLibrary
            
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
                
                if (availableTypes as NSArray).contains(type) {
                    
                    /* Set up defaults */
                    imagePicker.mediaTypes = [type]
                    imagePicker.allowsEditing = canEdit
                }
            }
        } else if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            imagePicker.sourceType = .savedPhotosAlbum
            
            if let availableTypes = UIImagePickerController.availableMediaTypes(for: .savedPhotosAlbum) {
                
                if (availableTypes as NSArray).contains(type) {
                    imagePicker.mediaTypes = [type]
                }
            }
        } else {
            return
        }
        
        imagePicker.allowsEditing = canEdit
        imagePicker.delegate = delegate
        target.present(imagePicker, animated: true, completion: nil) // presents the imagepicker to the user
        
        return
    }
    
    
}

        
        
  
