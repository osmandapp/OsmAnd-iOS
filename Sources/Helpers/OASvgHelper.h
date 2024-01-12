//
//  OASvgHelper.h
//  OsmAnd Maps
//
//  Created by Alexey K on 12.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OASvgHelper : NSObject

+ (UIImage *) imageFromSvgResource:(NSString *)resourceName width:(float)width height:(float)height;
+ (UIImage *) imageFromSvgResourcePath:(NSString *)resourcePath width:(float)width height:(float)height;
+ (UIImage *) imageFromSvgData:(const NSData *)data width:(float)width height:(float)height;
+ (UIImage *) imageFromSvgResource:(NSString *)resourceName scale:(float)scale;
+ (UIImage *) imageFromSvgResourcePath:(NSString *)resourcePath scale:(float)scale;
+ (UIImage *) imageFromSvgData:(const NSData *)data scale:(float)scale;

@end

NS_ASSUME_NONNULL_END
