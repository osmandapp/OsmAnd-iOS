//
//  AisObjectDrawable.h
//  OsmAnd
//
//  Created by OsmAnd on 27.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef __cplusplus

#include <cstdint>
#include <memory>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/Map/VectorLinesCollection.h>

@class OAMapRendererView;
@class OASAisObject;

NS_ASSUME_NONNULL_BEGIN

@interface AisObjectDrawable : NSObject

@property (nonatomic, copy, nullable) NSString *renderKey;
@property (nonatomic) uint64_t renderedVersion;
@property (nonatomic) BOOL cpaWarning;
@property (nonatomic) float renderedSurfaceZoom;

+ (void)clearImageCache;
+ (CGFloat)baseIconSize;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithObject:(OASAisObject *)object;
- (instancetype)initWithObject:(OASAisObject *)object
                      textScale:(CGFloat)textScale
           displayDensityFactor:(CGFloat)displayDensityFactor NS_DESIGNATED_INITIALIZER;

- (void)setObject:(OASAisObject *)object visualState:(NSInteger)visualState;
- (void)setTextScale:(CGFloat)textScale
 displayDensityFactor:(CGFloat)displayDensityFactor;
- (BOOL)hasAisRenderData;
- (BOOL)hasAnyAisRenderData;
- (NSString *)currentRenderKey;
- (void)createAisRenderDataWithBaseOrder:(int)baseOrder
                       markersCollection:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection;
- (void)updateAisRenderDataWithMapView:(OAMapRendererView *)mapView
                            cpaWarning:(BOOL)cpaWarning
                               visible:(BOOL)visible
                 vectorLinesCollection:(const std::shared_ptr<OsmAnd::VectorLinesCollection> &)vectorLinesCollection;
- (void)clearAisRenderDataFromMarkersCollection:(const std::shared_ptr<OsmAnd::MapMarkersCollection> &)markersCollection
                          vectorLinesCollection:(const std::shared_ptr<OsmAnd::VectorLinesCollection> &)vectorLinesCollection;

@end

NS_ASSUME_NONNULL_END

#endif
