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

+ (BOOL)hasMapImageNamed:(NSString *)name;
+ (nullable UIImage *) mapImageNamed:(NSString *)name;
+ (nullable UIImage *) mapImageNamed:(NSString *)name scale:(float)scale;
+ (nullable UIImage *) imageNamed:(NSString *)path;

+ (nullable UIImage *) mapImageFromSvgResource:(NSString *)resourceName width:(float)width height:(float)height;
+ (nullable UIImage *) mapImageFromSvgResource:(NSString *)resourceName scale:(float)scale;
+ (nullable UIImage *) imageFromSvgResourcePath:(NSString *)resourcePath width:(float)width height:(float)height;
+ (nullable UIImage *) imageFromSvgResourcePath:(NSString *)resourcePath scale:(float)scale;
+ (nullable UIImage *) imageFromSvgData:(const NSData *)data width:(float)width height:(float)height;
+ (nullable UIImage *) imageFromSvgData:(const NSData *)data scale:(float)scale;

@end

NS_ASSUME_NONNULL_END
