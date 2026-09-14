//
//  OACppRouteConverter.h
//  OsmAnd
//
//  Turns a route calculated by the C++ router into the OsmAndShared route segments the app's route
//  model is built on, so that the C++ router keeps working while it is still the default and the
//  rest of the app reads one kind of segment either way.
//
//  Temporary by design: it exists only while the C++ router does. When the shared planner becomes
//  the only one, this converter goes with it, and nothing else has to change.
//

#import <Foundation/Foundation.h>

#include "CommonCollections.h"
#include "commonOsmAndCore.h"

struct RouteSegmentResult;
struct TurnType;

@class OASRouteSegmentResult, OASTurnType;

@interface OACppRouteConverter : NSObject

/**
 * The same route, as shared segments. Roads and their regions are converted once per call and
 * shared between the segments that sit on them, as the shared reader would return them.
 *
 * The roads attached to a segment at each of its points come over one level deep - the exit
 * information is read off them - but the roads attached to those do not, and neither do the
 * pre-attached routes: the preparation has already used them and nothing outside the planner
 * reads them.
 */
+ (NSArray<OASRouteSegmentResult *> *) toSharedSegments:(const std::vector<std::shared_ptr<RouteSegmentResult>> &)segments;

/** One manoeuvre, for the places that still take it off a C++ segment. */
+ (OASTurnType *) toSharedTurnType:(const std::shared_ptr<TurnType> &)turnType;

@end
