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
@property (nonatomic) NSMutableArray<OATrack *> *tracks;
@property (nonatomic) NSMutableArray<OARoute *> *routes;

@property (nonatomic) long modifiedTime;

- (instancetype)init;

- (const std::shared_ptr<OsmAnd::GpxDocument>&) getDocument;

- (void) updateDocAndMetadata;
- (void) addWpt:(OAWptPt *)w;
- (void) addTrack:(OATrack *)t;
- (void) addTracks:(NSArray<OATrack *> *)tracks;
- (void)addTrackSegment:(OATrkSegment *)s track:(OATrack *)track;
- (BOOL) removeTrackSegment:(OATrkSegment *)segment;
- (void) addTrackPoint:(OAWptPt *)p segment:(OATrkSegment *)segment;
- (void) addRoutePoints:(NSArray<OAWptPt *> *)points addRoute:(BOOL)addRoute;
- (void) addRoutes:(NSArray<OARoute *> *)routes;

- (void)deleteWpt:(OAWptPt *)w;
- (void)deleteAllWpts;
- (void) addWpts:(NSArray<OAWptPt *> *)wpts;

- (BOOL) saveTo:(NSString *)filename;

@end
