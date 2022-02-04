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
#include <OsmAndCore/Color.h>

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

@class OAApplicationMode, OAMeasurementCommandManager, OAGpxData, OAWptPt, OATrkSegment, OARoadSegmentData, OAGPXMutableDocument, OAGpxRouteApproximation;

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

@property (nonatomic) OAWptPt *originalPointToMove;

@property (nonatomic) BOOL inAddPointMode;
@property (nonatomic) BOOL inApproximationMode;

@property (nonatomic) OAGpxData *gpxData;
@property (nonatomic) NSInteger selectedSegment;

@property (nonatomic) EOACalculationMode lastCalculationMode;

@property (nonatomic) EOAAddPointMode addPointMode;
@property (nonatomic, assign) BOOL approximationMode;

@property (nonatomic) NSMutableDictionary<NSArray<OAWptPt *> *, OARoadSegmentData *> *roadSegmentData;

- (NSArray<OAWptPt *> *) getAllPoints;
- (NSArray<OAWptPt *> *) getPoints;
- (NSArray<NSArray<OAWptPt *> *> *) getPointsSegments:(BOOL)plain route:(BOOL)route;
- (NSArray<OAWptPt *> *) getBeforePoints;
- (NSArray<OAWptPt *> *) getAfterPoints;
- (NSInteger) getPointsCount;
- (void) clearPoints;
- (void) clearSnappedToRoadPoints;

- (OAWptPt *) removePoint:(NSInteger)position updateSnapToRoad:(BOOL)updateSnapToRoad;
- (void) addPoint:(NSInteger)position pt:(OAWptPt *)pt;
- (void) addPoints:(NSArray<OAWptPt *> *)points;
- (void) addPoints;
- (void) setPoints:(NSArray<OAWptPt *> *)points;

- (NSArray<OATrkSegment *> *) getBeforeTrkSegmentLine;
- (NSArray<OATrkSegment *> *) getAfterTrkSegmentLine;

- (NSArray<OATrkSegment *> *) getBeforeSegments;
- (NSArray<OATrkSegment *> *) getAfterSegments;

- (OAApplicationMode *) getBeforeSelectedPointAppMode;
- (OAApplicationMode *) getSelectedPointAppMode;

- (void) addPoint:(OAWptPt *)pt;
- (void) addPoint:(OAWptPt *)pt mode:(EOAAddPointMode)mode;
- (void) addPoint:(NSInteger)position point:(OAWptPt *)pt mode:(EOAAddPointMode)mode;

- (NSArray<OAWptPt *> *) setPoints:(OAGpxRouteApproximation *)gpxApproximation originalPoints:(NSArray<OAWptPt *> *)originalPoints mode:(OAApplicationMode *)mode;

- (double) getRouteDistance;
- (BOOL) isNewData;
- (BOOL) isApproximationNeeded;
- (BOOL) isAddNewSegmentAllowed;
- (BOOL) hasRoute;

- (BOOL) isInAddPointMode;

- (void) splitPoints:(NSInteger) selectedPointPosition after:(BOOL)after;
- (void) joinPoints:(NSInteger) selectedPointPosition;
- (void) clearSegments;
- (void) trimBefore:(NSInteger)selectedPointPosition;
- (void) trimAfter:(NSInteger)selectedPointPosition;
- (void) splitSegments:(NSInteger)position;

- (BOOL) isFirstPointSelected:(BOOL)outer;
- (BOOL) isFirstPointSelected:(NSInteger)selectedPointPosition outer:(BOOL)outer;
- (BOOL) isLastPointSelected:(BOOL) outer;
- (BOOL) isLastPointSelected:(NSInteger)selectedPointPosition outer:(BOOL)outer;

- (void) updateSegmentsForSnap;

- (void) cancelSnapToRoad;

- (OsmAnd::ColorARGB) getLineColor;

- (OAGPXMutableDocument *) exportGpx:(NSString *)gpxName;
- (NSArray<NSArray<OAWptPt *> *> *) getRoutePoints;

- (void) scheduleRouteCalculateIfNotEmpty;

- (void) setChangesSaved;
- (BOOL) hasChanges;

- (BOOL) canSplit:(BOOL)after;

- (void) resetAppMode;

@end
