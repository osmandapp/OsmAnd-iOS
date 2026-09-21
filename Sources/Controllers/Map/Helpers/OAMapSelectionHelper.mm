//
//  OAMapSelectionHelper.mm
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// OsmAnd/src/net/osmand/plus/views/layers/MapSelectionHelper.java
// git revision 14c59e54e11dd340f5cbf9ea99b9f2a85ae9c644

#import "OAMapSelectionHelper.h"
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
#import "OAClickableWayHelper.h"
#import "OAClickableWayHelper+cpp.h"
#import "OAPOIHelper.h"
#import "OAPOIHelper+cpp.h"
#import "OAAmenitySearcher.h"
#import "OAAmenitySearcher+cpp.h"
#import "OAClickableWayMenuProvider.h"
#import "OATravelSelectionLayer.h"
#import "OAAmenitySearcher.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Map/AmenitySymbolsProvider.h>
#include <OsmAndCore/Map/BillboardRasterMapSymbol.h>
#include <OsmAndCore/NetworkRouteContext.h>
#include <OsmAndCore/Data/ObfMapObject.h>

static int AMENITY_SEARCH_RADIUS = 50;
static int AMENITY_SEARCH_RADIUS_FOR_RELATION = 500;
static int TILE_SIZE = 256;

@implementation OAMapSelectionHelper
{
    NSArray<OAMapLayer *> *_pointLayers;
    OAClickableWayHelper *_clickableWayHelper;
    NSArray<NSString *> *_publicTransportTypes;
    id _provider;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _clickableWayHelper = [[OAClickableWayHelper alloc] init];
        _provider = OARootViewController.instance.mapPanel.mapViewController.mapLayers.poiLayer;
    }
    return self;
}

- (MapSelectionResult *)collectObjectsFromMap:(CGPoint)point showUnknownLocation:(BOOL)showUnknownLocation
{
    if (!_provider)
        _provider = OARootViewController.instance.mapPanel.mapViewController.mapLayers.poiLayer;
    
    MapSelectionResult *result = [[MapSelectionResult alloc] initWithPoint:point];
    [self collectObjectsFromLayers:result unknownLocation:showUnknownLocation secondaryObjects:NO];
    [self collectObjectsFromMap:result point:point];
    
    if ([result isEmpty])
        [self collectObjectsFromLayers:result unknownLocation:showUnknownLocation secondaryObjects:YES];
    
    [result groupByOsmIdAndWikidataId];
    return result;
}

- (void)collectObjectsFromMap:(MapSelectionResult *)result point:(CGPoint)point
{
    [self selectObjectsFromOpenGl:result point:point];
}

- (void)collectObjectsFromLayers:(MapSelectionResult *)result unknownLocation:(BOOL)unknownLocation secondaryObjects:(BOOL)secondaryObjects
{
    OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
    
    NSArray<OAMapLayer *> *layers = [mapViewController.mapLayers getLayers];
    
    for (OAMapLayer *layer in layers)
    {
        // Android doesn't have that layer here
        if ([layer isKindOfClass:OAGPXRecLayer.class])
            continue;
        
        if ([layer conformsToProtocol:@protocol(OAContextMenuProvider)])
        {
            id<OAContextMenuProvider> provider = (id<OAContextMenuProvider>)layer;
            
            if (![provider isSecondaryProvider] || secondaryObjects)
            {
                if ([provider respondsToSelector:@selector(collectObjectsFromPoint:unknownLocation:excludeUntouchableObjects:)])
                {
                    [provider collectObjectsFromPoint:result unknownLocation:unknownLocation excludeUntouchableObjects:NO];
                }
            }
        }
    }
}

