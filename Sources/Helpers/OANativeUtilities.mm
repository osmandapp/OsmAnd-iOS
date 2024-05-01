//
//  OAUtilities.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 6/5/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OANativeUtilities.h"

#import <UIKit/UIKit.h>
#import "OAColors.h"
#import "OAUtilities.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OAMapUtils.h"

#include <QString>

#include <SkCGUtils.h>
#include <SkCanvas.h>
#include <OsmAndCore/SkiaUtilities.h>
#include <openingHoursParser.h>

@implementation UIColor (nsColorNative)

- (OsmAnd::FColorARGB) toFColorARGB
{
    CGFloat red, green, blue, alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return OsmAnd::ColorARGB(alpha * 255, red * 255, green * 255, blue * 255);
}

@end

@implementation NSDate (nsDateNative)

- (std::tm) toTm
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:self];
    
    struct tm res;
    res.tm_year = (int) components.year - 1900;
    res.tm_mon = (int) components.month - 1;
    res.tm_mday = (int) components.day;
    res.tm_hour = (int) components.hour;
    res.tm_min = (int) components.minute;
    res.tm_sec = (int) components.second;
    std::mktime(&res);
    
    return res;
}

@end

@implementation OANativeUtilities

+ (sk_sp<SkImage>) skImageFromPngResource:(NSString *)resourceName
{
    NSString *resourcePath = nil;
    if ([UIScreen mainScreen].scale > 2.0f)
        resourcePath = [[NSBundle mainBundle] pathForResource:[resourceName stringByAppendingString:@"@3x"] ofType:@"png"];
    else if ([UIScreen mainScreen].scale > 1.0f)
        resourcePath = [[NSBundle mainBundle] pathForResource:[resourceName stringByAppendingString:@"@2x"] ofType:@"png"];
    else
    	resourcePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"png"];

    if (resourcePath == nil)
        resourcePath = [[NSBundle mainBundle] pathForResource:[resourceName stringByAppendingString:@"@2x"] ofType:@"png"];

    if (resourcePath == nil)
        resourcePath = [[NSBundle mainBundle] pathForResource:[resourceName stringByAppendingString:@"@3x"] ofType:@"png"];

    if (resourcePath == nil)
        return nullptr;

    return [self.class skImageFromResourcePath:resourcePath];
}

+ (sk_sp<SkImage>) skImageFromResourcePath:(NSString *)resourcePath
{
    if (resourcePath == nil)
        return nullptr;
    
    NSData* resourceData = [NSData dataWithContentsOfFile:resourcePath];
    if (!resourceData)
        return nullptr;
    
    return [self.class skImageFromNSData:resourceData];
}

+ (sk_sp<SkImage>) skImageFromNSData:(const NSData *)data
{
    if (!data)
        return nullptr;
        
    CFDataRef dataRef = (CFDataRef)CFBridgingRetain(data);
    return SkImage::MakeFromEncoded(SkData::MakeWithProc(
             CFDataGetBytePtr(dataRef),
             CFDataGetLength(dataRef),
             [](const void* ptr, void* context) {
                 CFRelease(context);
             },
             (void *)dataRef
         ));
}

+ (sk_sp<SkImage>) skImageFromSvgResource:(NSString *)resourceName width:(float)width height:(float)height
{
    const auto resourcePath = [[NSBundle mainBundle] pathForResource:resourceName
                                                              ofType:@"svg"
                                                         inDirectory:@"map-icons-svg"];
    if (resourcePath == nil)
        return nullptr;

    return [self.class skImageFromSvgResourcePath:resourcePath width:width height:height];
}

+ (sk_sp<SkImage>) skImageFromSvgResource:(NSString *)resourceName scale:(float)scale
{
    const auto resourcePath = [[NSBundle mainBundle] pathForResource:resourceName
                                                              ofType:@"svg"
                                                         inDirectory:@"map-icons-svg"];
    if (resourcePath == nil)
        return nullptr;

    return [self.class skImageFromSvgResourcePath:resourcePath scale:scale];
}

+ (sk_sp<SkImage>) skImageFromSvgResourcePath:(NSString *)resourcePath width:(float)width height:(float)height
{
    if (!resourcePath)
        return nullptr;

    NSData* resourceData = [NSData dataWithContentsOfFile:resourcePath];
    if (!resourceData)
        return nullptr;

    return [self.class skImageFromSvgData:resourceData width:width height:height];
}

