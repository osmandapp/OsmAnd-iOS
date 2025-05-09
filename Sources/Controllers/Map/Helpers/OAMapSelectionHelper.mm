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
#import "OAContextMenuProvider.h"
#import "OAMapObject.h"
#import "OAPOI.h"
#import "OAClickableWay.h"
#import "OAClickableWayHelper.h"
#import "OAClickableWayHelper+cpp.h"
#import "OsmAnd_Maps-Swift.h"


//TODO: delete unnecessary imports
#include "OACoreResourcesAmenityIconProvider.h"
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Map/AmenitySymbolsProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/Map/BillboardRasterMapSymbol.h>
#include <OsmAndCore/Map/IOnPathMapSymbol.h>
#include <OsmAndCore/NetworkRouteContext.h>
#include <OsmAndCore/NetworkRouteSelector.h>


static int AMENITY_SEARCH_RADIUS = 50;
static int AMENITY_SEARCH_RADIUS_FOR_RELATION = 500;
static int TILE_SIZE = 256;

static NSString *TAG_POI_LAT_LON = @"osmand_poi_lat_lon";

@implementation OAMapSelectionHelper
{
    NSArray<OAMapLayer *> *_pointLayers;
    OAClickableWayHelper *_clickableWayHelper;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _clickableWayHelper = [[OAClickableWayHelper alloc] init];
    }
    return self;
}

//public Map<LatLon, BackgroundType> getTouchedFullMapObjects()
//public Map<LatLon, BackgroundType> getTouchedSmallMapObjects()
//public boolean hasTouchedMapObjects()
//public void clearTouchedMapObjects()


- (OAMapSelectionResult *) collectObjectsFromMap:(CGPoint)point showUnknownLocation:(BOOL)showUnknownLocation
{
    OAMapSelectionResult *result = [[OAMapSelectionResult alloc] initWithPoint:point];
    [self collectObjectsFromLayers:result unknownLocation:showUnknownLocation secondaryObjects:NO];
    [self collectObjectsFromMap:result point:point];
    
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
//    //TODO: delete after test?
//    NSMutableArray<OATargetPoint *> *found = [NSMutableArray array];
//    
//    
//    OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
//    
//    //TODO: is it correct? maybe we chould iterate over all layers?
//    if (!_pointLayers)
//    {
//        _pointLayers = @[mapViewController.mapLayers.myPositionLayer,
//                         mapViewController.mapLayers.mapillaryLayer,
//                         mapViewController.mapLayers.downloadedRegionsLayer,
//                         mapViewController.mapLayers.gpxMapLayer];
//    }
//    for (OAMapLayer *layer in _pointLayers)
//    {
//        if ([layer conformsToProtocol:@protocol(OAContextMenuProvider)])
//        {
//            id<OAContextMenuProvider> provider = ((id<OAContextMenuProvider>)layer);
//            
////            [provider collectObjectsFromPoint:<#(CLLocationCoordinate2D)#> touchPoint:<#(CGPoint)#> symbolInfo:<#(const OsmAnd::IMapRenderer::MapSymbolInformation *)#> found:<#(NSMutableArray<OATargetPoint *> *)#> unknownLocation:<#(BOOL)#>];
////            
////            [((id<OAContextMenuProvider>)layer) collectObjectsFromPoint:coord touchPoint:touchPoint symbolInfo:nil found:found unknownLocation:showUnknownLocation];
//        }
//    }
//    
    
    //TODO: implement
}



