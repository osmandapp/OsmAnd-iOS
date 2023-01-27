//
//  CoreResourcesFromBundleProvider.cpp
//  OsmAnd
//
//  Created by Alexey Pelykh on 12/8/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#include "CoreResourcesFromBundleProvider.h"

#include <QStringList>
#include <QFile>

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

#import "OALog.h"

CoreResourcesFromBundleProvider::CoreResourcesFromBundleProvider()
{
}

CoreResourcesFromBundleProvider::~CoreResourcesFromBundleProvider()
{
}

QByteArray CoreResourcesFromBundleProvider::getResource(const QString& name,
                                                        const float displayDensityFactor,
                                                        bool* ok /* = nullptr*/) const
{
    NSString* resourcePath = getResourcePath(name, displayDensityFactor);

    if (!resourcePath)
    {
        if (ok)
            *ok = false;
        return QByteArray();
    }

    NSData* resourceData = [NSData dataWithContentsOfFile:resourcePath];
    if (!resourceData)
    {
        OALog(@"Failed to load resource content from '%@'", resourcePath);

        if (ok)
            *ok = false;
        return QByteArray();
    }

    if (ok)
        *ok = true;
    return QByteArray::fromNSData(resourceData);
}

QByteArray CoreResourcesFromBundleProvider::getResource(const QString& name,
                                                        bool* ok /* = nullptr*/) const
{
    NSString* resourcePath = getResourcePath(name);

    if (!resourcePath)
    {
        if (ok)
            *ok = false;
        return QByteArray();
    }

    NSData* resourceData = [NSData dataWithContentsOfFile:resourcePath];
    if (!resourceData)
    {
        OALog(@"Failed to load resource content from '%@'", resourcePath);

        if (ok)
            *ok = false;
        return QByteArray();
    }

    if (ok)
        *ok = true;
    return QByteArray::fromNSData(resourceData);
}

bool CoreResourcesFromBundleProvider::containsResource(const QString& name,
                                                       const float displayDensityFactor) const
{
    NSString* resourcePath = getResourcePath(name, displayDensityFactor);

    return ([[NSFileManager defaultManager] fileExistsAtPath:resourcePath] == YES);
}

bool CoreResourcesFromBundleProvider::containsResource(const QString& name) const
{
    NSString* resourcePath = getResourcePath(name);

    return ([[NSFileManager defaultManager] fileExistsAtPath:resourcePath] == YES);
}

NSString* CoreResourcesFromBundleProvider::getResourcePath(const QString& name)
{
    NSString* resourceName = nil;
    NSString* resourceType = nil;
    NSString* resourceDir = nil;

    if (name == QLatin1String("map/styles/default.render.xml"))
    {
        resourceName = @"default.render";
        resourceType = @"xml";
        resourceDir = nil;
    }
    else if (name == QLatin1String("map/presets/default.map_styles_presets.xml"))
    {
        resourceName = @"default.map_styles_presets";
        resourceType = @"xml";
        resourceDir = nil;
    }
    else if (name == QLatin1String("misc/icu4c/icu-data-l.dat"))
    {
        resourceName = @"icudt52l";
        resourceType = @"dat";
        resourceDir = nil;
    }
    else if (name == QLatin1String("routing/routing.xml"))
    {
        resourceName = @"routing";
        resourceType = @"xml";
        resourceDir = nil;
    }
    else if (name.startsWith(QLatin1String("map/stubs/")))
    {
        auto stubFilename = name;
        stubFilename = stubFilename.replace(QLatin1String("map/stubs/"), QLatin1String(""));
        const auto lastDotIndex = stubFilename.lastIndexOf(QLatin1Char('.'));

        resourceName = stubFilename.mid(0, lastDotIndex).toNSString();
        resourceType = stubFilename.mid(lastDotIndex + 1).toNSString();
        resourceDir = @"stubs";
    }
    else if (name.startsWith(QLatin1String("map/fonts/")))
    {
        auto fontFilename = name;
        fontFilename = fontFilename.replace(QLatin1String("map/fonts/"), QLatin1String(""));

        QString fontSubpath;
        const auto lastSlashIndex = fontFilename.lastIndexOf(QLatin1Char('/'));
        if (lastSlashIndex >= 0)
        {
            fontSubpath = fontFilename.mid(0, lastSlashIndex);
            fontFilename = fontFilename.mid(lastSlashIndex + 1);
        }

        const auto lastDotIndex = fontFilename.lastIndexOf(QLatin1Char('.'));

        resourceName = fontFilename.mid(0, lastDotIndex).toNSString();
        resourceType = fontFilename.mid(lastDotIndex + 1).toNSString();
        resourceDir = @"fonts";
        if (!fontSubpath.isEmpty())
            resourceDir = [[resourceDir stringByAppendingString:@"/"] stringByAppendingString:fontSubpath.toNSString()];
    }
    else if (name.startsWith(QLatin1String("misc/")))
    {
        auto resourceFileName = name;
        resourceFileName = resourceFileName.replace(QLatin1String("misc/"), QLatin1String(""));
        const auto lastDotIndex = resourceFileName.lastIndexOf(QLatin1Char('.'));
        
        resourceName = resourceFileName.mid(0, lastDotIndex).toNSString();
        resourceType = resourceFileName.mid(lastDotIndex + 1).toNSString();
        
        resourceDir = @"";
    }
    else if (name == QLatin1String("misc/proj/proj.db"))
    {
        resourceName = @"proj";
        resourceType = @"db";
        resourceDir = nil;
    }
    else
    {
        OALog(@"Unrecognized resource name '%@'", name.toNSString());
        return nil;
    }

    NSString* resourcePath = [[NSBundle mainBundle] pathForResource:resourceName
                                                             ofType:resourceType
                                                        inDirectory:resourceDir];
    if (!resourcePath)
    {
        OALog(@"Failed to locate '%@', but it have to be present", name.toNSString());
        return nil;
    }

    return resourcePath;
}

