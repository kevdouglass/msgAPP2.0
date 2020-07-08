//
//  Encryption.swift
//  WhatsApp_2
//
/// will have 2 class funcs
/// 1: Encrypt data
/// 2: Decrypt data
//  Created by Kevin Douglass on 7/7/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import Foundation
import RNCryptor

class Encryption {
    
    /// #1 Encrypt Text Data
    class func encryptText(chatRoomID: String, decryptMessage: String) -> String {
        let _data = decryptMessage.data(using: String.Encoding.utf8)
        let encryptedData = RNCryptor.encrypt(data: _data!, withPassword: chatRoomID)
        
        let _options = NSData.Base64EncodingOptions(rawValue: 0)
        
        return encryptedData.base64EncodedString(options: _options)
    }
    
    
    
    /// #2 Decrypting Text Data
    class func decryptText(chatRoomID: String, encryptedMessage: String) -> String {
        let _decryptor = RNCryptor.Decryptor(password: chatRoomID)
        
        let _options = NSData.Base64DecodingOptions(rawValue: 0)
        let encryptedData = NSData(base64Encoded: encryptedMessage, options: _options)
        
        var _message: NSString = ""  /// NSString is just a string from objective C
        
        if (encryptedData != nil) {
            /// use do-catch to try and catch any errors while decrypting
            do {
                let decryptedData = try (_decryptor.decrypt(data: encryptedData! as Data))
                /// turn the message into string of UTF8 character String
                _message = NSString(data: decryptedData, encoding: String.Encoding.utf8.rawValue)!
            } catch {
                print("DEBUG: Error decrupting text \(error.localizedDescription)")
            }
        }
        return _message as String
    }
    
    
}
