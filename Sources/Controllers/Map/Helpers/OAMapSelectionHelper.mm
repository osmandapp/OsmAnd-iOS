//
//  OAMapSelectionHelper.mm
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAMapSelectionHelper.h"
#import "OAMapSelectionResult.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OATargetPoint.h"
#import "OAMapLayer.h"
#import "OAMapLayers.h"
#import "OAContextMenuProvider.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererEnvironment.h"
#import "OAMapObject.h"
#import "OAPOI.h"
#import "OATransportStop.h"
#import "OAPOIFilter.h"
#import "OAClickableWay.h"
#import "OAClickableWayHelper.h"
#import "OAClickableWayHelper+cpp.h"
#import "OASelectedMapObject.h"
#import "OASelectedGpxPoint.h"
#import "OAPOIHelper.h"
#import "OAPOIHelper+cpp.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Map/AmenitySymbolsProvider.h>
#include <OsmAndCore/Map/BillboardRasterMapSymbol.h>
#include <OsmAndCore/NetworkRouteSelector.h>

static int AMENITY_SEARCH_RADIUS = 50;
static int AMENITY_SEARCH_RADIUS_FOR_RELATION = 500;
static int TILE_SIZE = 256;

static NSString *TAG_POI_LAT_LON = @"osmand_poi_lat_lon";

@implementation OAMapSelectionHelper
{
    NSArray<OAMapLayer *> *_pointLayers;
    OAClickableWayHelper *_clickableWayHelper;
    NSArray<NSString *> *_publicTransportTypes;
    id _provider;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _clickableWayHelper = [[OAClickableWayHelper alloc] init];
        _provider = OARootViewController.instance.mapPanel.mapViewController.mapLayers.poiLayer;
    }
    return self;
}

- (OAMapSelectionResult *) collectObjectsFromMap:(CGPoint)point showUnknownLocation:(BOOL)showUnknownLocation
{
    if (!_provider)
        _provider = _provider = OARootViewController.instance.mapPanel.mapViewController.mapLayers.poiLayer;
    
    OAMapSelectionResult *result = [[OAMapSelectionResult alloc] initWithPoint:point];
    [self collectObjectsFromLayers:result unknownLocation:showUnknownLocation secondaryObjects:NO];
    [self collectObjectsFromMap:result point:point]; //start from this
    
    [self processTransportStops:[result getAllObjects]];
    if ([result isEmpty])
        [self collectObjectsFromLayers:result unknownLocation:showUnknownLocation secondaryObjects:YES];
    
    [result groupByOsmIdAndWikidataId];
    return result;
}

- (void) collectObjectsFromMap:(OAMapSelectionResult *)result point:(CGPoint)point
{
    [self selectObjectsFromOpenGl:result point:point];
}

- (void) collectObjectsFromLayers:(OAMapSelectionResult *)result unknownLocation:(BOOL)unknownLocation secondaryObjects:(BOOL)secondaryObjects
{
    OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;

    
    NSArray<OAMapLayer *> *layers = [mapViewController.mapLayers getLayers];
    
    for (OAMapLayer *layer in layers)
    {
        // Android doesn't have that layer here
        if ([layer isKindOfClass:OAOsmBugsLayer.class])
            continue;
        
        if ([layer conformsToProtocol:@protocol(OAContextMenuProvider)])
        {
            id<OAContextMenuProvider> provider = ((id<OAContextMenuProvider>)layer);
            
            if ([provider isSecondaryProvider] || secondaryObjects)
            {
                [provider collectObjectsFromPoint:result unknownLocation:unknownLocation excludeUntouchableObjects:NO];
            }
        }
    }
}