// public void acquireTouchedMapObjects(@NonNull RotatedTileBox tileBox, @NonNull PointF point, boolean unknownLocation)



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
                double lon = OsmAnd::Utilities::get31LongitudeX(billboardMapSymbol->getPosition31().x);
                double lat = OsmAnd::Utilities::get31LatitudeY(billboardMapSymbol->getPosition31().y);
                result.objectLatLon = CLLocationCoordinate2DMake(lat, lon);

                if (const auto billboardAdditionalParams = std::dynamic_pointer_cast<const OsmAnd::MapSymbolsGroup::AdditionalBillboardSymbolInstanceParameters>(symbolInfo.instanceParameters))
                {
                    if (billboardAdditionalParams->overridesPosition31)
                    {
                        lon = OsmAnd::Utilities::get31LongitudeX(billboardAdditionalParams->position31.x);
                        lat = OsmAnd::Utilities::get31LatitudeY(billboardAdditionalParams->position31.y);
                        result.objectLatLon = CLLocationCoordinate2DMake(lat, lon);
                    }
                }
                
                
                //test
//                const auto a = symbolInfo.mapSymbol->groupPtr;
                
                if (const auto amenitySymbolGroup = dynamic_cast<OsmAnd::AmenitySymbolsProvider::AmenitySymbolsGroup*>(symbolInfo.mapSymbol->groupPtr))
                {
                    cppAmenity = amenitySymbolGroup->amenity;
                }
                
//                OsmAnd::AmenitySymbolsProvider::AmenitySymbolsGroup* amenitySymbolGroup = dynamic_cast<OsmAnd::AmenitySymbolsProvider::AmenitySymbolsGroup*>(symbolInfo.mapSymbol->groupPtr);
//                cppAmenity = amenitySymbolGroup->amenity;
            }
            else
            {
                result.objectLatLon = [mapVc getLatLonFromElevatedPixel:point.x y:point.y].coordinate;
            }
            
            if (cppAmenity != nullptr)
            {
                NSMutableArray<NSString *> *names = [NSMutableArray new];
                for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(cppAmenity->localizedNames)))
                {
                    NSString *name = entry.value().toNSString();
                    if (name)
                        [names addObject:name];
                }
                
                NSString *nativeName = cppAmenity->nativeName.toNSString();
                if (nativeName)
                    [names addObject:nativeName];
                
                uint64_t obfId = cppAmenity->id.id;
                amenity = [self findAmenity:result.objectLatLon names:names obfId:obfId];
            }
            else
            {
                OsmAnd::MapObjectsSymbolsProvider::MapObjectSymbolsGroup* mapObjectSymbolsGroup = dynamic_cast<OsmAnd::MapObjectsSymbolsProvider::MapObjectSymbolsGroup*>(symbolInfo.mapSymbol->groupPtr);
                if (const auto obfMapObject = mapObjectSymbolsGroup->mapObject)
                {
                    MutableOrderedDictionary<NSString *,NSString *> *tags = [self getOrderedTags:obfMapObject->getResolvedAttributesListPairs()];
                    
                    BOOL isTravelGpx = [OATravelObfHelper.shared isTravelGpxTags:tags];
                    BOOL isOsmRoute = !OsmAnd::NetworkRouteKey::getRouteKeys([self toQHash:tags]).isEmpty();
                    BOOL isClickableWay = [_clickableWayHelper isClickableWay:obfMapObject tags:tags];
                    
                    if (isOsmRoute && !osmRoutesAlreadyAdded)
                    {
                        osmRoutesAlreadyAdded = [self addOsmRoutesAround:result point:point selectorFilter:[self createRouteFilter]];
                    }
                    
                    if (!isOsmRoute || !osmRoutesAlreadyAdded)
                    {
                        if (isTravelGpx)
                        {
                            [self addTravelGpx:result routeId: tags[ROUTE_ID]];
                        }
                        else if (isClickableWay)
                        {
                            OAClickableWay *clickableWay = [_clickableWayHelper loadClickableWay:[result getPointLatLon] obfMapObject:obfMapObject tags:tags];
                            [self addClickableWay:result clickableWay:clickableWay];
                        }
                    }
                    
                    BOOL allowAmenityObjects = !isTravelGpx;
                    
                    if (allowAmenityObjects)
                    {
                        if (auto onPathMapSymbol = std::dynamic_pointer_cast<const  OsmAnd::IOnPathMapSymbol>(symbolInfo.mapSymbol))
                        {
                            CLLocationCoordinate2D latLon = result.objectLatLon;
                            NSString *latLonTag = tags[TAG_POI_LAT_LON];
                            if (latLonTag)
                            {
                                CLLocation *l = [self parsePoiLatLon:latLonTag];
                                if (l)
                                    latLon = l.coordinate;
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
                                [self addRenderedObject:result symbolInfo:symbolInfo obfMapObject:obfMapObject tags:tags];
                            }
                        }
                    }
                }
            }
            
            if (amenity && [self isUniqueAmenity:[result getAllObjects] amenity:amenity])
            {
                [result collect:amenity];
                //result.collect(amenity, mapLayers.getPoiMapLayer());
            }
        }
    }
}

