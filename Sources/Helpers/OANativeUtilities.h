//
//  OAUtilities.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 6/5/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#include <memory>

#include <SkBitmap.h>

#import <Foundation/Foundation.h>

@interface OANativeUtilities : NSObject

+ (std::shared_ptr<SkBitmap>)skBitmapFromPngResource:(NSString*)resourceName;

@end
