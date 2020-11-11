//
//  OAGpxData.h
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
// OsmAnd/src/net/osmand/plus/measurementtool/GpxData.java
// git revision b1d714a62c513b96bdc616ec5531cff8231c6f43
// Partially synced! Needs to be checked when other code is implemented

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EOAActionType)
{
    UNDEFINED = -1,
    ADD_SEGMENT = 0,
    ADD_ROUTE_POINTS,
    EDIT_SEGMENT,
    OVERWRITE_SEGMENT
};

@class OAGPXDocument, OATrackSegment, QuadRect;

@interface OAGpxData : NSObject

@property (nonatomic, readonly) OAGPXDocument *gpxFile;
@property (nonatomic, readonly) OATrackSegment *trkSegment;
@property (nonatomic, readonly) QuadRect *rect;
@property (nonatomic, readonly) EOAActionType actionType;

- (instancetype) initWithFile:(OAGPXDocument *)gpxFile rect:(QuadRect *)rect actionType:(EOAActionType)actionType trkSegment:(OATrackSegment *)trkSegment;
- (instancetype) initWithFile:(OAGPXDocument *)gpxFile gpxData:(OAGpxData *)gpxData;

@end
