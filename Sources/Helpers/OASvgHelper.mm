//
//  OASvgHelper.m
//  OsmAnd Maps
//
//  Created by Alexey K on 12.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OASvgHelper.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/SkiaUtilities.h>
#include <QReadWriteLock>

const static float kDefaultIconSize = 24.0f;

static NSMutableDictionary<NSString *, NSString *> *resourcesExistCache = [NSMutableDictionary dictionary];
static NSMutableArray<NSString *> *resourcesNotExistCache = [NSMutableArray array];
static QReadWriteLock iconsCacheLock;

@implementation OASvgHelper

+ (BOOL)hasMXSvgMapImageBy:(NSString *)name
{
    return name && ([self mapImagePathFromSvgResource:[name hasPrefix:@"mx_"] ? name : [@"mx_" stringByAppendingString:name]]) != nil;
}

+ (nullable UIImage *) mapImageNamed:(NSString *)name
{
    CGFloat scaleFactor = [[UIScreen mainScreen] scale];
    float scaledSize = kDefaultIconSize * scaleFactor;
    return [self.class mapImageFromSvgResource:name width:scaledSize height:scaledSize];
}

+ (nullable UIImage *) mapImageNamed:(NSString *)name scale:(float)scale
{
    CGFloat scaleFactor = [[UIScreen mainScreen] scale];
    float scaledSize = kDefaultIconSize * scaleFactor * scale;
    return [self.class mapImageFromSvgResource:name width:scaledSize height:scaledSize];
}

+ (nullable UIImage *)imageNamed:(NSString *)path
{
    NSString *resourceName = [path lastPathComponent];
    NSString *resourcePath;
    {
        QReadLocker scopedLocker(&iconsCacheLock);
        if ([resourcesNotExistCache containsObject:resourceName])
            return nil;
        resourcePath = resourcesExistCache[resourceName];
    }
    if (!resourcePath)
    {
        resourcePath = [[NSBundle mainBundle] pathForResource:resourceName
                                                       ofType:@"svg"
                                                  inDirectory:[path stringByDeletingLastPathComponent]];
        {
            QWriteLocker scopedLocker(&iconsCacheLock);
            if (!resourcePath)
            {
                [resourcesNotExistCache addObject:resourceName];
                return nil;
            }
            resourcesExistCache[resourceName] = resourcePath;
        }
    }
    float scaledSize = kDefaultIconSize * UIScreen.mainScreen.scale;
    return [OANativeUtilities skImageToUIImage:[OANativeUtilities skImageFromSvgResourcePath:resourcePath width:scaledSize height:scaledSize]];
}

+ (nullable NSString *)mapImagePathFromSvgResource:(NSString *)resourceName
{
    NSString *path;
    {
        QReadLocker scopedLocker(&iconsCacheLock);
        path = resourcesExistCache[resourceName];
        if (path)
            return path;
        else if ([resourcesNotExistCache containsObject:resourceName])
            return nil;
    }

    path = [[NSBundle mainBundle] pathForResource:resourceName
                                           ofType:@"svg"
                                      inDirectory:@"map-icons-svg"];
    {
        QWriteLocker scopedLocker(&iconsCacheLock);
        if (path)
            resourcesExistCache[resourceName] = path;
        else
            [resourcesNotExistCache addObject:resourceName];
    }
    return path;
}

+ (nullable UIImage *)mapImageFromSvgResource:(NSString *)resourceName width:(float)width height:(float)height
{
    NSString *resourcePath = [self mapImagePathFromSvgResource:resourceName];
    if (resourcePath == nil)
        return nil;

    return [OANativeUtilities skImageToUIImage:[OANativeUtilities skImageFromSvgResourcePath:resourcePath width:width height:height]];
}

+ (nullable UIImage *)mapImageFromSvgResource:(NSString *)resourceName scale:(float)scale
{
    NSString *resourcePath = [self mapImagePathFromSvgResource:resourceName];
    if (resourcePath == nil)
        return nil;

    return [OANativeUtilities skImageToUIImage:[OANativeUtilities skImageFromSvgResourcePath:resourcePath scale:scale]];
}

+ (UIImage *) imageFromSvgResourcePath:(NSString *)resourcePath width:(float)width height:(float)height
{
    if (resourcePath == nil)
        return nil;

    NSData* resourceData = [NSData dataWithContentsOfFile:resourcePath];
    if (!resourceData)
        return nil;

    return [OANativeUtilities skImageToUIImage:[OANativeUtilities skImageFromSvgData:resourceData width:width height:height]];
}

+ (UIImage *) imageFromSvgResourcePath:(NSString *)resourcePath scale:(float)scale
{
    if (resourcePath == nil)
        return nil;

    NSData* resourceData = [NSData dataWithContentsOfFile:resourcePath];
    if (!resourceData)
        return nil;

    return [OANativeUtilities skImageToUIImage:[OANativeUtilities skImageFromSvgData:resourceData scale:scale]];
}

+ (UIImage *) imageFromSvgData:(const NSData *)data width:(float)width height:(float)height
{
    return data ? [OANativeUtilities skImageToUIImage:OsmAnd::SkiaUtilities::createImageFromVectorData(QByteArray::fromRawNSData(data), width, height)] : nil;
}

+ (UIImage *) imageFromSvgData:(const NSData *)data scale:(float)scale
{
    return data ? [OANativeUtilities skImageToUIImage:OsmAnd::SkiaUtilities::createImageFromVectorData(QByteArray::fromRawNSData(data), scale)] : nil;
}

@end
