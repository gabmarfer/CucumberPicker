//
//  UIStoryboard+Cucumber.swift
//  CucumberPicker
//
//  Created by gabmarfer on 27/01/2017.
//  Copyright © 2017 Kenoca Software. All rights reserved.
//

import Foundation
import UIKit

extension UIStoryboard {
    
    enum StoryboardIdentifiers: String {
        case cucumberPicker = "CucumberPicker"
    }
    
    class func cucumberPickerStoryboard() -> UIStoryboard {
        return UIStoryboard(name: StoryboardIdentifiers.cucumberPicker.rawValue, bundle: Bundle.main)
    }
}