NSString* CoreResourcesFromBundleProvider::getResourcePath(const QString& name,
                                                           const float displayDensityFactor)
{
    NSString* resourceName = nil;
    NSString* resourceType = nil;
    NSString* resourceDir = nil;

    if (name.startsWith(QLatin1String("map/shields/")))
    {
        auto resourceFileName = name;
        resourceFileName = resourceFileName.replace(QLatin1String("map/shields/"), QLatin1String("h_"));
        const auto lastDotIndex = resourceFileName.lastIndexOf(QLatin1Char('.'));

        resourceName = resourceFileName.mid(0, lastDotIndex).toNSString();
        resourceType = resourceFileName.mid(lastDotIndex + 1).toNSString();
        resourceDir = @"map-shaders-png";
        if (displayDensityFactor >= 3.0f)
            resourceDir = [resourceDir stringByAppendingString:@"/drawable-xxhdpi"];
        else if (displayDensityFactor >= 2.0f)
            resourceDir = [resourceDir stringByAppendingString:@"/drawable-xhdpi"];
        else if (displayDensityFactor >= 1.5f)
            resourceDir = [resourceDir stringByAppendingString:@"/drawable-hdpi"];
        else // if (displayDensityFactor >= 1.0f)
            resourceDir = [resourceDir stringByAppendingString:@"/drawable-mdpi"];
    }
    else if (name.startsWith(QLatin1String("map/shaders/")))
    {
        auto resourceFileName = name;
        resourceFileName = resourceFileName.replace(QLatin1String("map/shaders/"), QLatin1String("h_"));
        const auto lastDotIndex = resourceFileName.lastIndexOf(QLatin1Char('.'));

        resourceName = resourceFileName.mid(0, lastDotIndex).toNSString();
        resourceType = resourceFileName.mid(lastDotIndex + 1).toNSString();
        resourceDir = @"map-shaders-png";
        if (displayDensityFactor >= 3.0f)
            resourceDir = [resourceDir stringByAppendingString:@"/drawable-xxhdpi"];
        else if (displayDensityFactor >= 2.0f)
            resourceDir = [resourceDir stringByAppendingString:@"/drawable-xhdpi"];
        else if (displayDensityFactor >= 1.5f)
            resourceDir = [resourceDir stringByAppendingString:@"/drawable-hdpi"];
        else // if (displayDensityFactor >= 1.0f)
            resourceDir = [resourceDir stringByAppendingString:@"/drawable-mdpi"];
    }
    else if (name.startsWith(QLatin1String("map/icons/")))
    {
        auto resourceFileName = name;
        resourceFileName = resourceFileName.replace(QLatin1String("map/icons/"), QLatin1String("mm_"));
        const auto lastDotIndex = resourceFileName.lastIndexOf(QLatin1Char('.'));

        resourceName = resourceFileName.mid(0, lastDotIndex).toNSString();
        resourceType = resourceFileName.mid(lastDotIndex + 1).toNSString();
        resourceDir = @"map-icons-png";
        if (displayDensityFactor >= 3.0f)
            resourceDir = [resourceDir stringByAppendingString:@"/drawable-xxhdpi"];
        else if (displayDensityFactor >= 2.0f)
            resourceDir = [resourceDir stringByAppendingString:@"/drawable-xhdpi"];
        else if (displayDensityFactor >= 1.5f)
            resourceDir = [resourceDir stringByAppendingString:@"/drawable-hdpi"];
        else // if (displayDensityFactor >= 1.0f)
            resourceDir = [resourceDir stringByAppendingString:@"/drawable-mdpi"];
    }
    else if (name.startsWith(QLatin1String("map/stubs/")))
    {
        auto resourceFileName = name;
        resourceFileName = resourceFileName.replace(QLatin1String("map/stubs/"), QLatin1String(""));
        const auto lastDotIndex = resourceFileName.lastIndexOf(QLatin1Char('.'));
        
        resourceName = resourceFileName.mid(0, lastDotIndex).toNSString();
        resourceType = resourceFileName.mid(lastDotIndex + 1).toNSString();
        if (displayDensityFactor >= 3.0f)
            resourceDir = @"stubs/[ddf=3.0]";
        else if (displayDensityFactor >= 2.0f)
            resourceDir = @"stubs/[ddf=2.0]";
        else if (displayDensityFactor >= 1.5f)
            resourceDir = @"stubs/[ddf=1.5]";
        else if (displayDensityFactor >= 1.0f)
            resourceDir = @"stubs/[ddf=1.0]";
        else
            resourceDir = @"stubs";
    }
    else if (name.startsWith(QLatin1String("misc/")))
    {
        auto resourceFileName = name;
        resourceFileName = resourceFileName.replace(QLatin1String("misc/"), QLatin1String(""));
        const auto lastDotIndex = resourceFileName.lastIndexOf(QLatin1Char('.'));
        
        resourceName = resourceFileName.mid(0, lastDotIndex).toNSString();
        resourceType = resourceFileName.mid(lastDotIndex + 1).toNSString();

        resourceDir = @"";
    }
    else
    {
        OALog(@"Unrecognized resource name '%@'", name.toNSString());
        return nil;
    }

    NSString* resourcePath = [[NSBundle mainBundle] pathForResource:resourceName
                                                             ofType:resourceType
                                                        inDirectory:resourceDir];
    if (!resourcePath)
    {
        OALog(@"Failed to locate '%@', but it have to be present", name.toNSString());
        return nil;
    }

    return resourcePath;
}
