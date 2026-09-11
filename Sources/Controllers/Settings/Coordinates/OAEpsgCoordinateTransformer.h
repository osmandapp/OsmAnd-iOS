//
//  OAEpsgCoordinateTransformer.h
//  OsmAnd
//
//  Created by Vitaliy Sova on 11.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAEpsgPoint : NSObject
@property (nonatomic, assign) double easting;
@property (nonatomic, assign) double northing;
@end

@interface OAEpsgCoordinateTransformer : NSObject

+ (instancetype)sharedInstance;

- (nullable OAEpsgPoint *)fromLonLatWithCode:(NSInteger)epsgCode lon:(double)lon lat:(double)lat;
- (nullable CLLocation *)toLonLatWithCode:(NSInteger)epsgCode easting:(double)easting northing:(double)northing;

@end

NS_ASSUME_NONNULL_END