- (void)selectObjectsFromOpenGl:(MapSelectionResult *)result point:(CGPoint)point
{
    OAMapViewController *mapVc = OARootViewController.instance.mapPanel.mapViewController;
    OAMapRendererView *rendererView = (OAMapRendererView *) mapVc.view;
    
    if (rendererView)
    {
        int delta = 20;
        OsmAnd::PointI tl = OsmAnd::PointI(point.x - delta, point.y - delta);
        OsmAnd::PointI br = OsmAnd::PointI(point.x + delta, point.y + delta);
        OsmAnd::AreaI area(tl, br);
        
        const auto& symbols = [rendererView getSymbolsIn:area strict:NO];
        OAAmenitySearcher *amenitySearcher = [[OAAmenitySearcher alloc] init];

        for (const auto symbolInfo : symbols)
        {
            if (symbolInfo.mapSymbol->ignoreClick)
                continue;
            
            std::shared_ptr<const OsmAnd::Amenity> cppAmenity;
            BaseDetailsObject *detailsObject;
            
            if (const auto billboardMapSymbol = std::dynamic_pointer_cast<const OsmAnd::IBillboardMapSymbol>(symbolInfo.mapSymbol))
            {
                double lat = OsmAnd::Utilities::get31LatitudeY(billboardMapSymbol->getPosition31().y);
                double lon = OsmAnd::Utilities::get31LongitudeX(billboardMapSymbol->getPosition31().x);
                result.objectLatLon = [[CLLocation alloc] initWithLatitude:lat longitude:lon];

                if (const auto billboardAdditionalParams = std::dynamic_pointer_cast<const OsmAnd::MapSymbolsGroup::AdditionalBillboardSymbolInstanceParameters>(symbolInfo.instanceParameters))
                {
                    if (billboardAdditionalParams->overridesPosition31)
                    {
                        lon = OsmAnd::Utilities::get31LongitudeX(billboardAdditionalParams->position31.x);
                        lat = OsmAnd::Utilities::get31LatitudeY(billboardAdditionalParams->position31.y);
                        result.objectLatLon = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
                    }
                }
                
                if (const auto amenitySymbolGroup = dynamic_cast<OsmAnd::AmenitySymbolsProvider::AmenitySymbolsGroup*>(symbolInfo.mapSymbol->groupPtr))
                {
                    cppAmenity = amenitySymbolGroup->amenity;
                }
            }
            else
            {
                CLLocation *clickLatLon = [mapVc getLatLonFromElevatedPixel:point.x y:point.y];
                result.objectLatLon = [self snapLatLonToWayGeometry:clickLatLon mapSymbol:symbolInfo.mapSymbol];
            }
            
            if (cppAmenity != nullptr)
            {
                NSMutableArray<NSString *> *names = [NSMutableArray new];
                for (const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(cppAmenity->localizedNames)))
                {
                    NSString *name = entry.value().toNSString();
                    if (name)
                        [names addObject:name];
                }
                
                NSString *nativeName = cppAmenity->nativeName.toNSString();
                if (nativeName)
                    [names addObject:nativeName];
                
                OAPOI *requestAmenity = [[OAPOI alloc] init];
                requestAmenity.obfId = cppAmenity->id.id;
                [requestAmenity setLatitude:result.objectLatLon.coordinate.latitude];
                [requestAmenity setLongitude:result.objectLatLon.coordinate.longitude];
                
                OAAmenitySearcherRequest *request = [[OAAmenitySearcherRequest alloc] initWithMapObject:requestAmenity names:[names copy]];
                detailsObject = [amenitySearcher searchDetailedObjectWithRequest:request];
            }
            else
            {
                if (const auto mapObjectSymbolsGroup = dynamic_cast<OsmAnd::MapObjectsSymbolsProvider::MapObjectSymbolsGroup*>(symbolInfo.mapSymbol->groupPtr))
                {
                    if (const auto& obfMapObject = std::dynamic_pointer_cast<const OsmAnd::ObfMapObject>(mapObjectSymbolsGroup->mapObject))
                    {
                        MutableOrderedDictionary<NSString *,NSString *> *tags = [self getOrderedTags:obfMapObject->getResolvedAttributesListPairs()];
                        
                        BOOL isTravelGpx = [OATravelObfHelper.shared isTravelGpxTags:tags];
                        BOOL isOldOsmRoute = !OsmAnd::NetworkRouteKey::getRouteKeys([self toQHash:tags]).isEmpty();
                        BOOL isClickableWay = [_clickableWayHelper isClickableWay:obfMapObject tags:tags];

                        NSString *routeId = tags[ROUTE_ID];
                        BOOL isNewOsmRoute = [self.class isNewOsmRoute:routeId isTravelGpx:isTravelGpx];
                        CLLocation *objectLatLon = result.objectLatLon;

                        if (isNewOsmRoute || isOldOsmRoute)
                        {
                            [self addFilteredOsmRoutes:result location:objectLatLon];
                        }

                        if (isClickableWay)
                        {
                            ClickableWay *clickableWay = [_clickableWayHelper loadClickableWay:objectLatLon obfMapObject:obfMapObject tags:tags];
                            [self addClickableWay:result clickableWay:clickableWay];
                        }

                        if (isTravelGpx && !isNewOsmRoute)
                        {
                            [self addTravelGpx:result routeId:routeId location:objectLatLon]; // WikiVoyage or User TravelGpx
                        }

                        auto onPathMapSymbol =
                            std::dynamic_pointer_cast<const OsmAnd::IOnPathMapSymbol>(symbolInfo.mapSymbol);
                        BOOL allowMapObjects = onPathMapSymbol == nullptr &&
                            !OsmAnd::NetworkRouteKey::containsUnclickableRouteTags([self toQHash:tags]);

                        if (allowMapObjects)
                        {
                            OARenderedObject *renderedObject =
                                [self createRenderedObject:symbolInfo obfMapObject:obfMapObject tags:tags];
                            if (renderedObject)
                            {
                                [result collect:renderedObject provider:nil];
                            }
                        }
                    }
                }
            }
            
            if (detailsObject && ![self isTransportStop:result.allObjects detail:detailsObject])
            {
                [result collect:detailsObject provider:_provider];
            }
        }
    }
}

