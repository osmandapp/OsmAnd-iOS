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
    
    static func imageDataToBase64String(_ imageData: Data) -> String {
        return imageData.base64EncodedString()
    }
    
    static func base64StringToImage(_ base64String: String) -> UIImage? {
        if let imageData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) {
            return UIImage(data: imageData)
        }
        return nil
    }
    
    static func htmlImgSrcTagContent(_ base64String: String) -> String {
        return "data:image/png;base64, " + base64String
    }
}
