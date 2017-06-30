//
//  OAGPXMutableDocument.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocument.h"

@interface OAGPXMutableDocument : OAGPXDocument

@property (nonatomic) NSMutableArray<OAGpxWpt *> *locationMarks;
@property (nonatomic) NSMutableArray<OAGpxTrk *> *tracks;
@property (nonatomic) NSMutableArray<OAGpxRte *> *routes;

@property (nonatomic) long modifiedTime;

- (instancetype)init;

- (const std::shared_ptr<OsmAnd::GpxDocument>&) getDocument;

- (void) updateDocAndMetadata;
- (void) addWpt:(OAGpxWpt *)w;
- (void) addTrack:(OAGpxTrk *)t;
- (void) addTrackSegment:(OAGpxTrkSeg *)s track:(OAGpxTrk *)track;
- (void) addTrackPoint:(OAGpxTrkPt *)p segment:(OAGpxTrkSeg *)segment;

- (void)deleteWpt:(OAGpxWpt *)w;
- (void)deleteAllWpts;

- (BOOL) saveTo:(NSString *)filename;

@end