- (CLLocation *)parsePoiLatLon:(NSString *)value
{
    if (!value)
        return nil;
    
    OASKGeoParsedPoint *p = [OASKMapUtils.shared decodeShortLinkStringS:value];
    return [[CLLocation alloc] initWithLatitude:p.getLatitude longitude:p.getLongitude];
}

- (const shared_ptr<const OsmAnd::BillboardRasterMapSymbol>)getRasterMapSymbolWithSymbolInfo:(OsmAnd::IMapRenderer::MapSymbolInformation)symbolInfo
{
    return [self getRasterMapSymbol:symbolInfo.mapSymbol];
}

- (const shared_ptr<const OsmAnd::BillboardRasterMapSymbol>)getRasterMapSymbol:(shared_ptr<const OsmAnd::MapSymbol>)mapSymbol
{
    if (const auto rasterMapSymbol = std::static_pointer_cast<const OsmAnd::BillboardRasterMapSymbol>(mapSymbol))
    {
        return rasterMapSymbol;
    }
    return nullptr;
}

- (OARenderedObject *)createRenderedObject:(OsmAnd::IMapRenderer::MapSymbolInformation)symbolInfo obfMapObject:(const std::shared_ptr<const OsmAnd::MapObject>)obfMapObject tags:(MutableOrderedDictionary<NSString *,NSString *> *)tags
{
    const auto rasterMapSymbol = [self getRasterMapSymbolWithSymbolInfo:symbolInfo];
    if (rasterMapSymbol != nullptr)
    {
        const auto group = rasterMapSymbol->groupPtr;
        const auto symbolIcon = [self getRasterMapSymbol:group->getFirstSymbolWithContentClass(OsmAnd::RasterMapSymbol::ContentClass::Icon)];
        const auto symbolCaption = [self getRasterMapSymbol:group->getFirstSymbolWithContentClass(OsmAnd::RasterMapSymbol::ContentClass::Caption)];
        
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
        
        if (symbolIcon != nullptr)
        {
            [renderedObject setIconRes:symbolIcon->content.toNSString()];
        }
        if (symbolCaption != nullptr)
        {
            [renderedObject setName:symbolCaption->content.toNSString()];
        }
        for (NSString *key in tags)
        {
            renderedObject.tags[key] = tags[key];
        }
        return renderedObject;
    }
    return nil;
}

