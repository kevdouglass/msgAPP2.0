//
//  AudioViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/23/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import Foundation
import IQAudioRecorderController

class AudioViewController {
    
    var delegate: IQAudioRecorderViewControllerDelegate
    
    init(delegate_: IQAudioRecorderViewControllerDelegate) {
        delegate = delegate_
    }
    
    func presentAudioRecorder(target: UIViewController) {
        let controller = IQAudioRecorderViewController()
        
        controller.delegate = delegate
        controller.title = "Record"
        controller.maximumRecordDuration = kAUDIOMAXDURATION
        controller.allowCropping = true
        
        target.presentBlurredAudioRecorderViewControllerAnimated(controller) // will represent our "Controller" -> NOW go to chatView controller to send audio message
    }
    
    
    
}
