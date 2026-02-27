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
#import "OARouteKey.h"
#import "OARouteKey+cpp.h" 
#import "OATravelGuidesHelper+cpp.h"
#import "OAClickableWayMenuProvider.h"
#import "OATravelSelectionLayer.h"
#import "OAAmenitySearcher.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Map/AmenitySymbolsProvider.h>
#include <OsmAndCore/Map/BillboardRasterMapSymbol.h>
#include <OsmAndCore/NetworkRouteSelector.h>
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
        if ([layer isKindOfClass:OAOsmBugsLayer.class] ||
            [layer isKindOfClass:OAGPXRecLayer.class])
            continue;
        
        if ([layer conformsToProtocol:@protocol(OAContextMenuProvider)])
        {
            id<OAContextMenuProvider> provider = ((id<OAContextMenuProvider>)layer);
            
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
        int index = 0;
        for (const auto symbolInfo : symbols)
        {
            NSLog(@"%d", index);
            index++;
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
                
                auto* groupPtr = symbolInfo.mapSymbol->groupPtr;
                NSLog(@"groupPtr type: %s", typeid(*groupPtr).name()); // N6OsmAnd22AmenitySymbolsProvider19AmenitySymbolsGroupE || N6OsmAnd9MapMarker12SymbolsGroupE
                
                if (const auto amenitySymbolGroup = dynamic_cast<OsmAnd::AmenitySymbolsProvider::AmenitySymbolsGroup*>(symbolInfo.mapSymbol->groupPtr))
                {
                    cppAmenity = amenitySymbolGroup->amenity;
                }
            }
            else
            {
                result.objectLatLon = [mapVc getLatLonFromElevatedPixel:point.x y:point.y];
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
     
                        BOOL isNewOsmRoute = false; // TODO implement new OSM routes

                        if (isTravelGpx) {
                            NSString *routeId = tags[@"route_id"];
                            if (routeId != nil && [routeId hasPrefix:@"O"]) {
                                if (false) {
                                    isNewOsmRoute = true;
                                } else {
                                    // TODO unhack me
                                    isTravelGpx = false;
                                    isOldOsmRoute = true;
                                    isNewOsmRoute = false;
                                }
                            }
                        }

                      //  BOOL isSpecial = isOldOsmRoute || isNewOsmRoute || isTravelGpx || isClickableWay;

                        if (isOldOsmRoute)
                        {
                            const auto selectorFilter = [self createRouteFilter];
                            [self addOsmRoutesAround:result point:point selectorFilter:selectorFilter];
                        }

                        if (isClickableWay)
                        {
                            ClickableWay *clickableWay = [_clickableWayHelper loadClickableWay:result.pointLatLon obfMapObject:obfMapObject tags:tags];
                            [self addClickableWay:result clickableWay:clickableWay];
                        }

                        if (isTravelGpx && !isNewOsmRoute)
                        {
                            [self addTravelGpx:result routeId: tags[ROUTE_ID]]; // WikiVoyage or User TravelGpx
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

- (void)addTravelGpx:(MapSelectionResult *)result routeId:(NSString *)routeId
{
    OATravelGpx *travelGpx = [OATravelGuidesHelper searchTravelGpx:result.pointLatLon routeId:routeId];
    if (travelGpx && [self isUniqueTravelGpx:result.allObjects travelGpx:travelGpx])
    {
        OASWptPt *selectedPoint = [[OASWptPt alloc] initWithLat:result.pointLatLon.coordinate.latitude lon:result.pointLatLon.coordinate.longitude];
        SelectedGpxPoint *selectedGpxPoint = [[SelectedGpxPoint alloc] initWithSelectedGpxFile:nil selectedPoint:selectedPoint];
        
        OAMapViewController *mapVc = OARootViewController.instance.mapPanel.mapViewController;
        OATravelSelectionLayer *provider = mapVc.mapLayers.travelSelectionLayer;

        [result collect:@[travelGpx, selectedGpxPoint] provider:provider];
    }
    else if (!travelGpx)
    {
        NSLog(@"addTravelGpx() searchTravelGpx() travelGpx is null");
    }
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

- (BOOL)addOsmRoutesAround:(MapSelectionResult *)result point:(CGPoint)point selectorFilter:(OsmAnd::NetworkRouteSelectorFilter *)selectorFilter
{
    if (selectorFilter != nullptr && selectorFilter->typeFilter.isEmpty())
    {
        return NO;
    }
    
    OAMapViewController *mapVc = OARootViewController.instance.mapPanel.mapViewController;
    OANetworkRouteSelectionLayer *networkRouteSelectionLayer = mapVc.mapLayers.networkRouteSelectionLayer;
    int searchRadius = [networkRouteSelectionLayer getScaledTouchRadius:[networkRouteSelectionLayer getDefaultRadiusPoi]] * TOUCH_RADIUS_MULTIPLIER;
    CLLocation *minLatLon = [mapVc getLatLonFromElevatedPixel:point.x - searchRadius y:point.y - searchRadius];
    CLLocation *maxLatLon = [mapVc getLatLonFromElevatedPixel:point.x + searchRadius y:point.y + searchRadius];
    OASKQuadRect *rect = [[OASKQuadRect alloc] initWithLeft:minLatLon.coordinate.longitude top:minLatLon.coordinate.latitude right:maxLatLon.coordinate.longitude bottom:maxLatLon.coordinate.latitude];
    
    return [self putRouteGpxToSelected:result provider:networkRouteSelectionLayer rect:rect selectorFilter:selectorFilter];
}

- (OsmAnd::NetworkRouteSelectorFilter *) createRouteFilter
{
    const auto routeSelectorFilter = new OsmAnd::NetworkRouteSelectorFilter();
    
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
                routeSelectorFilter->typeFilter.insert(*osmRouteType);
            }
        }
    }
    return routeSelectorFilter;
}

- (BOOL)putRouteGpxToSelected:(MapSelectionResult *)result provider:(id<OAContextMenuProvider>)provider rect:(OASKQuadRect *)rect selectorFilter:(OsmAnd::NetworkRouteSelectorFilter *)selectorFilter
{
    OsmAnd::PointI topLeft31 = [OANativeUtilities getPoint31FromLatLon:OsmAnd::LatLon(rect.top, rect.left)];
    OsmAnd::PointI bottomRight31 = [OANativeUtilities getPoint31FromLatLon:OsmAnd::LatLon(rect.bottom, rect.right)];
    OsmAnd::AreaI area31(topLeft31, bottomRight31);
    
    int added = 0;
    auto networkRouteSelector = std::make_shared<OsmAnd::NetworkRouteSelector>([OsmAndApp instance].resourcesManager->obfsCollection);
    if (selectorFilter != nullptr)
    {
        networkRouteSelector->rCtx->setNetworkFilter(*selectorFilter);
    }
    
    auto routes = networkRouteSelector->getRoutes(area31, false, nullptr);
    
    for (auto it = routes.begin(); it != routes.end(); ++it)
    {
        OARouteKey *routeKey = [[OARouteKey alloc] initWithKey:it.key()];
        if ([self isUniqueOsmRoute:result tmpKey:routeKey])
        {
            NSArray *pair = @[routeKey, rect];
            [result collect:pair provider:provider];
            added++;
        }
    }
    return added > 0;
}

- (BOOL)isUniqueOsmRoute:(MapSelectionResult *)result tmpKey:(OARouteKey *)tmpKey
{
    for (SelectedMapObject *selectedObject in result.allObjects)
    {
        id object = selectedObject.object;
        if ([object isKindOfClass:NSArray.class])
        {
            id firstObject = [((NSArray *) object) firstObject];
            if (firstObject && [firstObject isKindOfClass:OARouteKey.class] && [firstObject isEqual:tmpKey])
            {
                return NO;
            }
        }
    }
    return YES;
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

- (BOOL)showContextMenuForSearchResult:(OAPOI *)poi filename:(NSString *)filename
{
    // The method is used to handle new->old OSM routes from search results.
    // After implementing new OSM routes scheme, this method will be refactored.

    BOOL canBeRoute = [poi isRouteTrack] || !NSStringIsEmpty(poi.values[@"ref"]) || !NSStringIsEmpty(poi.values[@"route_id"]);
    if (!canBeRoute)
        return NO;
    
    MapSelectionResult *result = [[MapSelectionResult alloc] initWithPoint:CGPointMake(0, 0)];
    CLLocation *latLon = [poi getLocation];
    result.objectLatLon = latLon;
    
    OATravelGpx *travelGpx = [[OATravelGpx alloc] initWithAmenity:poi];
    NSString *trackName = [poi getGpxFileName:nil];
    if (filename)
    {
        travelGpx.file = filename;
        if (![travelGpx.file hasSuffix:@".obf"])
            [travelGpx.file stringByAppendingPathExtension:@"obf"];
    }
    OsmAnd::AreaI bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(50, OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(latLon.coordinate.latitude, latLon.coordinate.longitude)));
    
    const auto foundBinaryMapObjects = [OATravelGuidesHelper searchGpxMapObject:travelGpx bbox31:bbox31 reader:nil useAllObfFiles:YES];
    
    BOOL osmRoutesAlreadyAdded = NO;
    for (const auto obfMapObject : foundBinaryMapObjects)
    {
        MutableOrderedDictionary<NSString *,NSString *> *tags = [self getOrderedTags:obfMapObject->getResolvedAttributesListPairs()];
        BOOL isOsmRoute = !OsmAnd::NetworkRouteKey::getRouteKeys([self toQHash:tags]).isEmpty();
        BOOL isClickableWay = [_clickableWayHelper isClickableWay:obfMapObject tags:tags];
        
        if (isClickableWay)
        {
            [ClickableWayHelper openClickableWayAmenityWithAmenity:poi adjustMapPosition:YES];
            return YES;
        }
        if (isOsmRoute || !osmRoutesAlreadyAdded)
        {
            OAMapViewController *mapVc = OARootViewController.instance.mapPanel.mapViewController;
            OANetworkRouteSelectionLayer *networkRouteSelectionLayer = mapVc.mapLayers.networkRouteSelectionLayer;
            int searchRadius = [networkRouteSelectionLayer getScaledTouchRadius:[networkRouteSelectionLayer getDefaultRadiusPoi]] * TOUCH_RADIUS_MULTIPLIER;
            OsmAnd::PointI point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(latLon.coordinate.latitude, latLon.coordinate.longitude));
            OsmAnd::AreaI rect31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(AMENITY_SEARCH_RADIUS, point31);
            OsmAnd::Utilities::get31LatitudeY(rect31.top());
            OASKQuadRect *rect = [[OASKQuadRect alloc] initWithLeft:OsmAnd::Utilities::get31LongitudeX(rect31.left()) top:OsmAnd::Utilities::get31LatitudeY(rect31.top()) right:OsmAnd::Utilities::get31LongitudeX(rect31.right()) bottom:OsmAnd::Utilities::get31LatitudeY(rect31.bottom())];
    
            osmRoutesAlreadyAdded = [self putRouteGpxToSelected:result provider:networkRouteSelectionLayer rect:rect selectorFilter:nil];
        }
    }
    
    [result groupByOsmIdAndWikidataId];
    NSMutableArray<SelectedMapObject *> *selectedObjects = [result getProcessedObjects];
    
    if ([selectedObjects count] > 0)
    {
        NSString *poiName = [poi.name lowercaseString];
        for (SelectedMapObject *selectedObject in selectedObjects)
        {
            if ([selectedObject.object isKindOfClass:NSArray.class])
            {
                OARouteKey *routeKey = selectedObject.object[0];
                NSString *name = [[routeKey getRouteName] lowercaseString];
                if ([poiName isEqualToString:name])
                {
                    [selectedObject.provider showMenuAction:selectedObject];
                    return YES;
                }
            }
        }
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
