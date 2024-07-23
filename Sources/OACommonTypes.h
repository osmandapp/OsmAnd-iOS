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
    OAMapModePositionTrack
};

typedef struct Point31
{
    int32_t x, y;
} Point31;

typedef struct {
    CLLocationCoordinate2D center;
    CLLocationCoordinate2D topLeft;
    CLLocationCoordinate2D bottomRight;
} OAGpxBounds;

typedef NS_ENUM(NSInteger, OAQuickSearchType)
{
    REGULAR = 0,
    START_POINT,
    DESTINATION,
    INTERMEDIATE,
    HOME,
    WORK
};

typedef struct {
    double top, bottom, left, right;
} OABBox;

#endif // !defined(OsmAnd_OACommonTypes_h)
