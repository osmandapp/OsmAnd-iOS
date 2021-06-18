//
//  OALocationsHolder.h
//  OsmAnd Maps
//
//  Created by Paul on 12.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <vector>

NS_ASSUME_NONNULL_BEGIN

@class CLLocation, OAGpxTrkPt;

@interface OALocationsHolder : NSObject <NSCopying>

@property (nonatomic, readonly, assign) NSInteger size;

- (instancetype) initWithLocations:(NSArray *)locations;


- (double) getLatitude:(NSInteger)index;
- (double) getLongitude:(NSInteger)index;

- (std::vector<std::pair<double, double>>) getLatLonList;
- (NSArray<OAGpxTrkPt *> *)getWptPtList;
- (NSArray<CLLocation *> *) getLocationsList;

//public LatLon getLatLon(int index)
- (OAGpxTrkPt *) getWptPt:(NSInteger)index;
- (CLLocation *) getLocation:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
