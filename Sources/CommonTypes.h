//
//  CommonTypes.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#ifndef OsmAnd_CommonTypes_h
#define OsmAnd_CommonTypes_h

#import <Foundation/Foundation.h>

@protocol OsmAndAppProtocol;
@protocol OsmAndAppCppProtocol;
typedef id<OsmAndAppProtocol, OsmAndAppCppProtocol> OsmAndAppInstance;

typedef NS_ENUM(NSInteger, OAMapMode)
{
    OAMapModeFree,
    OAMapModePositionTrack,
    OAMapModeFollow
};

#endif
