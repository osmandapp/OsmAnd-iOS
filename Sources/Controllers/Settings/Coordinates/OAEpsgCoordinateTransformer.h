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

@interface OAEpsgGridConstants : NSObject
@property (nonatomic, assign) double lonMin;
@property (nonatomic, assign) double lonMax;
@property (nonatomic, assign) double latMin;
@property (nonatomic, assign) double latMax;
@property (nonatomic, assign) double semiMajor;
@property (nonatomic, assign) double invFlattening;
@property (nonatomic, assign) double refLon;
@property (nonatomic, assign) double refLat;
@property (nonatomic, assign) double falseEasting;
@property (nonatomic, assign) double falseNorthing;
@property (nonatomic, assign) double scaleFactor;
@property (nonatomic, assign) double scaleFactorY;
@end

@interface OAEpsgEllipsoidParameters : NSObject
@property (nonatomic, assign) double translationsX;
@property (nonatomic, assign) double translationsY;
@property (nonatomic, assign) double translationsZ;
@property (nonatomic, assign) double translationsW;
@property (nonatomic, assign) double rotationsX;
@property (nonatomic, assign) double rotationsY;
@property (nonatomic, assign) double rotationsZ;
@property (nonatomic, assign) double scale;
@end

@interface OAEpsgPoint : NSObject
@property (nonatomic, assign) double easting;
@property (nonatomic, assign) double northing;
@end

@interface OAEpsgCoordinateTransformer : NSObject

+ (instancetype)sharedInstance;

- (nullable OAEpsgPoint *)fromLonLatWithCode:(NSInteger)epsgCode lon:(double)lon lat:(double)lat;
- (nullable CLLocation *)toLonLatWithCode:(NSInteger)epsgCode easting:(double)easting northing:(double)northing;
- (nullable OAEpsgGridConstants *)constantsForCode:(NSInteger)epsgCode
                                     projectionRaw:(NSInteger)projectionRaw;
- (nullable OAEpsgEllipsoidParameters *)ellipsoidParametersForCode:(NSInteger)epsgCode
                                                     operationCode:(NSInteger)operationCode;

@end

NS_ASSUME_NONNULL_END
