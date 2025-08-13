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
static NSString * const kMapIconsSvgFolderName = @"map-icons-svg";

static NSMutableDictionary<NSString *, NSString *> *resourcesPaths = [NSMutableDictionary dictionary];
static QReadWriteLock resourcesPathsLock;

@implementation OASvgHelper

+ (BOOL)hasMxMapImageNamed:(NSString *)name
{
    return name && ([self mapImageResourcePathNamed:[name hasPrefix:@"mx_"] ? name : [@"mx_" stringByAppendingString:name] resourceDir:kMapIconsSvgFolderName]) != nil;
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
    NSString *resourcePath = [self mapImageResourcePathNamed:[path lastPathComponent] resourceDir:[path stringByDeletingLastPathComponent]];
    if (!resourcePath)
        return nil;

    float scaledSize = kDefaultIconSize * UIScreen.mainScreen.scale;
    return [OANativeUtilities skImageToUIImage:[OANativeUtilities skImageFromSvgResourcePath:resourcePath width:scaledSize height:scaledSize]];
}

+ (nullable NSString *)mapImageResourcePathNamed:(NSString *)resourceName resourceDir:(NSString *)resourceDir
{
    NSString *path;
    {
        QReadLocker scopedLocker(&resourcesPathsLock);

        path = resourcesPaths[resourceName];
        if (path)
            return path.length > 0 ? path : nil;
    }

    path = [[NSBundle mainBundle] pathForResource:resourceName
                                           ofType:@"svg"
                                      inDirectory:resourceDir];
    {
        QWriteLocker scopedLocker(&resourcesPathsLock);

        resourcesPaths[resourceName] = path ? path : @"";
    }
    return path;
}

+ (nullable UIImage *)mapImageFromSvgResource:(NSString *)resourceName width:(float)width height:(float)height
{
    NSString *resourcePath = [self mapImageResourcePathNamed:resourceName resourceDir:kMapIconsSvgFolderName];
    if (!resourcePath)
        return nil;

    return [OANativeUtilities skImageToUIImage:[OANativeUtilities skImageFromSvgResourcePath:resourcePath width:width height:height]];
}

+ (nullable UIImage *)mapImageFromSvgResource:(NSString *)resourceName scale:(float)scale
{
    NSString *resourcePath = [self mapImageResourcePathNamed:resourceName resourceDir:kMapIconsSvgFolderName];
    if (!resourcePath)
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
