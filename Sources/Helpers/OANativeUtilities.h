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

#include <SkImage.h>

#include <OsmAndCore/Color.h>

#include <OsmAndCore/CommonTypes.h>

#include <openingHoursParser.h>

#import <Foundation/Foundation.h>

#import "OACommonTypes.h"

#include <OsmAndCore/LatLon.h>

#define kMinAltitudeValue -20000

@interface UIColor (nsColorNative)

- (OsmAnd::FColorARGB) toFColorARGB;

@end

@interface NSDate (nsDateNative)

- (std::tm) toTm;

@end

@interface OANativeUtilities : NSObject

+ (sk_sp<SkImage>) skImageFromPngResource:(NSString *)resourceName;
+ (sk_sp<SkImage>) skImageFromResourcePath:(NSString *)resourcePath;
+ (sk_sp<SkImage>) skImageFromNSData:(const NSData *)data;

+ (sk_sp<SkImage>) skImageFromSvgResource:(NSString *)resourceName width:(float)width height:(float)height;
+ (sk_sp<SkImage>) skImageFromSvgResourcePath:(NSString *)resourcePath width:(float)width height:(float)height;
+ (sk_sp<SkImage>) skImageFromSvgData:(const NSData *)data width:(float)width height:(float)height;
+ (sk_sp<SkImage>) skImageFromSvgResource:(NSString *)resourceName scale:(float)scale;
+ (sk_sp<SkImage>) skImageFromSvgResourcePath:(NSString *)resourcePath scale:(float)scale;
+ (sk_sp<SkImage>) skImageFromSvgData:(const NSData *)data scale:(float)scale;

+ (sk_sp<SkImage>) getScaledSkImage:(sk_sp<SkImage>)skImage scaleFactor:(float)scaleFactor;

+ (NSArray<NSString *> *) QListOfStringsToNSArray:(const QList<QString> &)list;
+ (Point31) convertFromPointI:(OsmAnd::PointI)input;
+ (OsmAnd::PointI) convertFromPoint31:(Point31)input;
+ (sk_sp<SkImage>) skImageFromCGImage:(CGImageRef) image;
+ (UIImage *) skImageToUIImage:(const sk_sp<const SkImage> &)image;

+ (QHash<QString, QString>) dictionaryToQHash:(NSDictionary<NSString *, NSString*> *)dictionary;

+ (QList<OsmAnd::TileId>)convertToQListTileIds:(NSArray<NSArray<NSNumber *> *> *)tileIds;

+ (UIColor *) getOpeningHoursColor:(std::vector<std::shared_ptr<OpeningHoursParser::OpeningHours::Info>>)openingHoursInfo;
+ (NSAttributedString *) getOpeningHoursDescr:(std::vector<std::shared_ptr<OpeningHoursParser::OpeningHours::Info>>)openingHoursInfo;

+ (float)getAltitudeForPixelPoint:(OsmAnd::PointI)screenPoint;
+ (float)getAltitudeForElevatedPoint:(OsmAnd::PointI)elevatedPoint;
+ (OsmAnd::PointI)get31FromElevatedPixel:(OsmAnd::PointI)screenPoint;
+ (float) getLocationHeightOrZero:(OsmAnd::PointI)location31;
+ (OsmAnd::PointI) getPoint31FromLatLon:(OsmAnd::LatLon)latLon;
+ (OsmAnd::PointI) getPoint31FromLatLon:(double)lat lon:(double)lon;
+ (OsmAnd::PointF) getPixelFromLatLon:(double)lat lon:(double)lon;
+ (CGPoint) getScreenPointFromLatLon:(double)lat lon:(double)lon;
+ (CGPoint) getScreenPointYFromLatLon:(double)lat lon:(double)lon;
+ (OsmAnd::PointI) calculateTarget31:(double)latitude longitude:(double)longitude applyNewTarget:(BOOL)applyNewTarget;

+ (BOOL) containsLatLon:(CLLocation *)location;
+ (BOOL) containsLatLon:(double)lat lon:(double)lon;

@end
