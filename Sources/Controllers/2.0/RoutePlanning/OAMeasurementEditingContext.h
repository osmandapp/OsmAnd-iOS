//
//  OAMeasurementEditingContext.h
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
// OsmAnd/src/net/osmand/plus/measurementtool/MeasurementEditingContext.java
// git revision 17b7386514528d4ac1ca6fd729278d6321ec95a8
// Partially synced!

#import <Foundation/Foundation.h>

#include <OsmAndCore/GpxDocument.h>

typedef NS_ENUM(NSInteger, EOACalculationMode)
{
    NEXT_SEGMENT = 0,
    WHOLE_TRACK
};

typedef NS_ENUM(NSInteger, EOAAddPointMode) {
    EOAAddPointModeUndefined = -1,
    EOAAddPointModeBefore = 0,
    EOAAddPointModeAfter
};

@class OAApplicationMode, OAMeasurementCommandManager, OAGpxData, OAGpxTrkPt, OAGpxTrkSeg, OARoadSegmentData;

@protocol OASnapToRoadProgressDelegate

- (void) showProgressBar;
- (void) updateProgress:(int)progress;
- (void) hideProgressBar;
- (void) refresh;

@end

@interface OAMeasurementEditingContext : NSObject

@property (nonatomic, weak) id<OASnapToRoadProgressDelegate> progressDelegate;

@property (nonatomic, readonly) OAMeasurementCommandManager *commandManager;
@property (nonatomic) OAApplicationMode *appMode;
@property (nonatomic) NSInteger selectedPointPosition;

@property (nonatomic) OAGpxTrkPt *originalPointToMove;

@property (nonatomic) BOOL inAddPointMode;
@property (nonatomic) BOOL inApproximationMode;

@property (nonatomic) OAGpxData *gpxData;

@property (nonatomic) EOACalculationMode lastCalculationMode;

@property (nonatomic) EOAAddPointMode addPointMode;

@property (nonatomic) NSMutableDictionary<NSArray<OAGpxTrkPt *> *, OARoadSegmentData *> *roadSegmentData;

- (NSArray<OAGpxTrkPt *> *) getAllPoints;
- (NSArray<OAGpxTrkPt *> *) getPoints;
- (NSArray<OAGpxTrkPt *> *) getBeforePoints;
- (NSArray<OAGpxTrkPt *> *) getAfterPoints;
- (NSInteger) getPointsCount;
- (void) clearPoints;

- (OAGpxTrkPt *) removePoint:(NSInteger)position updateSnapToRoad:(BOOL)updateSnapToRoad;
- (void) addPoint:(NSInteger)position pt:(OAGpxTrkPt *)pt;
- (void) addPoints:(NSArray<OAGpxTrkPt *> *)points;

- (NSArray<OAGpxTrkSeg *> *) getBeforeTrkSegmentLine;
- (NSArray<OAGpxTrkSeg *> *) getAfterTrkSegmentLine;

- (void) addPoint:(OAGpxTrkPt *)pt;

- (double) getRouteDistance;
- (BOOL) isNewData;

- (void) clearSegments;
- (void) trimBefore:(NSInteger)selectedPointPosition;
- (void) trimAfter:(NSInteger)selectedPointPosition;
- (void) splitSegments:(NSInteger)position;

- (void) updateSegmentsForSnap;

@end
