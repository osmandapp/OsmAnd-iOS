//
//  OAUtilities.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 6/5/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#include <OsmAndCore/stdlib_common.h>
#include <memory>
#include <ctime>

#include <OsmAndCore/QtExtensions.h>
#include <QList>

#include <SkBitmap.h>

#include <OsmAndCore/CommonTypes.h>

#import <Foundation/Foundation.h>

#import "OACommonTypes.h"

@interface NSDate (nsDateNative)

- (std::tm) toTm;

@end

@interface OANativeUtilities : NSObject

+ (std::shared_ptr<SkBitmap>) skBitmapFromPngResource:(NSString *)resourceName rotatedBy:(double)degrees;
+ (std::shared_ptr<SkBitmap>) skBitmapFromMmPngResource:(NSString *)resourceName;
+ (std::shared_ptr<SkBitmap>) skBitmapFromPngResource:(NSString *)resourceName;
+ (std::shared_ptr<SkBitmap>) skBitmapFromResourcePath:(NSString *)resourcePath;

+ (NSMutableArray*) QListOfStringsToNSMutableArray:(const QList<QString>&)list;
+ (Point31) convertFromPointI:(OsmAnd::PointI)input;
+ (OsmAnd::PointI) convertFromPoint31:(Point31)input;
+ (UIImage *) skBitmapToUIImage:(const SkBitmap&) skBitmap;

@end