- (OAPOI *)getAmenity:(CLLocation *)latLon obfMapObject:(const std::shared_ptr<const OsmAnd::MapObject>)obfMapObject tags:(MutableOrderedDictionary<NSString *,NSString *> *)tags
{
    NSMutableArray<NSString *> *names = [self getValues:obfMapObject->getCaptionsInAllLanguages()];
    NSString *caption = obfMapObject->getCaptionInNativeLanguage().toNSString();
    if (!NSStringIsEmpty(caption))
        [names addObject:caption];
    
    if (!NSDictionaryIsEmpty(tags) && tags[OATravelGpx.TRAVEL_MAP_TO_POI_TAG] && [tags[ROUTE_TAG] isEqualToString:@"point"])
    {
        [names addObject:tags[OATravelGpx.TRAVEL_MAP_TO_POI_TAG]]; // additional attribute for TravelGpx points (route_id)
    }
    
    uint64_t obfId = [OAMapObject getInvalidObfId];
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

- (void)addTravelGpx:(MapSelectionResult *)result routeId:(NSString *)routeId location:(CLLocation *)location
{
    OATravelGpx *travelGpx = [OATravelObfHelper.shared searchTravelGpxWithLocation:location routeId:routeId];
    if (travelGpx)
        [self collectTravelGpx:result travelGpx:travelGpx location:location];
    else
        NSLog(@"addTravelGpx() searchTravelGpx() travelGpx is null");
}

/// The OSM routes drawn under the tap, of the types the style has switched on. A route answers by
/// its own amenity in the poi section, so there is nothing left to assemble from relations here.
- (void)addFilteredOsmRoutes:(MapSelectionResult *)result location:(CLLocation *)location
{
    NSSet<NSString *> *routeTypeNames = [self createRouteTypesFilter];
    if (routeTypeNames.count == 0)
        return;

    NSArray<OATravelGpx *> *found = [OATravelObfHelper.shared searchTravelGpxWithLocation:location osmRouteTypeNames:routeTypeNames];
    for (OATravelGpx *travelGpx in found)
    {
        [self collectTravelGpx:result travelGpx:travelGpx location:location];
    }
}

- (void)collectTravelGpx:(MapSelectionResult *)result travelGpx:(OATravelGpx *)travelGpx location:(CLLocation *)location
{
    if (![self isUniqueTravelGpx:result.allObjects travelGpx:travelGpx])
        return;

    OASWptPt *selectedPoint = [[OASWptPt alloc] initWithLat:location.coordinate.latitude lon:location.coordinate.longitude];
    SelectedGpxPoint *selectedGpxPoint = [[SelectedGpxPoint alloc] initWithSelectedGpxFile:nil selectedPoint:selectedPoint];

    OAMapViewController *mapVc = OARootViewController.instance.mapPanel.mapViewController;
    OATravelSelectionLayer *provider = mapVc.mapLayers.travelSelectionLayer;

    [result collect:@[travelGpx, selectedGpxPoint] provider:provider];
}

/// Whether tapping this route should look for a track at all: a v2 route carries its OSM id in
/// `route_id`, and it is the poi section, not the relation, that answers for it.
+ (BOOL)isNewOsmRoute:(NSString *)routeId isTravelGpx:(BOOL)isTravelGpx
{
    if (!isTravelGpx || routeId == nil)
        return NO;

    return [OASObfConstants.shared getOsmIdFromPrefixedRouteIdRouteId:routeId] > 0;
}

/// The way's vertex nearest the tap. The route search looks 25 m around the point it is given, and
/// a tap lands beside the line, not on it.
- (CLLocation *)snapLatLonToWayGeometry:(CLLocation *)location mapSymbol:(const std::shared_ptr<const OsmAnd::MapSymbol> &)mapSymbol
{
    const auto mapObjectSymbolsGroup = dynamic_cast<OsmAnd::MapObjectsSymbolsProvider::MapObjectSymbolsGroup*>(mapSymbol->groupPtr);
    if (!mapObjectSymbolsGroup)
        return location;

    const auto& obfMapObject = std::dynamic_pointer_cast<const OsmAnd::ObfMapObject>(mapObjectSymbolsGroup->mapObject);
    if (!obfMapObject)
        return location;

    CLLocation *snapped = location;
    double minDist = DBL_MAX;
    for (const auto& point31 : OsmAnd::constOf(obfMapObject->points31))
    {
        double lat = OsmAnd::Utilities::get31LatitudeY(point31.y);
        double lon = OsmAnd::Utilities::get31LongitudeX(point31.x);
        double dist = OsmAnd::Utilities::distance(location.coordinate.longitude, location.coordinate.latitude, lon, lat);
        if (dist < minDist)
        {
            minDist = dist;
            snapped = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
        }
    }
    return snapped;
}

- (BOOL)addClickableWay:(MapSelectionResult *)result clickableWay:(ClickableWay *)clickableWay
{
    if (clickableWay && [self isUniqueClickableWay:result.allObjects clickableWay:clickableWay])
    {
        [result collect:clickableWay provider:[_clickableWayHelper getContextMenuProvider]];
        return YES;
    }
    return NO;
}

- (BOOL)isUniqueGpxFileName:(NSMutableArray<SelectedMapObject *> *)selectedObjects gpxFileName:(NSString *)gpxFileName
{
    for (SelectedMapObject *selectedObject in selectedObjects)
    {
        id object = selectedObject.object;
        if ([object isKindOfClass:SelectedGpxPoint.class] && [selectedObject.provider isKindOfClass:OAGPXLayer.class])
        {
            SelectedGpxPoint *gpxPoint = (SelectedGpxPoint *)object;
            if ([[gpxPoint.selectedGpxFile path] hasSuffix:gpxFileName])
            {
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)isUniqueClickableWay:(NSMutableArray<SelectedMapObject *> *)selectedObjects clickableWay:(ClickableWay *)clickableWay
{
    for (SelectedMapObject *selectedObject in selectedObjects)
    {
        if ([selectedObject.object isKindOfClass:OAPOI.class] &&
            [self haveSameActivityType:(OAPOI *)selectedObject.object clickableWay:clickableWay])
        {
            return NO; // skip if same-kind-of OSM route(s) found before
        }
        if ([selectedObject.object isKindOfClass:OAPOI.class] &&
            clickableWay.osmId == [((OAPOI *) selectedObject.object) getOsmId])
        {
            return NO; // skip if ClickableWayAmenity is selected
        }
        if ([selectedObject.object isKindOfClass:ClickableWay.class] &&
            clickableWay.osmId == ((ClickableWay *) selectedObject.object).osmId)
        {
            return NO;
        }
    }
 
    NSString *gpxFileName = [[clickableWay getGpxFileName] stringByAppendingPathExtension:GPX_FILE_EXT];
    return [self isUniqueGpxFileName:selectedObjects gpxFileName:gpxFileName];
}

- (BOOL)haveSameActivityType:(OAPOI *)amenity clickableWay:(ClickableWay *)clickableWay
{
    NSString *gpxActivityType = [clickableWay.gpxFile getExtensionsToRead][[OASGpxUtilities.shared ACTIVITY_TYPE]];
    if (gpxActivityType) {
        NSString *amenityActivityType = amenity.getAdditionalInfo[[NSString stringWithFormat:@"%@_%@",
                                                                   OATravelGpx.ROUTE_ACTIVITY_TYPE, gpxActivityType]];
        return [gpxActivityType isEqualToString:amenityActivityType];
    }
    return NO;
}

- (BOOL)isUniqueTravelGpx:(NSMutableArray<SelectedMapObject *> *)selectedObjects travelGpx:(OATravelGpx *)travelGpx
{
    if (selectedObjects.count == 0)
        return YES;
    
    for (SelectedMapObject *selectedObject in selectedObjects)
    {
        if ([selectedObject.object isKindOfClass:NSArray.class] &&
            ([selectedObject.provider isKindOfClass:OAGPXLayer.class] || [selectedObject.provider isKindOfClass:OATravelSelectionLayer.class]))
        {
            NSArray *pair = (NSArray *)selectedObject.object;
            id firstOblect = [pair firstObject];
            if ([firstOblect isKindOfClass:OATravelGpx.class])
            {
                OATravelGpx *gpx = firstOblect;
                if ([travelGpx equalsWithObj:gpx])
                {
                    return NO;
                }
            }
        }
    }
    
    NSString *gpxFileName = [[travelGpx getGpxFileName] stringByAppendingString:GPX_FILE_EXT];
    return [self isUniqueGpxFileName:selectedObjects gpxFileName:gpxFileName];
}

/// The osm route types the style is drawing right now. A route type switched off in Configure map
/// must not answer a tap, so the click search is given the enabled ones by name.
- (NSSet<NSString *> *)createRouteTypesFilter
{
    NSMutableSet<NSString *> *routeTypeNames = [NSMutableSet set];

    OAMapStyleSettings *styleSettings = [OAMapStyleSettings sharedInstance];
    for (OAMapStyleParameter *param in [styleSettings getAllParameters])
    {
        QString attrName = QString::fromNSString(param.name);
        const auto osmRouteType = OsmAnd::OsmRouteType::getByRenderingPropertyAttr(attrName);
        if (osmRouteType != nullptr)
        {
            BOOL isEnabled;
            NSString *storedValue = [param storedValue];
            if (attrName == OsmAnd::OsmRouteType::HIKING->renderingPropertyAttr)
            {
                isEnabled = !NSStringIsEmpty(storedValue) && ![storedValue isEqualToString:@"disabled"];
            }
            else
            {
                isEnabled = !NSStringIsEmpty(storedValue) && [storedValue isEqualToString:@"true"];
            }
            if (isEnabled)
            {
                [routeTypeNames addObject:osmRouteType->name.toNSString()];
            }
        }
    }
    return routeTypeNames;
}

- (BOOL)isTransportStop:(NSArray<SelectedMapObject *> *)selectedObjects detail:(BaseDetailsObject *)detail
{
    for (SelectedMapObject *selectedObject in selectedObjects)
    {
        if ([selectedObject.object isKindOfClass:OATransportStop.class])
        {
            OATransportStop *stop = selectedObject.object;
            OAPOI *detailSyntheticAmenity = [detail syntheticAmenity];
            if ([stop.name hasPrefix:detailSyntheticAmenity.name])
                return YES;
        }
    }
    return NO;
}

- (NSArray<NSString *> *)getPublicTransportTypes
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
            _publicTransportTypes = [publicTransportTypes copy];
        }
    }
    return _publicTransportTypes;
}

- (NSMutableArray<NSString *> *)getValues:(QHash<QString, QString>)set
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

- (MutableOrderedDictionary<NSString *, NSString *> *)getOrderedTags:(QList<QPair<QString, QString>>)tagsList
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

+ (OAPOI *)findAmenity:(CLLocation *)latLon names:(NSArray<NSString *> *)names obfId:(uint64_t)obfId
{
    int searchRadius = [ObfConstants isIdFromRelation:obfId >> AMENITY_ID_RIGHT_SHIFT] ?
        AMENITY_SEARCH_RADIUS_FOR_RELATION :
        AMENITY_SEARCH_RADIUS;
    
    return [self findAmenity:latLon names:names obfId:obfId radius:searchRadius];
}

+ (OAPOI *)findAmenity:(CLLocation *)latLon names:(NSArray<NSString *> *)names obfId:(uint64_t)obfId radius:(int)radius
{
    uint64_t osmId = [ObfConstants getOsmId:obfId >> AMENITY_ID_RIGHT_SHIFT];
    OsmAnd::PointI point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(latLon.coordinate.latitude, latLon.coordinate.longitude));
    OsmAnd::AreaI rect = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(radius, point31);
    
    BOOL (^nilBlock)(OAPOI *poi) = nil;
    NSArray<OAPOI *> *amenities = [OAAmenitySearcher findPOI:OASearchPoiTypeFilter.acceptAllPoiTypeFilter additionalFilter:nil bbox31:rect currentLocation:point31 includeTravel:YES matcher:nil publish:nilBlock];
    OAPOI *amenity = [self findAmenityByOsmId:amenities obfId:osmId point:latLon];
    
    if (!amenity && names.count > 0)
    {
        amenity = [self findAmenityByName:amenities names:names];
    }
    return amenity;
}

