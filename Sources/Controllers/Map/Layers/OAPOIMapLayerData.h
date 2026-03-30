#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/Amenity.h>

@class OAPOI;
@class OAPOIType;
@class OAPOIUIFilter;
@class OAMapRendererView;
@class OAMapViewController;
@class QuadRect;

NS_ASSUME_NONNULL_BEGIN

@interface OAPOITileBoxRequest : NSObject<NSCopying>

@property (nonatomic, readonly) NSInteger left;
@property (nonatomic, readonly) NSInteger top;
@property (nonatomic, readonly) NSInteger right;
@property (nonatomic, readonly) NSInteger bottom;
@property (nonatomic, readonly) NSInteger width;
@property (nonatomic, readonly) NSInteger height;
@property (nonatomic, readonly) NSInteger zoom;
@property (nonatomic, readonly) QuadRect *latLonBounds;

- (instancetype)initWithMapView:(OAMapRendererView *)mapView;
- (instancetype)initWithVisibleBBox31:(const OsmAnd::AreaI &)visibleBBox31 zoom:(NSInteger)zoom;
- (instancetype)extendTileExtentX:(NSInteger)tileExtentX tileExtentY:(NSInteger)tileExtentY;
- (BOOL)containsRequest:(nullable OAPOITileBoxRequest *)request;

@end

@interface OAPOIMapLayerItem : NSObject

@property (nonatomic, readonly) BOOL usesFallbackPoi;
@property (nonatomic, readonly, nullable) OAPOI *cachedPoi;
@property (nonatomic, readonly, nullable) OAPOIType *type;
@property (nonatomic, readonly, nullable) NSString *wikiIconUrl;

- (instancetype)initWithAmenity:(const std::shared_ptr<const OsmAnd::Amenity> &)amenity;
- (instancetype)initWithPoi:(OAPOI *)poi;

- (std::shared_ptr<const OsmAnd::Amenity>)amenity;
- (nullable OAPOI *)poi;
- (nullable OAPOI *)poiIfLoaded;
- (int64_t)signedId;
- (OsmAnd::PointI)position31;
- (CLLocationCoordinate2D)coordinate;
- (nullable NSString *)captionWithLanguage:(nullable NSString *)language
                             transliterate:(BOOL)transliterate;
- (nullable NSString *)routeId;
- (nullable NSString *)wikidata;
- (int)travelEloNumber;
- (BOOL)isRouteTrack;
- (BOOL)isRouteArticlePoint;
- (BOOL)isWiki;
- (BOOL)isClosed;

@end

@interface OAPOIMapLayerDataReadyCallback : NSObject

@property (nonatomic, readonly) OAPOITileBoxRequest *request;
@property (nonatomic, readonly, nullable) NSArray<OAPOIMapLayerItem *> *results;
@property (nonatomic, readonly, nullable) NSArray<OAPOIMapLayerItem *> *displayedResults;
@property (nonatomic, readonly) BOOL ready;

- (instancetype)initWithRequest:(OAPOITileBoxRequest *)request;
- (BOOL)waitUntilReadyForTimeout:(NSTimeInterval)timeout;
- (void)onDataReadyWithResults:(nullable NSArray<OAPOIMapLayerItem *> *)results
              displayedResults:(nullable NSArray<OAPOIMapLayerItem *> *)displayedResults;

@end

@interface OAPOIMapLayerData : NSObject

@property (nonatomic, readonly) NSTimeInterval dataRequestTimeout;
@property (nonatomic, readonly, nullable) OAPOITileBoxRequest *queriedRequest;
@property (nonatomic, readonly, nullable) NSArray<OAPOIMapLayerItem *> *results;
@property (nonatomic, readonly, nullable) NSArray<OAPOIMapLayerItem *> *displayedResults;
@property (nonatomic, readonly, nullable) OAPOIUIFilter *topPlacesFilter;
@property (nonatomic, readonly) BOOL deferredResults;
@property (nonatomic, copy, nullable) dispatch_block_t layerOnPreExecute;
@property (nonatomic, copy, nullable) dispatch_block_t layerOnPostExecute;

- (instancetype)initWithMapView:(OAMapRendererView *)mapView
              mapViewController:(OAMapViewController *)mapViewController;

- (void)setPoiFilter:(nullable OAPOIUIFilter *)poiFilter
          wikiFilter:(nullable OAPOIUIFilter *)wikiFilter;
- (nullable OAPOIUIFilter *)poiFilter;
- (nullable OAPOIUIFilter *)wikiFilter;

- (OAPOIMapLayerDataReadyCallback *)getDataReadyCallback:(OAPOITileBoxRequest *)request;
- (void)addDataReadyCallback:(OAPOIMapLayerDataReadyCallback *)callback;
- (void)removeDataReadyCallback:(OAPOIMapLayerDataReadyCallback *)callback;
- (void)queryNewData:(OAPOITileBoxRequest *)request;
- (void)clearCache;
- (NSArray<OAPOI *> *)displayedResultsAsPoi;
- (NSArray<OAPOI *> *)resultsAsPoi;
- (nullable OAPOI *)poiForItem:(nullable OAPOIMapLayerItem *)item;

@end

NS_ASSUME_NONNULL_END
