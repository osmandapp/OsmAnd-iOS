//
//  ExternalResourcesProvider.cpp
//  OsmAnd
//
//  Created by Alexey Pelykh on 12/8/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#include "ExternalResourcesProvider.h"

#include <QStringList>
#include <QFile>

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

ExternalResourcesProvider::ExternalResourcesProvider(const bool useHD_)
    : useHD(useHD_)
{
}

ExternalResourcesProvider::~ExternalResourcesProvider()
{
}

QByteArray ExternalResourcesProvider::getResource(const QString& name, bool* ok /*= nullptr*/) const
{
    if(!useHD)
    {
        if(ok)
            *ok = false;
        return QByteArray();
    }
    
    auto resourceFileName = name;
    resourceFileName = resourceFileName.replace(QLatin1String("map/shaders/"), QLatin1String("h_"));
    resourceFileName = resourceFileName.replace(QLatin1String("map/map_icons/"), QLatin1String("mm_"));
    resourceFileName = resourceFileName.replace(QLatin1String("map/shields/"), QLatin1String("h_"));
    const auto fileNameParts = resourceFileName.split('.');
    const auto resourcePath = [[NSBundle mainBundle]
                               pathForResource:[NSString stringWithUTF8String:fileNameParts[0].toUtf8().constData()]
                               ofType:[NSString stringWithUTF8String:fileNameParts[1].toUtf8().constData()]
                               inDirectory:@"Embedded/HD"];
    if(resourcePath == nil)
    {
        if(ok)
            *ok = false;
        return QByteArray();
    }
    
    QFile resourceFile(QString::fromUtf8([resourcePath UTF8String]));
    if(!resourceFile.exists())
    {
        if(ok)
            *ok = false;
        return QByteArray();
    }
    if(!resourceFile.open(QIODevice::ReadOnly))
    {
        if(ok)
            *ok = false;
        return QByteArray();
    }
    
    const auto data = resourceFile.readAll();
    resourceFile.close();

    if(ok)
        *ok = true;
    return data;
}

bool ExternalResourcesProvider::containsResource(const QString& name) const
{
    if(!useHD)
        return false;
    
    auto resourceFileName = name;
    resourceFileName = resourceFileName.replace(QLatin1String("map/shaders/"), QLatin1String("h_"));
    resourceFileName = resourceFileName.replace(QLatin1String("map/map_icons/"), QLatin1String("mm_"));
    resourceFileName = resourceFileName.replace(QLatin1String("map/shields/"), QLatin1String("h_"));
    const auto fileNameParts = resourceFileName.split('.');
    const auto resourcePath = [[NSBundle mainBundle]
                               pathForResource:[NSString stringWithUTF8String:fileNameParts[0].toUtf8().constData()]
                               ofType:[NSString stringWithUTF8String:fileNameParts[1].toUtf8().constData()]
                               inDirectory:@"Embedded/HD"];
    
    return (resourcePath != nil);
}
