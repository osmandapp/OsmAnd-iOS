//
//  OAGPXMutableDocument.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocument.h"

@interface OAGPXMutableDocument : OAGPXDocument

@property (nonatomic) NSMutableArray<OAWptPt *> *points;
@property (nonatomic) NSMutableArray<OAGpxTrk *> *tracks;
@property (nonatomic) NSMutableArray<OAGpxRte *> *routes;

@property (nonatomic) long modifiedTime;

- (instancetype)init;

- (const std::shared_ptr<OsmAnd::GpxDocument>&) getDocument;

- (void) updateDocAndMetadata;
- (void) addWpt:(OAWptPt *)w;
- (void) addTrack:(OAGpxTrk *)t;
- (void) addTracks:(NSArray<OAGpxTrk *> *)tracks;
- (void) addTrackSegment:(OAGpxTrkSeg *)s track:(OAGpxTrk *)track;
- (BOOL) removeTrackSegment:(OAGpxTrkSeg *)segment;
- (void) addTrackPoint:(OAWptPt *)p segment:(OAGpxTrkSeg *)segment;
- (void) addRoutePoints:(NSArray<OAWptPt *> *)points addRoute:(BOOL)addRoute;
- (void) addRoutes:(NSArray<OAGpxRte *> *)routes;

- (void)deleteWpt:(OAWptPt *)w;
- (void)deleteAllWpts;
- (void) addWpts:(NSArray<OAWptPt *> *)wpts;

- (BOOL) saveTo:(NSString *)filename;

@end
