//
//  Downloader.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/17/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import Foundation
import FirebaseStorage
import Firebase
import MBProgressHUD    // loading bar for image
import AVFoundation

let storage = Storage.storage()     // access where we save our data in FireBase


//image

func uploadImage(image: UIImage, chatRoomId: String, view: UIView, completion: @escaping (_ imageLink: String?) -> Void) {
    // imageLink is optional -> is place we store our image
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    
        progressHUD.mode = .determinateHorizontalBar            // horizontal Loading bar
    
    let dateString = dateFormatter().string(from: Date())       // date string
    
    // PictureMessages is main folder to be saved
    let photoFileName = "PictureMessages/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + "/" + ".jpg"
    
    // in firebase look under "Storage" folder
    // set security rules to "allow read, write: if request.auth != null;"
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(photoFileName) // photoFileName is our path
    
    // access img and create JPG
    let imageData = image.jpegData(compressionQuality: 0.7) // 70% of real image
    
    
    //create *task to upload file
    var task: StorageUploadTask!
    //task = storageRef.putData(imageData, metadata: nil, completion: )
    task = storageRef.putData(imageData!, metadata: nil, completion: { (metaData, error) in
        
        // metaData is the link
        task.removeAllObservers()   // stop listening to any changes in storage directory
        progressHUD.hide(animated: true)
        
        if error != nil {
            print("Error uploading image \(error?.localizedDescription)")
            return
        }
        
        // if everything went ok, Get URL
        storageRef.downloadURL(completion: { (url, error) in
            //check if any download UrL
            guard let downloadURL = url else {
                completion(nil)
                
                return
            }
            completion(downloadURL.absoluteString) // absolute string is path of our file
        })
    })
    
    // % of what has completed (10 mb = 10% )
    task.observe(StorageTaskStatus.progress) { (snapshot) in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }
    
}

// TO BE USED IN "INCOMINGMESSAGES.swift" file to create a message
func downloadImage(imageUrl: String, completion: @escaping(_ image: UIImage?) -> Void) {
    let imageURL = NSURL(string: imageUrl)
    print(imageUrl)
    let imageFileName = (imageUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first! // split our image URL by the "%" sign
    print("file name \(imageFileName)")
    
    // save image locally so it doeasnt have to be downloaded everytime
    if fileExistAtPathOfDocumentsDirectory(path: imageFileName) {
        // it exists -> we return it
        if let contentsOfFile = UIImage(contentsOfFile: fileInDocumentsDirectory(filename: imageFileName)) {
            completion(contentsOfFile) // return completen if file exists in LOCAL directory
        } else {
            print("DEBUG: couldnt generate image")
            completion(nil)
        }
        
    } else {
        // file path does NOT exist -> so we DOWNLOAD it
        let downloadQueue = DispatchQueue(label: "imageDownloadQueue")
        downloadQueue.async {
            // get data from the URL
            let data = NSData(contentsOf: imageURL! as URL)
            
            if data != nil {
                // we did get something
                // create an image from it
                var docURL = getDocumentsURL()
                docURL = docURL.appendingPathComponent(imageFileName, isDirectory: false)
                data!.write(to: docURL, atomically: true) // if already same file with same file, it will make a temp file then delete the file
                
                let imageToReturn = UIImage(data: data! as Data)
                
                DispatchQueue.main.async {
                    completion(imageToReturn)
                }
                
                
            } else {
                // was empty
                DispatchQueue.main.async {
                    print("DEBUG: no image in database")
                    completion(nil)
                }
            }
        }
        
    }
}



// VIDEO
//MARK: upload video from Firebase
func uploadVideo(video: NSData, chatRoomId: String, view: UIView,
                 completion: @escaping(_ videoLink: String?) -> Void) {
    // show a load/progress bar for when you upload a video
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    progressHUD.mode = .determinateHorizontalBar
    
    //SET date for video file/ directory
    let dateString = dateFormatter().string(from: Date())
    
    /* make a video file. directory name for Firebase */
    let videoFileName = "VideoMessages/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + ".mov"
    /* access Firebase storage reference for <Video File name> */
    let storageRef = storage.reference(forURL: kFILEREFERENCE).child(videoFileName)

    //create task
    var task: StorageUploadTask!
    task = storageRef.putData(video as Data, metadata: nil, completion: { (metadata, error) in
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        if error != nil {
            // we have an error
            print("DEBUG: error couldnt upload video in Downloader.swift. (1) \(error!.localizedDescription)")
        }
        /* if there are no errors get the download URL with completion.. */
        storageRef.downloadURL(completion: { (url, error) in
            
            // check if there is a download URL
            guard let downloadUrl = url else {
                completion(nil)
                return
            }
            completion(downloadUrl.absoluteString)
        })
    })
    /* show our percetage of load progress */
        task.observe(StorageTaskStatus.progress) { (snapshot) in
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.totalUnitCount)!)
    }
}