+ (sk_sp<SkImage>) skImageFromSvgResourcePath:(NSString *)resourcePath scale:(float)scale
{
    if (resourcePath == nil)
        return nullptr;

    NSData* resourceData = [NSData dataWithContentsOfFile:resourcePath];
    if (!resourceData)
        return nullptr;

    return [self.class skImageFromSvgData:resourceData scale:scale];
}

+ (sk_sp<SkImage>) skImageFromSvgData:(const NSData *)data width:(float)width height:(float)height
{
    return data ? OsmAnd::SkiaUtilities::createImageFromVectorData(QByteArray::fromRawNSData(data), width, height) : nullptr;
}

+ (sk_sp<SkImage>) skImageFromSvgData:(const NSData *)data scale:(float)scale
{
    return data ? OsmAnd::SkiaUtilities::createImageFromVectorData(QByteArray::fromRawNSData(data), scale) : nullptr;
}

+ (sk_sp<SkImage>) getScaledSkImage:(sk_sp<SkImage>)skImage scaleFactor:(float)scaleFactor
{
    if (!qFuzzyCompare(scaleFactor, 1.0f) && skImage)
        skImage = OsmAnd::SkiaUtilities::scaleImage(skImage, scaleFactor, scaleFactor);
    return skImage;
}

+ (UIImage *) skImageToUIImage:(const sk_sp<const SkImage> &)image
{
    if (!image)
        return nil;
    SkBitmap bmp;
    image->asLegacyBitmap(&bmp);
    CGFloat scaleFactor = [[UIScreen mainScreen] scale];
    CGImageRef img = SkCreateCGImageRef(bmp);
    UIImage *res = img != nil ? [[UIImage alloc] initWithCGImage:img scale:scaleFactor orientation:UIImageOrientationUp] : nil;
    if (img)
        CGImageRelease(img);
    return res;
}

+ (NSArray<NSString *> *) QListOfStringsToNSArray:(const QList<QString> &)list
{
    NSMutableArray<NSString *> *array = [[NSMutableArray alloc] initWithCapacity:list.size()];
    for (const auto& item : list)
        [array addObject:item.toNSString()];

    return [NSArray arrayWithArray:array];
}

+ (Point31) convertFromPointI:(OsmAnd::PointI)input
{
    Point31 output;
    output.x = input.x;
    output.y = input.y;
    return output;
}

+ (OsmAnd::PointI) convertFromPoint31:(Point31)input
{
    OsmAnd::PointI output;
    output.x = input.x;
    output.y = input.y;
    return output;
}

+ (sk_sp<SkImage>) skImageFromCGImage:(CGImageRef)image
{
    return SkMakeImageFromCGImage(image);
}

+ (QHash<QString, QString>) dictionaryToQHash:(NSDictionary<NSString *, NSString*> *)dictionary
{
    QHash<QString, QString> res;
    if (dictionary != nil)
    {
        for (NSString *key in dictionary.allKeys)
            res.insert(QString::fromNSString(key), QString::fromNSString(dictionary[key]));
    }
    return res;
}

+ (QList<OsmAnd::TileId>)convertToQListTileIds:(NSArray<NSArray<NSNumber *> *> *)tileIds
{
    QList<OsmAnd::TileId> qTileIds;
    for (NSArray<NSNumber *> *tileId in tileIds)
    {
        OsmAnd::TileId qTileId = OsmAnd::TileId::fromXY([tileId.firstObject intValue], [tileId.lastObject intValue]);
        qTileIds.append(qTileId);
    }
    return qTileIds;
}

+ (UIColor *)getOpeningHoursColor:(std::vector<std::shared_ptr<OpeningHoursParser::OpeningHours::Info>>)openingHoursInfo
{
    if (!openingHoursInfo.empty())
    {
        bool open = false;
        for (auto info : openingHoursInfo)
        {
            if (info->opened || info->opened24_7)
            {
                open = true;
                break;
            }
        }
        return open ? UIColorFromRGB(color_ctx_menu_amenity_opened_text) : UIColorFromRGB(color_ctx_menu_amenity_closed_text);
    }
    return nil;
}

