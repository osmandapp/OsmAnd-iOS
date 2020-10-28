//
//  OAMeasurementEditingContext.h
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore/GpxDocument.h>

typedef NS_ENUM(NSInteger, EOACalculationMode)
{
    NEXT_SEGMENT = 0,
    WHOLE_TRACK
};

@class OAApplicationMode, OAMeasurementCommandManager, OAGpxData, OAGpxTrkPt, OAGpxTrkSeg;

@interface OAMeasurementEditingContext : NSObject

@property (nonatomic, readonly) OAMeasurementCommandManager *commandManager;
@property (nonatomic) OAApplicationMode *appMode;
@property (nonatomic) NSInteger selectedPointPosition;

@property (nonatomic) OAGpxTrkPt *originalPointToMove;

@property (nonatomic) BOOL inAddPointMode;
@property (nonatomic) BOOL inApproximationMode;

@property (nonatomic) OAGpxData *gpxData;

@property (nonatomic) EOACalculationMode lastCalculationMode;

- (NSArray<OAGpxTrkPt *> *) getPoints;
- (NSArray<OAGpxTrkPt *> *) getBeforePoints;
- (NSArray<OAGpxTrkPt *> *) getAfterPoints;
- (NSInteger) getPointsCount;

- (OAGpxTrkPt *) removePoint:(NSInteger)position updateSnapToRoad:(BOOL)updateSnapToRoad;
- (void) addPoint:(NSInteger)position pt:(OAGpxTrkPt *)pt;

- (OAGpxTrkSeg *) getBeforeTrkSegmentLine;
- (OAGpxTrkSeg *) getAfterTrkSegmentLine;

- (void) addPoint:(OAGpxTrkPt *)pt;

- (double) getRouteDistance;
- (BOOL) isNewData;

@end
