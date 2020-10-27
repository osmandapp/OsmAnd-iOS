//
//  OAGpxData.h
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EOAActionType)
{
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