+ (NSArray<OAPOI *> *)findAmenities:(CLLocation *)latLon
{
    OsmAnd::PointI point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(latLon.coordinate.latitude, latLon.coordinate.longitude));
    OsmAnd::AreaI rect = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(AMENITY_SEARCH_RADIUS, point31);
    BOOL (^nilBlock)(OAPOI *poi) = nil;
    return [OAAmenitySearcher findPOI:[OASearchPoiTypeFilter acceptAllPoiTypeFilter] additionalFilter:nil bbox31:rect currentLocation:point31 includeTravel:YES matcher:nil publish:nilBlock];
}

+ (OAPOI *)findAmenityByOsmId:(CLLocation *)latLon obfId:(uint64_t)obfId
{
    NSArray<OAPOI *> *amenities = [self findAmenities:latLon];
    return [self findAmenityByOsmId:amenities obfId:obfId point:latLon];
}

+ (OAPOI *)findAmenityByOsmId:(NSArray<OAPOI *> *)amenities obfId:(uint64_t)obfId point:(CLLocation *)point
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

+ (OAPOI *)findAmenityByName:(NSArray<OAPOI *> *)amenities names:(NSArray<NSString *> *)names
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

/// Opens a track found by search or reopened from history straight in the track menu, the way a
/// tap on the map does. Anything else goes on to the ordinary poi menu.
- (BOOL)showContextMenuForSearchResult:(OAPOI *)poi
{
    if ([poi isRouteTrack] && ![poi isSuperRoute])
    {
        OATravelGpx *travelGpx = [[OATravelGpx alloc] initWithAmenity:poi];
        [OATravelObfHelper.shared openTrackMenuWithArticle:travelGpx
                                               gpxFileName:[poi getGpxFileName:nil]
                                                    latLon:[poi getLocation]
                                         adjustMapPosition:YES];
        return YES;
    }

    if ([_clickableWayHelper isClickableWayAmenity:poi])
    {
        [ClickableWayHelper openClickableWayAmenityWithAmenity:poi adjustMapPosition:YES];
        return YES;
    }

    return NO;
}

- (QHash<QString, QString>)toQHash:(NSDictionary<NSString *, NSString *> *) dict
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