- (CLLocation *) parsePoiLatLon:(NSString *)value
{
    if (!value)
        return nil;
    
    OASKGeoParsedPoint * p = [OASKMapUtils.shared decodeShortLinkStringS:value];
    return [[CLLocation alloc] initWithLatitude:p.getLatitude longitude:p.getLongitude];
}

- (NSString *) getMapIconName:(OsmAnd::IMapRenderer::MapSymbolInformation)symbolInfo
{
    const auto rasterMapSymbol = [self getRasterMapSymbol:symbolInfo];
    if (rasterMapSymbol != nullptr && rasterMapSymbol->contentClass == OsmAnd::RasterMapSymbol::ContentClass::Icon)
    {
        rasterMapSymbol->content.toNSString();
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
            //TODO: test which one is correct?
            renderedObject.obfId = mapObject->id;
            //renderedObject.obfId = mapObject->id.id;
        }
        const auto points31 = obfMapObject->points31;
        for (int k = 0; k < points31.size(); k++)
        {
            const auto pointI = points31[k];
            [renderedObject addLocation:pointI.x y:pointI.y];
        }
        
//        renderedObject.labelX = obfMapObject->getLabelCoordinateX();
//        renderedObject.labelY = obfMapObject->getLabelCoordinateY();
        
        double lat = OsmAnd::Utilities::get31LatitudeY(obfMapObject->getLabelCoordinateY());
        double lon = OsmAnd::Utilities::get31LongitudeX(obfMapObject->getLabelCoordinateX());
        [renderedObject setLabelLatLon:CLLocationCoordinate2DMake(lat, lon)];
        
        if (rasterMapSymbol->contentClass == OsmAnd::RasterMapSymbol::ContentClass::Caption)
        {
            [renderedObject setName:rasterMapSymbol->content.toNSString()];
        }
        if (rasterMapSymbol->contentClass == OsmAnd::RasterMapSymbol::ContentClass::Icon)
        {
            [renderedObject setIconRes:rasterMapSymbol->content.toNSString()];
        }
        for (NSString *key in tags.allKeys)
        {
            renderedObject.tags[key] = tags[key];
            
        }
        [result collect:renderedObject];
    }
}

- (OAPOI *) getAmenity:(CLLocationCoordinate2D)latLon obfMapObject:(const std::shared_ptr<const OsmAnd::MapObject>)obfMapObject tags:(MutableOrderedDictionary<NSString *,NSString *> *)tags
{
    NSMutableArray<NSString *> *names = [self getValues:obfMapObject->getCaptionsInAllLanguages()];
    NSString *caption = obfMapObject->getCaptionInNativeLanguage().toNSString();
    if (![caption isEmpty])
        [names addObject:caption];
    
    if (![tags isEmpty] && tags[OATravelGpx.TRAVEL_MAP_TO_POI_TAG] && [tags[ROUTE_TAG] isEqualToString:@"point"])
    {
        [names addObject:tags[OATravelGpx.TRAVEL_MAP_TO_POI_TAG]]; // additional attribute for TravelGpx points (route_id)
    }
    
    uint64_t obfId = -1;
    if (const auto& mapObject = std::dynamic_pointer_cast<const OsmAnd::ObfMapObject>(obfMapObject))
    {
        //TODO: test which one is correct?
        obfId = mapObject->id;
        //obfId = mapObject->id.id;
    }
    
    OAPOI *amenity = [self findAmenity:latLon names:names obfId:obfId];
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
    OATravelGpx *travelGpx = [OATravelObfHelper.shared searchTravelGpxWithLatLon:result.objectLatLon routeId:routeId];
    
    if (travelGpx && [self isUniqueTravelGpx:[result getAllObjects] travelGpx:travelGpx])
    {
//        OAWpt
    }
    
    
    //TODO: implement
}

