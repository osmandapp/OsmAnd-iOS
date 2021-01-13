//
//  OASaveGpxRouteAsyncTask.h
//  OsmAnd
//
//  Created by Paul on 08.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OARoutePlanningHudViewController, OAGPXDocument;

@interface OASaveGpxRouteAsyncTask : NSObject

- (instancetype) initWithHudController:(OARoutePlanningHudViewController * __weak)hudRef outFile:(NSString *)outFile gpxFile:(OAGPXDocument *)gpx simplified:(BOOL)simplified addToTrack:(BOOL)addToTrack showOnMap:(BOOL)showOnMap;

- (void) execute:(void(^)(OAGPXDocument *, NSString *))onComplete;

@end
