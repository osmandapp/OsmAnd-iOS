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
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "OAMapUtils.h"

#include <QString>
#include <SkCGUtils.h>
#include <SkCanvas.h>
#include <OsmAndCore/SkiaUtilities.h>
#include <openingHoursParser.h>

@implementation UIColor (nsColorNative)

- (OsmAnd::FColorRGB) toFColorRGB
{
    CGFloat red, green, blue, alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return OsmAnd::FColorRGB(red, green, blue);
}

- (OsmAnd::FColorARGB) toFColorARGB
{
    CGFloat red, green, blue, alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return OsmAnd::FColorARGB(alpha, red, green, blue);
}

- (OsmAnd::ColorRGB) toColorRGB
{
    CGFloat red, green, blue, alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return OsmAnd::ColorRGB(red * 255, green * 255, blue * 255);
}

- (OsmAnd::ColorARGB) toColorARGB
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

+ (NSString *)getScaledResourceName:(NSString *)resourceName
{
    NSString *resourcePath = nil;
    CGFloat scale = [UIScreen mainScreen].scale;
    if (scale > 2.0f)
        resourcePath = [[NSBundle mainBundle] pathForResource:[resourceName stringByAppendingString:@"@3x"] ofType:@"png"];
    else if (scale > 1.0f)
        resourcePath = [[NSBundle mainBundle] pathForResource:[resourceName stringByAppendingString:@"@2x"] ofType:@"png"];
    else
        resourcePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"png"];

    if (resourcePath == nil)
        resourcePath = [[NSBundle mainBundle] pathForResource:[resourceName stringByAppendingString:@"@2x"] ofType:@"png"];
    if (resourcePath == nil)
        resourcePath = [[NSBundle mainBundle] pathForResource:[resourceName stringByAppendingString:@"@3x"] ofType:@"png"];

    return resourcePath;
}

