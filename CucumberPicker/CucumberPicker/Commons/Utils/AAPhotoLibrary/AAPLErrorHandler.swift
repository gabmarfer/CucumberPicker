//
//  AAPLErrorHandler.swift
//  AAPhotoLibrary
//
//  Created by Armen Abrahamyan on 5/7/16.
//  Copyright © 2016 Armen Abrahamyan. All rights reserved.
//

import Foundation

struct AAError {
    let error: NSError
}

enum AAPLErrorHandler: RawRepresentable {
    
    case aaRestricted
    case aaDenied
    case aaDataNotConvertible
    case aaForceAccessDenied
    case aaUnableDeleteCollection
    case aaUnableDeleteAsset
    case aaGeneralError
    
    typealias RawValue = AAError
    var rawValue: RawValue {
        switch self {
            case .aaRestricted:
                return AAError(error: NSError(domain: "com.aaphotolibrary", code: -771, userInfo: ["error": "Impossible to access the Photo Library, please make sure that you don't expilicitly deneid access or there is no specific parenthal control enabled !"]))
            case .aaDenied:
                return AAError(error: NSError(domain: "com.aaphotolibrary", code: -772, userInfo: ["error": "Access is manually restricted by User."]))
            case .aaForceAccessDenied:
                return AAError(error: NSError(domain: "com.aaphotolibrary", code: -773, userInfo: ["error": "Failed to force authorize an access to photo library. Check parenthal controls."]))
            case .aaDataNotConvertible:
                return AAError(error: NSError(domain: "com.aaphotolibrary", code: -774, userInfo: ["error": "Problem converting NSData into UIImage, please make sure that data is not corrupted."]))
            case .aaUnableDeleteCollection:
                return AAError(error: NSError(domain: "com.aaphotolibrary", code: -775, userInfo: ["error": "Unable to delete collection. Found collection is nil"]))
            case .aaUnableDeleteAsset:
                return AAError(error: NSError(domain: "com.aaphotolibrary", code: -776, userInfo: ["error": "Unable to delete an asset. No assets found"]))
            case .aaGeneralError:
                return AAError(error: NSError(domain: "com.aaphotolibrary", code: -777, userInfo: ["error": "Unknown problem occures"]))
            
        }
    }
    
    init?(rawValue: RawValue) {
        switch rawValue.error.code {
            case -771: self = .aaRestricted
            case -772: self = .aaDenied
            case -773: self = .aaForceAccessDenied
            case -774: self = .aaDataNotConvertible
            case -775: self = .aaUnableDeleteCollection
            case -776: self = .aaUnableDeleteAsset
            
            default: self = .aaGeneralError
        }
    }
    
}
