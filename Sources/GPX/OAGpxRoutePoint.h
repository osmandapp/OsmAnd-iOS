//
//  OAGpxRoutePoint.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocumentPrimitives.h"

@interface OAGpxRoutePoint : OAGpxWpt

@property (nonatomic, assign) BOOL visited;
@property (nonatomic, assign) long visitedTime;
@property (nonatomic, assign) BOOL disabled;
@property (nonatomic, assign) int index;

- (instancetype)initWithWpt:(OAGpxWpt *)gpxWpt;

- (void)applyRouteInfo;
- (void)clearRouteInfo;

@end
