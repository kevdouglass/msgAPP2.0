//
//  CollectionReference.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 5/27/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import Foundation
import FirebaseFirestore

enum FCollectionReference: String {
    
    case User
    case Typing
    case Recent
    case Message
    case Group
    case Call
    
}

func reference(_ collectionReference: FCollectionReference) -> CollectionReference{
    return Firestore.firestore().collection(collectionReference.rawValue)
}
