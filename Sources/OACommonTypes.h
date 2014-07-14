//
//  OACommonTypes.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#ifndef OsmAnd_OACommonTypes_h
#define OsmAnd_OACommonTypes_h

#import <Foundation/Foundation.h>

@protocol OsmAndAppProtocol;
@protocol OsmAndAppCppProtocol;
typedef id<OsmAndAppProtocol, OsmAndAppCppProtocol> OsmAndAppInstance;

typedef NS_ENUM(NSInteger, OAMapMode)
{
    OAMapModeUnknown = -1,
    OAMapModeFree,
    OAMapModePositionTrack,
    OAMapModeFollow
};

typedef struct Point31
{
    int32_t x, y;
} Point31;

#endif // !defined(OsmAnd_OACommonTypes_h)