- (void) selectObjectsFromOpenGl:(OAMapSelectionResult *)result point:(CGPoint)point
{
    OAMapViewController *mapVc = OARootViewController.instance.mapPanel.mapViewController;
    OAMapRendererView *rendererView = (OAMapRendererView *) mapVc.view;
    
    if (rendererView)
    {
        int delta = 20;
        OsmAnd::PointI tl = OsmAnd::PointI(point.x - delta, point.y - delta);
        OsmAnd::PointI br = OsmAnd::PointI(point.x + delta, point.y + delta);
        OsmAnd::AreaI area(tl, br);
        
        BOOL osmRoutesAlreadyAdded = NO;
        const auto& symbols = [rendererView getSymbolsIn:area strict:NO];
        
        for (const auto symbolInfo : symbols)
        {
            if (symbolInfo.mapSymbol->ignoreClick)
                continue;
            
            OAPOI *amenity;
            std::shared_ptr<const OsmAnd::Amenity> cppAmenity;
            
            if (const auto billboardMapSymbol = std::dynamic_pointer_cast<const OsmAnd::IBillboardMapSymbol>(symbolInfo.mapSymbol))
            {
                double lat = OsmAnd::Utilities::get31LatitudeY(billboardMapSymbol->getPosition31().y);
                double lon = OsmAnd::Utilities::get31LongitudeX(billboardMapSymbol->getPosition31().x);
                result.objectLatLon = [[CLLocation alloc] initWithLatitude:lat longitude:lon];

                if (const auto billboardAdditionalParams = std::dynamic_pointer_cast<const OsmAnd::MapSymbolsGroup::AdditionalBillboardSymbolInstanceParameters>(symbolInfo.instanceParameters))
                {
                    if (billboardAdditionalParams->overridesPosition31)
                    {
                        lon = OsmAnd::Utilities::get31LongitudeX(billboardAdditionalParams->position31.x); //TODO: not tested yet
                        lat = OsmAnd::Utilities::get31LatitudeY(billboardAdditionalParams->position31.y);
                        result.objectLatLon = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
                    }
                }
                
                if (const auto amenitySymbolGroup = dynamic_cast<OsmAnd::AmenitySymbolsProvider::AmenitySymbolsGroup*>(symbolInfo.mapSymbol->groupPtr))
                {
                    cppAmenity = amenitySymbolGroup->amenity;                                     //TODO: not tested yet
                }
            }
            else
            {
                result.objectLatLon = [mapVc getLatLonFromElevatedPixel:point.x y:point.y]; //TODO: not tested yet
            }
            
            if (cppAmenity != nullptr)
            {
                NSMutableArray<NSString *> *names = [NSMutableArray new];                       //TODO: not tested yet
                for (const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(cppAmenity->localizedNames)))
                {
                    NSString *name = entry.value().toNSString();
                    if (name)
                        [names addObject:name];
                }
                
                NSString *nativeName = cppAmenity->nativeName.toNSString();
                if (nativeName)
                    [names addObject:nativeName];
                
                uint64_t obfId = cppAmenity->id.id;
                amenity = [self.class findAmenity:result.objectLatLon names:names obfId:obfId];
            }
            else
            {
                if (const auto mapObjectSymbolsGroup = dynamic_cast<OsmAnd::MapObjectsSymbolsProvider::MapObjectSymbolsGroup*>(symbolInfo.mapSymbol->groupPtr))
                {
                    if (const auto obfMapObject = mapObjectSymbolsGroup->mapObject)
                    {
                        MutableOrderedDictionary<NSString *,NSString *> *tags = [self getOrderedTags:obfMapObject->getResolvedAttributesListPairs()];
                        
                        BOOL isTravelGpx = [OATravelObfHelper.shared isTravelGpxTags:tags];
                        BOOL isOsmRoute = !OsmAnd::NetworkRouteKey::getRouteKeys([self toQHash:tags]).isEmpty();
                        BOOL isClickableWay = [_clickableWayHelper isClickableWay:obfMapObject tags:tags];
                        
                        if (isOsmRoute && !osmRoutesAlreadyAdded)
                        {
                            osmRoutesAlreadyAdded = [self addOsmRoutesAround:result point:point selectorFilter:[self createRouteFilter]];    //TODO: not tested yet
                        }
                        
                        if (!isOsmRoute || !osmRoutesAlreadyAdded)
                        {
                            if (isTravelGpx)
                            {
                                [self addTravelGpx:result routeId: tags[ROUTE_ID]];                           //TODO: not tested yet
                            }
                            else if (isClickableWay)
                            {
                                OAClickableWay *clickableWay = [_clickableWayHelper loadClickableWay:[result getPointLatLon] obfMapObject:obfMapObject tags:tags];
                                [self addClickableWay:result clickableWay:clickableWay];                      //TODO: not tested yet
                            }
                        }
                        
                        BOOL allowAmenityObjects = !isTravelGpx;
                        
                        if (allowAmenityObjects)
                        {   
                            auto onPathMapSymbol = std::dynamic_pointer_cast<const  OsmAnd::IOnPathMapSymbol>(symbolInfo.mapSymbol);
                            if (onPathMapSymbol == nullptr)
                            {
                                CLLocation *latLon = result.objectLatLon;
                                NSString *latLonTag = tags[TAG_POI_LAT_LON];
                                if (latLonTag)
                                {
                                    CLLocation *l = [self parsePoiLatLon:latLonTag];
                                    if (l)
                                        latLon = l;
                                    [tags removeObjectForKey:TAG_POI_LAT_LON];
                                }
                                
                                BOOL allowRenderedObjects = !isOsmRoute && !isClickableWay &&  !OsmAnd::NetworkRouteKey::containsUnsupportedRouteTags([self toQHash:tags]);
                                
                                amenity = [self getAmenity:latLon obfMapObject:obfMapObject tags:tags];
                                
                                if (amenity)
                                {
                                    [amenity setMapIconName:[self getMapIconName:symbolInfo]];
                                }
                                else if (allowRenderedObjects)
                                {
                                    [self addRenderedObject:result symbolInfo:symbolInfo obfMapObject:obfMapObject tags:tags];   //TODO: not tested yet
                                }
                            }
                        }
                    }
                }
            }
            
            if (amenity && [self isUniqueAmenity:[result getAllObjects] amenity:amenity])                            //TODO: not tested
            {
                [result collect:amenity provider:_provider];
            }
        }
    }
}

