//
//  OARouteProvider.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/routing/RouteProvider.java
//  git revision e5a489637a08d21827a1edd2cf6581339b5f748a

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, EOARouteService)
{
    OSMAND = 0,
    YOURS,
    OSRM,
    BROUTER,
    STRAIGHT
};

@class OAGPXDocument;

@interface OARouteService : NSObject

@property (nonatomic, readonly) EOARouteService service;

+ (instancetype)withService:(EOARouteService)service;

+ (NSString *)getName:(EOARouteService)service;
+ (BOOL) isOnline:(EOARouteService)service;
+ (BOOL) isAvailable:(EOARouteService)service;
+ (NSArray<OARouteService *> *) getAvailableRouters;

@end

@class OALocationMark, OARouteDirectionInfo;

@interface OAGPXRouteParams : NSObject

@property (nonatomic) NSArray<CLLocation *> *points;
@property (nonatomic) NSArray<OARouteDirectionInfo *> *directions;
@property (nonatomic) BOOL calculateOsmAndRoute;
@property (nonatomic) BOOL passWholeRoute;
@property (nonatomic) BOOL calculateOsmAndRouteParts;
@property (nonatomic) BOOL useIntermediatePointsRTE;
@property (nonatomic) NSArray<OALocationMark *> *wpt;
    
@property (nonatomic) BOOL addMissingTurns;
    
@end

@interface OAGPXRouteParamsBuilder : NSObject

@property (nonatomic, readonly) OAGPXDocument *file;

@property (nonatomic) BOOL calculateOsmAndRoute;
@property (nonatomic) BOOL reverse;
@property (nonatomic, readonly) BOOL leftSide;
@property (nonatomic) BOOL passWholeRoute;
@property (nonatomic) BOOL calculateOsmAndRouteParts;
@property (nonatomic) BOOL useIntermediatePointsRTE;

- (instancetype)initWithDoc:(OAGPXDocument *)document;

/*
    public GPXRouteParams build(Location start, OsmandSettings settings) {
        GPXRouteParams res = new GPXRouteParams();
        res.prepareGPXFile(this);
        //			if (passWholeRoute && start != null) {
        //				res.points.add(0, start);
        //			}
        return res;
    }

    public List<Location> getPoints() {
        GPXRouteParams copy = new GPXRouteParams();
        copy.prepareGPXFile(this);
        return copy.getPoints();
    }
 */

@end

@interface OARouteProvider : NSObject

@end
