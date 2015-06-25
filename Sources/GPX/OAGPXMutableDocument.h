//
//  OAGPXMutableDocument.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocument.h"

@interface OAGPXMutableDocument : OAGPXDocument

@property (nonatomic) NSMutableArray *locationMarks;
@property (nonatomic) NSMutableArray *tracks;
@property (nonatomic) NSMutableArray *routes;

@property (nonatomic) long modifiedTime;

- (instancetype)init;

- (const std::shared_ptr<OsmAnd::GpxDocument>&) getDocument;

- (void) updateDocName;
- (void) updateDocAndMetadata;
- (void) addWpt:(OAGpxWpt *)w;
- (void) addTrack:(OAGpxTrk *)t;
- (void) addTrackSegment:(OAGpxTrkSeg *)s track:(OAGpxTrk *)track;
- (void) addTrackPoint:(OAGpxTrkPt *)p segment:(OAGpxTrkSeg *)segment;

- (void)deleteWpt:(OAGpxWpt *)w;

- (BOOL) saveTo:(NSString *)filename;

@end
