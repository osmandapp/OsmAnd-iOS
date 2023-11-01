//
//  WebImagesCacheHelper.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 27/10/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAImageToStringConverter)
@objcMembers
final class ImageToStringConverter : NSObject {
    
    static func imageToBase64String(_ image: UIImage) -> String {
        if let jpegData = image.jpegData(compressionQuality: 1) {
            return jpegData.base64EncodedString()
        }
        return ""
    }
    
    static func base64StringToImage(_ base64String: String) -> UIImage? {
        if let imageData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) {
            return UIImage(data: imageData)
        }
        return nil
    }
}