- (CLLocation *) parsePoiLatLon:(NSString *)value
{
    if (!value)
        return nil;
    
    OASKGeoParsedPoint *p = [OASKMapUtils.shared decodeShortLinkStringS:value];
    return [[CLLocation alloc] initWithLatitude:p.getLatitude longitude:p.getLongitude];
}

- (NSString *) getMapIconName:(OsmAnd::IMapRenderer::MapSymbolInformation)symbolInfo
{
    const auto rasterMapSymbol = [self getRasterMapSymbol:symbolInfo];
    if (rasterMapSymbol != nullptr && rasterMapSymbol->contentClass == OsmAnd::RasterMapSymbol::ContentClass::Icon)
    {
        return rasterMapSymbol->content.toNSString();
    }
    return nil;
}

- (const shared_ptr<const OsmAnd::BillboardRasterMapSymbol>) getRasterMapSymbol:(OsmAnd::IMapRenderer::MapSymbolInformation)symbolInfo
{
    if (const auto rasterMapSymbol = std::static_pointer_cast<const OsmAnd::BillboardRasterMapSymbol>(symbolInfo.mapSymbol))
    {
        return rasterMapSymbol;
    }
    return nullptr;
}

- (void) addRenderedObject:(OAMapSelectionResult *)result symbolInfo:(OsmAnd::IMapRenderer::MapSymbolInformation)symbolInfo obfMapObject:(const std::shared_ptr<const OsmAnd::MapObject>)obfMapObject tags:(MutableOrderedDictionary<NSString *,NSString *> *)tags
{
    const auto rasterMapSymbol = [self getRasterMapSymbol:symbolInfo];
    if (rasterMapSymbol != nullptr)
    {
        OARenderedObject *renderedObject = [[OARenderedObject alloc] init];
        if (const auto& mapObject = std::dynamic_pointer_cast<const OsmAnd::ObfMapObject>(obfMapObject))
        {
            renderedObject.obfId = mapObject->id.id;
        }
        const auto points31 = obfMapObject->points31;
        for (int k = 0; k < points31.size(); k++)
        {
            const auto pointI = points31[k];
            [renderedObject addLocation:pointI.x y:pointI.y];
        }
        
        double lat = OsmAnd::Utilities::get31LatitudeY(obfMapObject->getLabelCoordinateY());
        double lon = OsmAnd::Utilities::get31LongitudeX(obfMapObject->getLabelCoordinateX());
        [renderedObject setLabelLatLon:[[CLLocation alloc] initWithLatitude:lat longitude:lon]];
        
        if (rasterMapSymbol->contentClass == OsmAnd::RasterMapSymbol::ContentClass::Caption)
        {
            [renderedObject setName:rasterMapSymbol->content.toNSString()];
        }
        if (rasterMapSymbol->contentClass == OsmAnd::RasterMapSymbol::ContentClass::Icon)
        {
            [renderedObject setIconRes:rasterMapSymbol->content.toNSString()];
        }
        for (NSString *key in tags)
        {
            renderedObject.tags[key] = tags[key];
            
        }
        [result collect:renderedObject provider:nil];
    }
}

