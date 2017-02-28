//
//  PushNoAnimationSegue.swift
//  CucumberPicker
//
//  Created by gabmarfer on 28/02/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//
//  Make a pushh without an animation

import UIKit

class PushNoAnimationSegue: UIStoryboardSegue {
    
    override func perform() {
        if let navigationController = source.navigationController {
            navigationController.pushViewController(destination, animated: false)
        }
    }
}
