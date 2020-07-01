//
//  HelperFunctions.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 5/27/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import Foundation
import UIKit
import FirebaseFirestore

//MARK: Global Functions
private let dateFormat = "yyyyMMddHHmmss"

func dateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    
    dateFormatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
    
    dateFormatter.dateFormat = dateFormat
    
    return dateFormatter
}

func imageFromInitials(firstName: String?, lastName: String?, withBlock: @escaping (_ image: UIImage) -> Void) {
    
    var string: String!
    var size = 36
    
    if firstName != nil && lastName != nil {
        string = String(firstName!.first!).uppercased() + String(lastName!.first!).uppercased()
    } else {
        string = String(firstName!.first!).uppercased()
        size = 72
    }
    
    let lblNameInitialize = UILabel()
    lblNameInitialize.frame.size = CGSize(width: 100, height: 100)
    lblNameInitialize.textColor = .white
    lblNameInitialize.font = UIFont(name: lblNameInitialize.font.fontName, size: CGFloat(size))
    lblNameInitialize.text = string
    lblNameInitialize.textAlignment = NSTextAlignment.center
    lblNameInitialize.backgroundColor = UIColor.lightGray
    lblNameInitialize.layer.cornerRadius = 25
    
    UIGraphicsBeginImageContext(lblNameInitialize.frame.size)
    lblNameInitialize.layer.render(in: UIGraphicsGetCurrentContext()!)
    
    let img = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    
    // return the img
    withBlock(img!)
    
}

func imageFromData(pictureData: String, withBlock: (_ image: UIImage?) -> Void) {
    var image: UIImage?
    
    let decodedData = NSData(base64Encoded: pictureData, options: NSData.Base64DecodingOptions(rawValue: 0))
    
    image = UIImage(data: decodedData! as Data)
    
    withBlock(image)
    
}





//MARK: For Calls and Chats: get message data from Firebase and return MSGs
// param: array of DocumentSnapshot
// return the array as a Dictionary
func dictionaryFromSnapshots(snapshots: [DocumentSnapshot]) -> [NSDictionary] {
    
    var allMessages: [NSDictionary] = []
    
    // loop through all snapshots in Documents in Firebase
    for snapMsg in snapshots {
        // append the msgs to the empty NSDictionary
        allMessages.append(snapMsg.data() as! NSDictionary)
    }
    
    return allMessages
}



//MARK: Format Date Function

func timeElapsed(date: Date) -> String {
    // count how many seconds has passed since previous date
    let seconds = NSDate().timeIntervalSince(date)
    
    var elapsed: String?
    
    // check how long ago the message was
    if (seconds < 60) {                     // if less than 60 SECONDs
        // within passed 60 seconds..
        elapsed = "Just now"
    } else if (seconds < 60 * 60) {         // if 1 or more MINUTEs
        let minutes = Int(seconds / 60)
        
        var minText = "min"
        if minutes > 1 {
            minText = "mins"
        }
        elapsed = "\(minutes) \(minText)"
    } else if (seconds < 24 * 60 * 60) {    // if Under 24 hours
        let hours = Int(seconds / (60 * 60))
        var hoursText = "hour"
        if hours > 1 {
            hoursText = "hours"
        }
        elapsed = "\(hours) \(hoursText)"
    } else {                                  // else Format by day
        let currentDateFormatter = dateFormatter()
        currentDateFormatter.dateFormat = "dd/MM/YYYY"
        
        elapsed = "\(currentDateFormatter.string(from: date))"
    }
    return elapsed!
}




//MARK: for avatars
func dataImageFromString(pictureString: String, withBlock: (_ image: Data?) -> Void) {
    let imageData = NSData(base64Encoded: pictureString, options: NSData.Base64DecodingOptions(rawValue: 0))
    
    withBlock(imageData as? Data)
}





// Mark: UIImageExtension
/**
  take img and turn it round
 then change the size
 */
extension UIImage {
    
    var isPortrait: Bool    { return size.height > size.width }
    var isLandscape: Bool     { return size.width > size.height }
    var breadth: CGFloat { return min(size.width, size.height) }
    var breadthSize: CGSize { return CGSize(width: breadth, height: breadth) }
    var breadthRect: CGRect { return CGRect(origin: .zero, size: breadthSize) }
    
    var circleMasked: UIImage? {
        UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        guard let cgImage = cgImage?.cropping(to: CGRect(origin: CGPoint(x: isLandscape ? floor((size.width - size.height) / 2) : 0, y: isPortrait ? floor((size.height - size.width)/2) : 0), size: breadthSize)) else { return nil }
        UIBezierPath(ovalIn: breadthRect).addClip()
        UIImage(cgImage: cgImage).draw(in: breadthRect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    
    func scaleImageToSize(newSize: CGSize) -> UIImage {
        var scaledImageRect = CGRect.zero
        
        let aspectWidth = newSize.width/size.width
        let aspectheight = newSize.height/size.height
        
        let aspectRatio = max(aspectWidth, aspectheight)
        
        scaledImageRect.size.width = size.width * aspectRatio
        scaledImageRect.size.height = size.height * aspectRatio
        scaledImageRect.origin.x    = (newSize.width - scaledImageRect.size.width) / 2.0
        scaledImageRect.origin.y = (newSize.height - scaledImageRect.size.height) / 2.0
        
        UIGraphicsBeginImageContext(newSize)
        draw(in: scaledImageRect)
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
}