+ (sk_sp<SkImage>)skImageFromPngResource:(NSString *)resourceName
{
    NSString *resourcePath = [self getScaledResourceName:resourceName];
    if (resourcePath == nil)
        return nullptr;

    sk_sp<SkImage> img = [self.class skImageFromResourcePath:resourcePath];
    if (img && UIScreen.mainScreen.scale == 1.0)
        img = [self getScaledSkImage:img scaleFactor:0.5f];
    
    return img;
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

+ (float)getAltitudeForPixelPoint:(OsmAnd::PointI)screenPoint
{
    if (screenPoint != OsmAnd::PointI())
    {
        OAMapRendererView *mapRenderer = OARootViewController.instance.mapPanel.mapViewController.mapView;
        OsmAnd::PointI elevatedPoint = OsmAnd::PointI();
        if ([mapRenderer getLocationFromElevatedPoint:screenPoint location31:&elevatedPoint])
            return [self getAltitudeForElevatedPoint:elevatedPoint];
    }
    return kMinAltitudeValue;
}

+ (float)getAltitudeForElevatedPoint:(OsmAnd::PointI)elevatedPoint
{
    return [OARootViewController.instance.mapPanel.mapViewController.mapView getLocationHeightInMeters:elevatedPoint];
}

+ (OsmAnd::PointI)get31FromElevatedPixel:(OsmAnd::PointI)screenPoint
{
    if (screenPoint != OsmAnd::PointI())
    {
        OAMapRendererView *mapRenderer = OARootViewController.instance.mapPanel.mapViewController.mapView;
        OsmAnd::PointI elevatedPoint = OsmAnd::PointI();
        if ([mapRenderer getLocationFromElevatedPoint:screenPoint location31:&elevatedPoint])
            return elevatedPoint;
    }
    return OsmAnd::PointI();
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
    int y31 = OsmAnd::Utilities::get31TileNumberY(lat);
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

+ (OsmAnd::LatLon) getLanlonFromPoint31:(OsmAnd::PointI)point31
{
    double lat = OsmAnd::Utilities::get31LatitudeY(point31.y);
    double lon = OsmAnd::Utilities::get31LongitudeX(point31.x);
    return OsmAnd::LatLon(lat, lon);
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

+ (OsmAnd::PointI) getPoint31From:(CGPoint)screenPoint
{
    OsmAnd::PointI point31;
    [OARootViewController.instance.mapPanel.mapViewController.mapView convert:screenPoint toLocation:&point31];
    return point31;
}

+ (BOOL)isSegmentCrossingPolygon:(OsmAnd::PointI)start31
                           end31:(OsmAnd::PointI)end31
                       polygon31:(QList<OsmAnd::PointI>)polygon31
{
    if (polygon31.size() < 2)
        return NO;

    for (int i = 1; i < polygon31.size(); i++)
    {
        const OsmAnd::PointI polygonLineStart31 = polygon31.at(i - 1);
        const OsmAnd::PointI polygonLineEnd31 = polygon31.at(i);
        if ([self areSegmentsCrossingFrom:polygonLineStart31 to:polygonLineEnd31 start:start31 end:end31])
        {
            return YES;
        }
    }

    return NO;
}

+ (BOOL)isSegmentCrossingPolygonStart:(OsmAnd::PointI)start31
                                   end:(OsmAnd::PointI)end31
                              polygon31:(const QList<OsmAnd::PointI>&)polygon31
{
    if (polygon31.size() < 2)
        return NO;

    for (int i = 1; i < polygon31.size(); i++)
    {
        const OsmAnd::PointI polygonLineStart31 = polygon31.at(i - 1);
        const OsmAnd::PointI polygonLineEnd31 = polygon31.at(i);
        if ([self areSegmentsCrossingFrom:polygonLineStart31 to:polygonLineEnd31 start:start31 end:end31])
        {
            return YES;
        }
    }

    return NO;
}

+ (BOOL)areSegmentsCrossingFrom:(OsmAnd::PointI)a31 to:(OsmAnd::PointI)b31 start:(OsmAnd::PointI)c31 end:(OsmAnd::PointI)d31
{
    return [self checkSegmentsProjectionsIntersectA:a31.x b:b31.x c:c31.x d:d31.x]
        && [self checkSegmentsProjectionsIntersectA:a31.y b:b31.y c:c31.y d:d31.y]
        && ([self getSignedArea31A:a31 b:b31 c:c31] * [self getSignedArea31A:a31 b:b31 c:d31] <= 0)
        && ([self getSignedArea31A:c31 b:d31 c:a31] * [self getSignedArea31A:c31 b:d31 c:b31] <= 0);
}

+ (BOOL)checkSegmentsProjectionsIntersectA:(int)a b:(int)b c:(int)c d:(int)d
{
    if (a > b)
    {
        int t = a;
        a = b;
        b = t;
    }
    if (c > d)
    {
        int t = c;
        c = d;
        d = t;
    }
    return MAX(a, c) <= MIN(b, d);
}

+ (long)getSignedArea31A:(OsmAnd::PointI)a31 b:(OsmAnd::PointI)b31 c:(OsmAnd::PointI)c31
{
    return (long)(b31.x - a31.x) * (c31.y - a31.y) - (long)(b31.y - a31.y) * (c31.x - a31.x);
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
    OsmAnd::PointI target31 = [self getPoint31FromLatLon:latitude lon:longitude];
    if (applyNewTarget)
        [mapRenderer setTarget31:target31];
    return target31;
}

+ (OsmAnd::PointI)get31FromElevatedPixelX:(float)x y:(float)y
{
    OAMapRendererView *mapRenderer = OARootViewController.instance.mapPanel.mapViewController.mapView;
    if (!mapRenderer)
        return OsmAnd::PointI();
    
    OsmAnd::PointI screenPoint(static_cast<int32_t>(qRound(x)), static_cast<int32_t>(qRound(y)));
    OsmAnd::PointI elevatedPoint = OsmAnd::PointI();
    
    if ([mapRenderer getLocationFromElevatedPoint:screenPoint location31:&elevatedPoint])
        return elevatedPoint;
    
    return OsmAnd::PointI();
}

+ (QList<OsmAnd::PointI>)getPolygon31FromPixelAndRadius:(CGPoint)pixel radius:(float)radius
{
    const float leftPix = pixel.x - radius;
    const float topPix = pixel.y - radius;
    const float rightPix = pixel.x + radius;
    const float bottomPix = pixel.y + radius;

    return [self getPolygon31FromScreenAreaLeft:leftPix top:topPix right:rightPix bottom:bottomPix];
}

+ (QList<OsmAnd::PointI>)getPolygon31FromScreenAreaLeft:(float)leftPix
            top:(float)topPix
          right:(float)rightPix
         bottom:(float)bottomPix
{
    QList<OsmAnd::PointI> polygon31;
    polygon31.reserve(5);

    const OsmAnd::PointI p0 = [self.class get31FromElevatedPixelX:leftPix y:topPix];
    const OsmAnd::PointI p1 = [self.class get31FromElevatedPixelX:rightPix y:topPix];
    const OsmAnd::PointI p2 = [self.class get31FromElevatedPixelX:rightPix y:bottomPix];
    const OsmAnd::PointI p3 = [self.class get31FromElevatedPixelX:leftPix y:bottomPix];

    if (p0 == OsmAnd::PointI() || p1 == OsmAnd::PointI() || p2 == OsmAnd::PointI() || p3 == OsmAnd::PointI())
        return polygon31; // empty indicates failure

    polygon31.append(p0);
    polygon31.append(p1);
    polygon31.append(p2);
    polygon31.append(p3);
    polygon31.append(p0); // close polygon

    return polygon31;
}

+ (int)rayIntersectXWithPrevX:(int)prevX
                        prevY:(int)prevY
                            x:(int)x
                            y:(int)y
                      middleY:(int)middleY {
    
    // Swap points if prev node is below the current node to ensure consistent direction
    if (prevY > y)
    {
        int tx = x;
        int ty = y;
        x = prevX;
        y = prevY;
        prevX = tx;
        prevY = ty;
    }

    // Adjust middleY if it lands exactly on a vertex to avoid edge-case ambiguities
    if (y == middleY || prevY == middleY)
        middleY -= 1;

    // Check if the ray at middleY actually intersects the segment
    if (prevY > middleY || y < middleY)
    {
        return INT_MIN;
    }
    else
    {
        if (y == prevY)
        {
            // Segment is horizontal and on the boundary
            return x;
        }
        
        // Calculate the x-coordinate of the intersection using linear interpolation
        // Formula: x = x1 + (y - y1) * (x2 - x1) / (y2 - y1)
        double rx = (double)x + ((double)middleY - y) * ((double)x - prevX) / ((double)y - prevY);
        
        return (int)rx;
    }
}

+ (BOOL)isPointInsidePolygonLat:(double)lat
                            lon:(double)lon
                      polygon31:(const QList<OsmAnd::PointI>&)polygon
{
    if (polygon.size() < 2)
        return NO;
    
    const int32_t x31 = OsmAnd::Utilities::get31TileNumberX(lon);
    const int32_t y31 = OsmAnd::Utilities::get31TileNumberY(lat);
    OsmAnd::PointI point31(x31, y31);

    int intersections = 0;
    const int px = point31.x;
    const int py = point31.y;

    for (int i = 1; i < polygon.size(); i++)
    {
        const OsmAnd::PointI prev = polygon.at(i - 1);
        const OsmAnd::PointI curr = polygon.at(i);

        int intersectedX = [self rayIntersectXWithPrevX:prev.x prevY:prev.y x:curr.x y:curr.y middleY:py];
        if (intersectedX != INT_MIN && px >= intersectedX) {
            intersections++;
        }
    }

    return (intersections % 2) == 1;
}

@end
