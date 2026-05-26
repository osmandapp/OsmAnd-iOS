//
//  OARouteColorize.h
//  OsmAnd Maps
//
//  Created by Paul on 24.09.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OASGpxTrackAnalysis, OASGpxFile, OASColorPalette, OASRouteColorizeColorizationType;

@interface OARouteColorizationPoint: NSObject

@property (nonatomic, assign) NSInteger identifier;
@property (nonatomic, assign) CGFloat lat;
@property (nonatomic, assign) CGFloat lon;
@property (nonatomic, assign) CGFloat val;
@property (nonatomic, assign) NSInteger color;

- (instancetype)initWithIdentifier:(NSInteger)identifier lat:(CGFloat)lat lon:(CGFloat)lon val:(CGFloat)val;

@end

@interface OARouteColorize : NSObject

- (instancetype)initWithGpxFile:(OASGpxFile *)gpxFile
                       analysis:(OASGpxTrackAnalysis *)analysis
                           type:(NSInteger)colorizationType
                        palette:(nullable OASColorPalette *)palette
                maxProfileSpeed:(float)maxProfileSpeed
                    fixedValues:(BOOL)fixedValues;

+ (OASRouteColorizeColorizationType *)sharedColorizationType:(NSInteger)colorizationType;
+ (NSArray<NSNumber *> *)colorsFromSharedPalette:(nullable OASColorPalette *)palette;
- (NSArray<OARouteColorizationPoint *> *)getResult;

@end

NS_ASSUME_NONNULL_END