- (OAPOI *) getAmenity:(CLLocation *)latLon obfMapObject:(const std::shared_ptr<const OsmAnd::MapObject>)obfMapObject tags:(MutableOrderedDictionary<NSString *,NSString *> *)tags
{
    NSMutableArray<NSString *> *names = [self getValues:obfMapObject->getCaptionsInAllLanguages()];
    NSString *caption = obfMapObject->getCaptionInNativeLanguage().toNSString();
    if (!NSStringIsEmpty(caption))
        [names addObject:caption];
    
    if (!NSDictionaryIsEmpty(tags) && tags[OATravelGpx.TRAVEL_MAP_TO_POI_TAG] && [tags[ROUTE_TAG] isEqualToString:@"point"])
    {
        [names addObject:tags[OATravelGpx.TRAVEL_MAP_TO_POI_TAG]]; // additional attribute for TravelGpx points (route_id)
    }
    
    uint64_t obfId = -1;
    if (const auto& mapObject = std::dynamic_pointer_cast<const OsmAnd::ObfMapObject>(obfMapObject))
    {
        obfId = mapObject->id.id;
    }
    
    OAPOI *amenity = [self.class findAmenity:latLon names:names obfId:obfId];
    if (amenity && obfMapObject->points31.size() > 1)
    {
        const auto points31 = obfMapObject->points31;
        for (int k = 0; k < points31.size(); k++)
        {
            [amenity addLocation:points31[k].x y:points31[k].y];
        }
    }
    return amenity;
}

- (void) addTravelGpx:(OAMapSelectionResult *)result routeId:(NSString *)routeId
{
    OATravelGpx *travelGpx = [OATravelObfHelper.shared searchTravelGpxWithLatLon:result.objectLatLon.coordinate routeId:routeId];
    
    if (travelGpx && [self isUniqueTravelGpx:[result getAllObjects] travelGpx:travelGpx])
    {

    }
    
    
    //TODO: implement later
}

- (BOOL) addClickableWay:(OAMapSelectionResult *)result clickableWay:(OAClickableWay *)clickableWay
{
    if (clickableWay && [self isUniqueClickableWay:[result getAllObjects] clickableWay:clickableWay])
    {
        [result collect:clickableWay provider:[_clickableWayHelper getContextMenuProvider]];
        return YES;
    }
    return NO;
}

