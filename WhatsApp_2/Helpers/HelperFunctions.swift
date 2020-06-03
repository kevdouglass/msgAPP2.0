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
