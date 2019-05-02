//
//  OAOsmMapUtils.h
//  OsmAnd
//
//  Created by Paul on 1/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/osm/edit/OsmMapUtils.java
//  git revision db3b280a26eaf721222ec918e8c0baf4dca9b1fd

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAWay;

@interface OAOsmMapUtils : NSObject

+(CLLocationCoordinate2D)getWeightCenterForWay:(OAWay *)way;

@end

NS_ASSUME_NONNULL_END