- (BOOL) isUniqueGpxFileName:(NSMutableArray<OASelectedMapObject *> *)selectedObjects gpxFileName:(NSString *)gpxFileName
{
    for (OASelectedMapObject *selectedObject in selectedObjects)
    {
        id object = selectedObject.object;
        if ([object isKindOfClass:OASelectedGpxPoint.class] && [selectedObject.provider isKindOfClass:OAGPXLayer.class])
        {
            OASelectedGpxPoint *gpxPoint = (OASelectedGpxPoint *)object;
            if ([[[gpxPoint getSelectedGpxFile] path] hasSuffix:gpxFileName])
            {
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL) isUniqueClickableWay:(NSMutableArray<OASelectedMapObject *> *)selectedObjects clickableWay:(OAClickableWay *)clickableWay
{
    for (OASelectedMapObject *selectedObject in selectedObjects)
    {
        if ([selectedObject.object isKindOfClass:OAClickableWay.class] &&
            clickableWay.osmId == ((OAClickableWay *) selectedObject.object).osmId)
        {
            return NO;
        }
    }
 
    NSString *gpxFileName = [[clickableWay getGpxFileName] stringByAppendingPathExtension:GPX_FILE_EXT];
    return [self isUniqueGpxFileName:selectedObjects gpxFileName:gpxFileName];
}

- (BOOL) isUniqueTravelGpx:(NSMutableArray<OASelectedMapObject *> *)selectedObjects travelGpx:(OATravelGpx *)travelGpx
{
    for (OASelectedMapObject *selectedObject in selectedObjects)
    {
        if ([selectedObject.object isKindOfClass:NSArray.class] &&
            [selectedObject.provider isKindOfClass:OAGPXLayer.class])
        {
            NSArray *pair = (NSArray *)selectedObject.object;
            id firstOblect = [pair firstObject];
            if (firstOblect && [firstOblect isKindOfClass:OATravelGpx.class])
            {
                OATravelGpx *gpx = firstOblect;
                
                // TODO: test this isEqual method
                if (travelGpx == gpx)
                {
                    return NO;
                }
            }
        }
    }
    
    NSString *gpxFileName = [travelGpx.file lastPathComponent];
    return [self isUniqueGpxFileName:selectedObjects gpxFileName:gpxFileName];
}

- (BOOL) addOsmRoutesAround:(OAMapSelectionResult *)result point:(CGPoint)point selectorFilter:(OsmAnd::NetworkRouteSelectorFilter)selectorFilter
{
    //TODO: implement
    return NO;
}

- (OsmAnd::NetworkRouteSelectorFilter) createRouteFilter
{
    OsmAnd::NetworkRouteSelectorFilter routeSelectorFilter;
    
    
    
    //TODO: implement
    
    
    return routeSelectorFilter;
}

- (BOOL) isUniqueAmenity:(NSMutableArray<OASelectedMapObject *> *)selectedObjects amenity:(OAPOI *)amenity
{
    for (OASelectedMapObject *selectedObject in selectedObjects)
    {
        id object = selectedObject.object;
        if ([object isKindOfClass:OAPOI.class] && [((OAPOI *)object) strictEquals:amenity])
        {
            OAPOI *poi = ((OAPOI *)object);
            if ([poi strictEquals:amenity])
                return NO;
        }
        else if ([object isKindOfClass:OATransportStop.class])
        {
            OATransportStop *transportSpop = ((OATransportStop *)object);
            if ([transportSpop.name hasPrefix:amenity.name])
                return NO;
        }
    }
    return YES;
}

- (NSArray<NSString *> *) getPublicTransportTypes
{
    OAPOIHelper *poiHelper = [OAPOIHelper sharedInstance];
    if (!_publicTransportTypes)
    {
        OAPOICategory *category = [poiHelper getPoiCategoryByName:@"transportation"];
        if (category)
        {
            
            NSMutableArray *publicTransportTypes = [NSMutableArray array];
            NSArray<OAPOIFilter *> *filters = category.poiFilters;
            for (OAPOIFilter *poiFilter in filters)
            {
                if ([poiFilter.name isEqualToString:@"public_transport"] || [poiFilter.name isEqualToString:@"water_transport"])
                {
                    for (OAPOIType *poiType in poiFilter.poiTypes)
                    {
                        [publicTransportTypes addObject:poiType.name];
                        for (OAPOIType *poiAdditionalType in poiType.poiAdditionals)
                            [publicTransportTypes addObject:poiAdditionalType.name];
                    }
                }
            }
            _publicTransportTypes = [NSArray arrayWithArray:publicTransportTypes];
        }
    }
    return _publicTransportTypes;
}

- (void) processTransportStops:(NSMutableArray<OASelectedMapObject *> *)selectedObjects
{
    NSArray<NSString *> *publicTransportTypes = [self getPublicTransportTypes];
    if (publicTransportTypes)
    {
        NSMutableArray<OAPOI *> *transportStopAmenities = [NSMutableArray array];
        
        for (OASelectedMapObject *selectedObject in selectedObjects)
        {
            id object = selectedObject.object;
            if ([object isKindOfClass:[OAPOI class]])
            {
                OAPOI *amenity = (OAPOI *)object;
                if (!NSStringIsEmpty(amenity.type.name) && [publicTransportTypes containsObject:amenity.type.name])
                    [transportStopAmenities addObject:amenity];
            }
        }
        
        if (!NSArrayIsEmpty(transportStopAmenities))
        {
            for (OAPOI *amenity in transportStopAmenities)
            {
                OATransportStopsLayer *transportStopsLayer = [OARootViewController instance].mapPanel.mapViewController.mapLayers.transportStopsLayer;
                OATransportStop *transportStop = [OATransportStopsBaseController findNearestTransportStopForAmenity:amenity];
                if (transportStop && transportStopsLayer)
                {
                    OASelectedMapObject *newTransportStop = [[OASelectedMapObject alloc] initWithMapObject:transportStop provider:transportStopsLayer];
                    [selectedObjects addObject:newTransportStop];
                    
                    [selectedObjects filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(OASelectedMapObject *selectedObject, NSDictionary *bindings) {
                        return (!selectedObject && !amenity) || [amenity isEqual:selectedObject.object];
                    }]];

                }
            }
        }
    }
}

- (NSMutableArray<NSString *> *) getValues:(QHash<QString, QString>)set
{
    NSMutableArray<NSString *> *res = [NSMutableArray new];
    if (set.size() != 0)
    {
        QList<QString> keys = set.keys();
        for (int i = 0; i < keys.size(); i++)
            [res addObject:keys[i].toNSString()];
    }
    return res;
}

- (MutableOrderedDictionary<NSString *, NSString *> *) getOrderedTags:(QList<QPair<QString, QString>>)tagsList
{
    MutableOrderedDictionary<NSString *, NSString *> *tagsMap = [MutableOrderedDictionary new];
    for (int i = 0; i < tagsList.size(); i++)
    {
      QPair<QString, QString> pair = tagsList[i];
      NSString *key = pair.first.toNSString();
      NSString *value = pair.second.toNSString();
      if (key && value)
          tagsMap[key] = value;
    }
    return tagsMap;
}

+ (OAPOI *) findAmenity:(CLLocation *)latLon names:(NSArray<NSString *> *)names obfId:(uint64_t)obfId
{
    int searchRadius = [ObfConstants isIdFromRelation:obfId >> AMENITY_ID_RIGHT_SHIFT] ?
        AMENITY_SEARCH_RADIUS_FOR_RELATION :
        AMENITY_SEARCH_RADIUS;
    
    return [self findAmenity:latLon names:names obfId:obfId radius:searchRadius];
}

+ (OAPOI *) findAmenity:(CLLocation *)latLon names:(NSArray<NSString *> *)names obfId:(uint64_t)obfId radius:(int)radius
{
    uint64_t osmId = [ObfConstants getOsmId:obfId >> AMENITY_ID_RIGHT_SHIFT];
    OsmAnd::PointI point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(latLon.coordinate.latitude, latLon.coordinate.longitude));
    OsmAnd::AreaI rect = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(radius, point31);
    
    BOOL (^nilBlock)(OAPOI *poi) = nil;
    NSArray<OAPOI *> *amenities = [OAPOIHelper findPOI:OASearchPoiTypeFilter.acceptAllPoiTypeFilter additionalFilter:nil bbox31:rect currentLocation:point31 includeTravel:YES matcher:nil publish:nilBlock];
    OAPOI *amenity = [self findAmenityByOsmId:amenities obfId:osmId point:latLon];
    
    if (!amenity && names.count > 0)
    {
        amenity = [self findAmenityByName:amenities names:names];
    }
    return amenity;
}

+ (NSArray<OAPOI *> *) findAmenities:(CLLocation *)latLon
{
    OsmAnd::PointI point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(latLon.coordinate.latitude, latLon.coordinate.longitude));
    OsmAnd::AreaI rect = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(AMENITY_SEARCH_RADIUS, point31);
    BOOL (^nilBlock)(OAPOI *poi) = nil;
    return [OAPOIHelper findPOI:[OASearchPoiTypeFilter acceptAllPoiTypeFilter] additionalFilter:nil bbox31:rect currentLocation:point31 includeTravel:YES matcher:nil publish:nilBlock];
}

