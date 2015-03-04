//
//  OAUtilities.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 6/5/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#include <OsmAndCore/stdlib_common.h>
#include <memory>

#include <OsmAndCore/QtExtensions.h>
#include <QList>

#include <SkBitmap.h>

#include <OsmAndCore/CommonTypes.h>

#import <Foundation/Foundation.h>

#import "OACommonTypes.h"

@interface OANativeUtilities : NSObject

+ (std::shared_ptr<SkBitmap>)skBitmapFromPngResource:(NSString*)resourceName;
+ (NSMutableArray*)QListOfStringsToNSMutableArray:(const QList<QString>&)list;
+ (Point31)convertFromPointI:(OsmAnd::PointI)input;
+ (OsmAnd::PointI)convertFromPoint31:(Point31)input;
+ (UIImage *) skBitmapToUIImage:(const SkBitmap&) skBitmap;

@end