// TO BE USED IN "INCOMINGMESSAGES.swift" file to create a VIDEO message
func downloadVideo(videoUrl: String, completion: @escaping(_ isReadyToPlay: Bool, _ videoFileName: String) -> Void) {
    
    
    let videoURL = NSURL(string: videoUrl)
    print("DEBUG: the video URL is \(videoURL)")
    let VideoFileName = (videoUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first! // split our image URL by the "%" sign
    print("DEBUG: file name \(VideoFileName)")
    
    
    // check if file exists
    /// save image locally so it doeasnt have to be downloaded everytime
    if fileExistAtPathOfDocumentsDirectory(path: VideoFileName) {
        // it exists -> it is ready to play
        completion(true, VideoFileName)
        
    } else {
        
        // file path does NOT exist
        ///-> so we DOWNLOAD it
        let downloadQueue = DispatchQueue(label: "videoDownloadQueue")
        downloadQueue.async {
            // get data from the URL
            let data = NSData(contentsOf: videoURL! as URL)
            
            if data != nil {
                
                // we did get something
                // create an image from it
                var docURL = getDocumentsURL()
                docURL = docURL.appendingPathComponent(VideoFileName , isDirectory: false) /// not a folder -> is a file
                data!.write(to: docURL, atomically: true) // if already same file with same file, it will make a temp file then delete the file
                
                
                
                
                let imageToReturn = UIImage(data: data! as Data)

                DispatchQueue.main.async {
                    completion(true, VideoFileName)
                }
            } else {
                
                // data was empty
                DispatchQueue.main.async {
                    print("DEBUG: no video in database")
                    ///completion(nil)
                }
            }
        }
        
    }
}






//MARK: AUDIO FILEs
func uploadAudio(audioPath: String, chatRoomId: String, view: UIView, completion: @escaping(_ audioLink: String?) -> Void) {
    
    
    let progressHUD = MBProgressHUD.showAdded(to: view, animated: true)
    progressHUD.mode = .determinateHorizontalBar            /// LOAD progress in horizontal bar
    
    let dateString = dateFormatter().string(from: Date())
    
    let audioFileName = "AudioMessages/" + FUser.currentId() + "/" + chatRoomId + "/" + dateString + ".m4a"
    
    let audio = NSData(contentsOfFile: audioPath)
    
    
    let storageRefAudio = storage.reference(forURL: kFILEREFERENCE).child(audioFileName)
    
    var task: StorageUploadTask!
    
    task = storageRefAudio.putData(audio! as Data, metadata: nil, completion: { (metadata, error) in
        
        task.removeAllObservers()
        progressHUD.hide(animated: true)
        
        if error != nil {
            print("DEBUG: error couldnt upload AUDIO file at >> \(error!.localizedDescription)")
            return
        }
        
        storageRefAudio.downloadURL(completion: { (url, error) in
            
            guard let downloadUrl = url else {
                completion(nil)
                return
            }

            completion(downloadUrl.absoluteString)
        })
        
    })
    
    task.observe(StorageTaskStatus.progress) { (snapshot) in
        /// show % of audio download to user
        progressHUD.progress = Float((snapshot.progress?.completedUnitCount)!) / Float((snapshot.progress?.completedUnitCount)!)
    }
}




//MARK: Download Audio messages
// TO BE USED IN "INCOMINGMESSAGES.swift" file to create a message (DOWNLOADING AUDIO)
func downloadAudio(audioUrl: String, completion: @escaping(_ audioFileName: String) -> Void) {
    let audioURL = NSURL(string: audioUrl)
    print(audioUrl)
    let audioFileName = (audioUrl.components(separatedBy: "%").last!).components(separatedBy: "?").first! // split our image URL by the "%" sign
    print("DEBUG: file name for Audio -> \(audioFileName)")
    
    // save image locally so it doeasnt have to be downloaded everytime
    if fileExistAtPathOfDocumentsDirectory(path: audioFileName) {
        // it exists
            completion(audioFileName) // -> we return it
    } else {
        // file path does NOT exist ...
        // -> so we DOWNLOAD it
        let downloadQueue = DispatchQueue(label: "audioDownloadQueue")
        downloadQueue.async {
            // get data from the URL
            let data = NSData(contentsOf: audioURL! as URL)
            
            if data != nil {
                // we did get something
                // create an image from it
                var docURL = getDocumentsURL()
                docURL = docURL.appendingPathComponent(audioFileName, isDirectory: false)
                data!.write(to: docURL, atomically: true) // if already same file with same file, it will make a temp file then delete the file
                
                ///let audioToReturn = UIImage(data: data! as Data)
                
                DispatchQueue.main.async {
                    completion(audioFileName)
                }
            } else {
                // was empty
                DispatchQueue.main.async {
                    print("DEBUG: no Audio saved in database")
                    //completion(nil)
                }
            }
        }
        
    }
}











//MARK: Helpers for DOWNLOAD IMAGE



///VIDEO thumbnail is a url link in Firebase we will pass this
func videoThumbnail(video: NSURL) -> UIImage {
    
    let asset = AVURLAsset(url: video as URL, options: nil)
    
    let imageGenerator = AVAssetImageGenerator(asset: asset)  /// object which provides video and image "previews" for thumbnail
    imageGenerator.appliesPreferredTrackTransform = true
    
    let time = CMTimeMakeWithSeconds(0.5, preferredTimescale: 1000)
    var actualTime = CMTime.zero
    
    var image: CGImage? // bitmap image
    
    do {
        image = try (imageGenerator.copyCGImage(at: time, actualTime: &actualTime))
    } catch let error as NSError {
        print("Debug: error generating thumbnail in Downloader.swift.\(error.localizedDescription)")
    }
    
    // once image is ready we pass the generated "preview" image
   let thumbnail = UIImage(cgImage: image!)
    //let thumbnail = UIImage.init(cgImage: image!)
    
    return thumbnail
}










func fileInDocumentsDirectory(filename: String) -> String {
    
    let fileURL = getDocumentsURL().appendingPathComponent(filename)
    return fileURL.path
    
}


func getDocumentsURL() -> URL {
    
    let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
    
    return documentURL!
    
}




///Check if file (photo) exists in directory

func fileExistAtPathOfDocumentsDirectory(path: String) -> Bool {
    var doesExist = false
    let filePath = fileInDocumentsDirectory(filename: path)
    
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: filePath) {
        doesExist = true // the document exist
    } else {
        doesExist = false
    }

    return doesExist

}