- (BOOL) addClickableWay:(OAMapSelectionResult *)result clickableWay:(OAClickableWay *)clickableWay
{
    if (clickableWay && [self isUniqueClickableWay:[result getAllObjects] clickableWay:clickableWay])
    {
        [result collect:clickableWay];
        //result.collect(clickableWay, clickableWayHelper.getContextMenuProvider());
        return YES;
    }
    return NO;
}

- (BOOL) isUniqueGpxFileName:(NSMutableArray<OASelectedMapObject *> *)selectedObjects gpxFileName:(NSString *)gpxFileName
{
    for (OASelectedMapObject *selectedObject in selectedObjects)
    {
        id object = selectedObject.object;
        
//        if ([object isKindOfClass:SelectedGpxPoint.class])
//        {
//            
//        }
    }
    
    //TODO: implement
    
    return YES;
}


/*
private boolean isUniqueGpxFileName(@NonNull List<SelectedMapObject> selectedObjects,
        @NonNull String gpxFileName) {
    for (SelectedMapObject selectedObject : selectedObjects) {
        Object object = selectedObject.object();
        if (object instanceof SelectedGpxPoint gpxPoint && selectedObject.provider() instanceof GPXLayer) {
            if (gpxPoint.getSelectedGpxFile().getGpxFile().getPath().endsWith(gpxFileName)) {
                return false;
            }
        }
    }
    return true;
}
*/


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
//    return [Self isUn]
    
    
    //TODO: implement
    
    
}

- (BOOL) isUniqueTravelGpx:(NSMutableArray<OASelectedMapObject *> *)selectedObjects travelGpx:(OATravelGpx *)travelGpx
{
    //TODO: implement
    return NO;
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


//private boolean putRouteGpxToSelected(

//private boolean isUniqueOsmRoute(

//private boolean addAmenity(

//private boolean isUniqueAmenity(

- (BOOL) isUniqueAmenity:(NSMutableArray<OASelectedMapObject *> *)selectedObjects amenity:(OAPOI *)amenity
{
    
    
    //TODO: implement
    
    return NO;
}

//private List<String> getPublicTransportTypes()


- (void) processTransportStops:(NSMutableArray<OASelectedMapObject *> *)selectedObjects
{
    //TODO: implement
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

- (OAPOI *) findAmenity:(CLLocationCoordinate2D)latLon names:(NSMutableArray<NSString *> *)names obfId:(uint64_t)obfId
{
    int searchRadius = [ObfConstants isIdFromRelation:obfId >> AMENITY_ID_RIGHT_SHIFT] ?
        AMENITY_SEARCH_RADIUS :
        AMENITY_SEARCH_RADIUS_FOR_RELATION;
    
    return [self findAmenity:latLon names:names obfId:obfId radius:searchRadius];
}

- (OAPOI *) findAmenity:(CLLocationCoordinate2D)latLon names:(NSMutableArray<NSString *> *)names obfId:(uint64_t)obfId radius:(int)radius
{
    
    //TODO: implement
    
    return nil;
}



//public static List<Amenity> findAmenities(

//public static Amenity findAmenityByOsmId(

//public static Amenity findAmenityByOsmId(

//public static Amenity findAmenityByName(

//public static PlaceDetailsObject fetchOtherData(

//public static PlaceDetailsObject fetchOtherData(

//private static boolean copyCoordinates(

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