+ (NSAttributedString *)getOpeningHoursDescr:(std::vector<std::shared_ptr<OpeningHoursParser::OpeningHours::Info>>)openingHoursInfo
{
    if (!openingHoursInfo.empty())
    {
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
        UIColor *colorOpen = UIColorFromRGB(color_ctx_menu_amenity_opened_text);
        UIColor *colorClosed = UIColorFromRGB(color_ctx_menu_amenity_closed_text);
        for (int i = 0; i < openingHoursInfo.size(); i ++)
        {
            auto info = openingHoursInfo[i];

            if (str.length > 0)
                [str appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];

            NSString *time = [NSString stringWithUTF8String:info->getInfo().c_str()];

            NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", time]];
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            BOOL opened = info->fallback && i > 0 ? openingHoursInfo[i - 1]->opened : info->opened;
            attachment.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_travel_time"]
                                                                             color:opened ? colorOpen : colorClosed];
            
            NSAttributedString *strWithImage = [NSAttributedString attributedStringWithAttachment:attachment];
            [s replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:strWithImage];
            [s addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
            [s addAttribute:NSForegroundColorAttributeName value:opened ? colorOpen : colorClosed range:NSMakeRange(0, s.length)];
            [str appendAttributedString:s];
        }
        
        UIFont *font = [UIFont scaledSystemFontOfSize:13.0 weight:UIFontWeightMedium];
        [str addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, str.length)];
        
        return str;
    }
    return nil;
}

+ (CLLocationCoordinate2D)getLatLonFromElevatedPixel:(OsmAnd::PointI)screenPoint
{
    OsmAnd::PointI point31 = [self get31FromElevatedPixel:screenPoint];
    double lat = OsmAnd::Utilities::get31LatitudeY(point31.y);
    double lon = OsmAnd::Utilities::get31LongitudeX(point31.x);
    return CLLocationCoordinate2DMake(lat, lon);
}

+ (OsmAnd::PointI)get31FromElevatedPixel:(OsmAnd::PointI)screenPoint
{
    OsmAnd::PointI elevatedPoint = OsmAnd::PointI();
    if (screenPoint != OsmAnd::PointI())
    {
        OAMapRendererView *mapRenderer = OARootViewController.instance.mapPanel.mapViewController.mapView;
        [mapRenderer getLocationFromElevatedPoint:screenPoint location31:&elevatedPoint];
    }
    return elevatedPoint;
}

+ (OsmAnd::PointF) getPixelFromLatLon:(double)lat lon:(double)lon
{
    CGPoint screenPoint = [self.class getScreenPointFromLatLon:lat lon:lon];
    return OsmAnd::PointF(screenPoint.x, screenPoint.y);
}

+ (CGPoint) getScreenPointFromLatLon:(double)lat lon:(double)lon
{
    OAMapRendererView *mapRenderer = OARootViewController.instance.mapPanel.mapViewController.mapView;
    int x31 = OsmAnd::Utilities::get31TileNumberX(lon);
    int y31 = OsmAnd::Utilities::get31TileNumberX(lat);
    OsmAnd::PointI point31 = OsmAnd::PointI(x31, y31);
    CGPoint screenPoint;
    [mapRenderer obtainScreenPointFromPosition:&point31 toScreen:&screenPoint checkOffScreen:YES];
    return screenPoint;
}

+ (double) getLocationHeightOrZero:(OsmAnd::PointI)location31
{
    OAMapRendererView *mapRenderer = OARootViewController.instance.mapPanel.mapViewController.mapView;
    double height = [mapRenderer getLocationHeightInMeters:location31];
    return height > kMinAltitudeValue ? height : 0;
}

+ (OsmAnd::PointI) getPoint31FromLatLon:(OsmAnd::LatLon)latLon
{
    return [self.class getPoint31FromLatLon:latLon.latitude lon:latLon.longitude];
}

+ (OsmAnd::PointI) getPoint31FromLatLon:(double)lat lon:(double)lon
{
    int32_t x31 = OsmAnd::Utilities::get31TileNumberX(lon);
    int32_t y31 = OsmAnd::Utilities::get31TileNumberY(lat);
    return OsmAnd::PointI(x31, y31);
}

+ (BOOL) containsLatLon:(CLLocation *)location
{
    return [self.class containsLatLon:location.coordinate.latitude lon:location.coordinate.longitude];
}

+ (BOOL) containsLatLon:(double)lat lon:(double)lon
{
    OAMapRendererView *mapRenderer = OARootViewController.instance.mapPanel.mapViewController.mapView;
    return [mapRenderer isPositionVisible:[self.class getPoint31FromLatLon:lat lon:lon]];
}

+ (OsmAnd::PointI) calculateTarget31:(double)latitude longitude:(double)longitude applyNewTarget:(BOOL)applyNewTarget
{
    OAMapRendererView *mapRenderer = OARootViewController.instance.mapPanel.mapViewController.mapView;
    OsmAnd::PointI target31 = [self.class getPoint31FromLatLon:latitude lon:longitude];
    if (applyNewTarget)
        [mapRenderer setTarget31:target31];
    return target31;
}

@end