+ (OAPOI *) findAmenityByOsmId:(CLLocation *)latLon obfId:(uint64_t)obfId
{
    NSArray<OAPOI *> *amenities = [self findAmenities:latLon];
    return [self findAmenityByOsmId:amenities obfId:obfId point:latLon];
}

+ (OAPOI *) findAmenityByOsmId:(NSArray<OAPOI *> *)amenities obfId:(uint64_t)obfId point:(CLLocation *)point
{
    OAPOI *result = nil;
    double minDist = AMENITY_SEARCH_RADIUS_FOR_RELATION * 2;
    
    for (OAPOI *amenity in amenities)
    {
        uint64_t initAmenityId = amenity.obfId;
        if (initAmenityId != 0)
        {
            uint64_t amenityId;
            if ([ObfConstants isShiftedID:initAmenityId])
                amenityId = [ObfConstants getOsmId:initAmenityId];
            else
                amenityId = initAmenityId >> AMENITY_ID_RIGHT_SHIFT;
            
            if (amenityId == obfId && !amenity.isClosed)
            {
                double dist = [OAMapUtils getDistance:[amenity getLocation].coordinate second:point.coordinate];
                if (result == nil || dist < minDist)
                {
                    result = amenity;
                    minDist = dist;
                }
            }
        }
    }
    return result;
}

+ (OAPOI *) findAmenityByName:(NSArray<OAPOI *> *)amenities names:(NSArray<NSString *> *)names
{
    if (names.count > 0)
    {
        for (OAPOI *amenity in amenities)
        {
            if (!amenity.isClosed)
            {
                if ([names containsObject:amenity.name])
                    return amenity;
                
                if ([amenity isRoutePoint] && amenity.name.length == 0)
                {
                    NSString *travelRouteId = [amenity.values objectForKey:OATravelGpx.TRAVEL_MAP_TO_POI_TAG];
                    if (travelRouteId && [names containsObject:travelRouteId])
                        return amenity;
                }
            }
        }
    }
    return nil;
}

- (QHash<QString, QString>) toQHash:(NSDictionary<NSString *, NSString *> *) dict
{
    QHash<QString, QString> result;
    for (NSString *key in dict) {
        QString qKey = QString::fromNSString(key);
        QString qValue = QString::fromNSString(dict[key]);
        result.insert(qKey, qValue);
    }
    return result;
}

@end

