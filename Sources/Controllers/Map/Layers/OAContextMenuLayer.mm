//
//  OAContextMenuLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAContextMenuLayer.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OATargetPoint.h"
#import "OAMapLayer.h"
#import "OAMapLayers.h"
#import "OAContextMenuProvider.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAReverseGeocoder.h"
#import "Localization.h"
#import "OAPOILocationType.h"
#import "OAMapObject+cpp.h"
#import "OAPOI.h"
#import "OARenderedObject.h"
#import "OARenderedObject+cpp.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIFilter.h"
#import "OAPOIHelper.h"
#import "OAPOIHelper+cpp.h"
#import "OATransportStop.h"
#import "OAUtilities.h"
#import "OAPointDescription.h"
#import "OATransportStopsBaseController.h"
#import "OAMapRendererEnvironment.h"
#import "OAColors.h"
#import "OAMapUtils+cpp.h"
#import "OAMapSelectionHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "OsmAndSharedWrapper.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/Map/IMapRenderer.h>
#include <OsmAndCore/Data/TransportStop.h>
#include <OsmAndCore/Search/TransportStopsInAreaSearch.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/Map/BillboardRasterMapSymbol.h>
#include <OsmAndCore/SingleSkImage.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>

@interface OAContextMenuLayer () <CAAnimationDelegate>
@end

@implementation OAContextMenuLayer
{
    // Context pin marker
    std::shared_ptr<OsmAnd::MapMarkersCollection> _contextPinMarkersCollection;
    std::shared_ptr<OsmAnd::MapMarker> _contextPinMarker;
    
    std::shared_ptr<OsmAnd::VectorLinesCollection> _outlineCollection;
    
    UIImageView *_animatedPin;
    BOOL _animationDone;
    CGFloat _latPin, _lonPin;
    
    BOOL _initDone;
    
    BOOL _isInChangePositionMode;
    UIImageView *_changePositionPin;
    
    NSArray<NSString *> *_publicTransportTypes;
    
    id<OAMoveObjectProvider> _selectedObjectContextMenuProvider;
    
    CGPoint _cachedTargetPoint;
    
    OAMapSelectionHelper *_mapSelectionHelper;
}

- (NSString *) layerId
{
    return kContextMenuLayerId;
}

- (void) initLayer
{
    // Create context pin marker
    _contextPinMarkersCollection.reset(new OsmAnd::MapMarkersCollection());
    _contextPinMarker = OsmAnd::MapMarkerBuilder()
    .setIsAccuracyCircleSupported(false)
    .setBaseOrder(self.pointsOrder)
    .setIsHidden(true)
    .setPinIcon(OsmAnd::SingleSkImage([OANativeUtilities skImageFromPngResource:@"ic_map_pin"]))
    .setPinIconVerticalAlignment(OsmAnd::MapMarker::Top)
    .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
    .buildAndAddToCollection(_contextPinMarkersCollection);
    
    _outlineCollection = std::make_shared<OsmAnd::VectorLinesCollection>();

    _initDone = YES;
    
    _mapSelectionHelper = [[OAMapSelectionHelper alloc] init];

    // Add context pin markers
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_contextPinMarkersCollection];
    }];
}

- (BOOL) isObjectMovable:(id)object
{
    for (OAMapLayer *layer in self.mapViewController.mapLayers.getLayers)
    {
        if ([layer conformsToProtocol:@protocol(OAMoveObjectProvider)])
        {
            id<OAMoveObjectProvider> provider = (id<OAMoveObjectProvider>) layer;
            if ([provider isObjectMovable:object])
            {
                return YES;
            }
        }
    }
    return NO;
}

- (void) applyMoveProvider:(id)object
{
    _selectedObjectContextMenuProvider = nil;
    for (OAMapLayer *layer in self.mapViewController.mapLayers.getLayers)
    {
        if ([layer conformsToProtocol:@protocol(OAMoveObjectProvider)])
        {
            id<OAMoveObjectProvider> provider = (id<OAMoveObjectProvider>) layer;
            if ([provider isObjectMovable:object])
            {
                _selectedObjectContextMenuProvider = provider;
                break;
            }
        }
    }
}

- (void)setupIconCenter
{
    auto centerPixel = self.mapView.getCenterPixel;
    CGPoint targetPoint = CGPointMake(centerPixel.x / UIScreen.mainScreen.scale, centerPixel.y / UIScreen.mainScreen.scale);
    if (CGPointEqualToPoint(targetPoint, _cachedTargetPoint))
        return;
        
    _cachedTargetPoint = targetPoint;
    CGFloat iconHalfHeight = _changePositionPin.frame.size.height /2;
    CGFloat iconHalfWidth = _changePositionPin.frame.size.width / 2;
    CGFloat shiftX = iconHalfWidth;
    CGFloat shiftY = iconHalfHeight;
    EOAPinVerticalAlignment verticalAlignment = [_selectedObjectContextMenuProvider getPointIconVerticalAlignment];
    EOAPinHorizontalAlignment horizontalAlignment = [_selectedObjectContextMenuProvider getPointIconHorizontalAlignment];

    if (horizontalAlignment == EOAPinAlignmentRight)
        shiftX = -iconHalfWidth;
    else if (horizontalAlignment == EOAPinAlignmentCenterHorizontal)
        shiftX = 0;

    if (verticalAlignment == EOAPinAlignmentBottom)
        shiftY = -iconHalfHeight;
    else if (verticalAlignment == EOAPinAlignmentCenterVertical)
        shiftY = 0;

    _changePositionPin.center = CGPointMake(targetPoint.x - shiftX, targetPoint.y - shiftY);
}

- (void) enterChangePositionMode:(id)targetObject
{
    [self applyMoveProvider:targetObject];
    if (!_selectedObjectContextMenuProvider)
        return;
    
    UIImage *icon = [_selectedObjectContextMenuProvider getPointIcon:targetObject];

    [_selectedObjectContextMenuProvider setPointVisibility:targetObject hidden:YES];
    if (!_changePositionPin)
    {
        _changePositionPin = [[UIImageView alloc] initWithImage:icon];
        _changePositionPin.frame = CGRectMake(0., 0., 30., 30.);
        _changePositionPin.contentMode = UIViewContentModeCenter;
    }
    else
    {
        _changePositionPin.image = icon;
    }
    [_changePositionPin sizeToFit];
    
    [self setupIconCenter];
    
    [self.mapView addSubview:_changePositionPin];
    _isInChangePositionMode = YES;
}

- (void) exitChangePositionMode:(id)targetObject applyNewPosition:(BOOL)applyNewPosition
{
    if (!_isInChangePositionMode)
        return;
    
    if (_changePositionPin && _changePositionPin.superview)
        [_changePositionPin removeFromSuperview];
    
    if (_selectedObjectContextMenuProvider)
    {
        if (applyNewPosition)
        {
            const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(self.mapView.target31);
            [_selectedObjectContextMenuProvider applyNewObjectPosition:targetObject position:CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude)];
        }
        else
        {
            [_selectedObjectContextMenuProvider setPointVisibility:targetObject hidden:NO];
        }
    }
    _selectedObjectContextMenuProvider = nil;
    _isInChangePositionMode = NO;
    _cachedTargetPoint = CGPointZero;
}

- (void) onMapFrameRendered
{
    if (_initDone && _animatedPin)
    {
        if (_animationDone)
        {
            [self hideAnimatedPin];
        }
        else
        {
            CGPoint targetPoint;
            OsmAnd::PointI targetPositionI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_latPin, _lonPin));
            if ([self.mapView convert:&targetPositionI toScreen:&targetPoint])
                _animatedPin.center = CGPointMake(targetPoint.x, targetPoint.y);
        }
    }
    
    if (_isInChangePositionMode)
        [self setupIconCenter];
    
    if (_isInChangePositionMode && self.changePositionDelegate)
        [self.changePositionDelegate onMapMoved];
}

- (std::shared_ptr<OsmAnd::MapMarker>) getContextPinMarker
{
    return _contextPinMarker;
}

- (void) showContextPinMarker:(double)latitude longitude:(double)longitude animated:(BOOL)animated
{
    if (!_initDone)
        return;
    
    _contextPinMarker->setIsHidden(true);
    
    if (!self.mapView.hidden && animated)
    {
        _animationDone = NO;
        
        _latPin = latitude;
        _lonPin = longitude;
        
        const OsmAnd::LatLon latLon(_latPin, _lonPin);
        _contextPinMarker->setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon));
        
        if (_animatedPin)
            [self hideAnimatedPin];
        
        _animatedPin = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_map_pin"]];
        
        @try
        {
            CGPoint targetPoint;
            OsmAnd::PointI targetPositionI = OsmAnd::Utilities::convertLatLonTo31(latLon);
            [self.mapView convert:&targetPositionI toScreen:&targetPoint];
            
            _animatedPin.center = CGPointMake(targetPoint.x, targetPoint.y);
        }
        @catch (NSException *e)
        {
            _animatedPin = nil;
            _contextPinMarker->setIsHidden(false);
            return;
        }
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation
                                          animationWithKeyPath:@"transform"];
        
        CATransform3D scale1 = CATransform3DMakeScale(0.5, 0.5, 1);
        CATransform3D scale2 = CATransform3DMakeScale(1.2, 1.2, 1);
        CATransform3D scale3 = CATransform3DMakeScale(0.9, 0.9, 1);
        CATransform3D scale4 = CATransform3DMakeScale(1.0, 1.0, 1);
        
        NSArray *frameValues = [NSArray arrayWithObjects:
                                [NSValue valueWithCATransform3D:scale1],
                                [NSValue valueWithCATransform3D:scale2],
                                [NSValue valueWithCATransform3D:scale3],
                                [NSValue valueWithCATransform3D:scale4],
                                nil];
        [animation setValues:frameValues];
        
        NSArray *frameTimes = [NSArray arrayWithObjects:
                               [NSNumber numberWithFloat:0.0],
                               [NSNumber numberWithFloat:0.5],
                               [NSNumber numberWithFloat:0.9],
                               [NSNumber numberWithFloat:1.0],
                               nil];
        [animation setKeyTimes:frameTimes];
        
        animation.fillMode = kCAFillModeForwards;
        animation.removedOnCompletion = NO;
        animation.duration = .3;
        animation.delegate = self;
        _animatedPin.layer.anchorPoint = CGPointMake(0.5, 1.0);
        [_animatedPin.layer addAnimation:animation forKey:@"popup"];
        
        [self.mapView addSubview:_animatedPin];
    }
    else
    {
        const OsmAnd::LatLon latLon(latitude, longitude);
        _contextPinMarker->setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon));
        _contextPinMarker->setIsHidden(false);
    }
}

- (void) hideContextPinMarker
{
    if (!_initDone)
        return;

    _contextPinMarker->setIsHidden(true);
}

- (void) hideAnimatedPin
{
    if (_animatedPin)
    {
        [_animatedPin.layer removeAllAnimations];
        [_animatedPin removeFromSuperview];
        _animatedPin = nil;
    }
}

- (OATargetPoint *) getTargetPoint:(id)obj
{
    OAMapViewController *mapViewController = self.mapViewController;
    for (OAMapLayer *layer in [mapViewController.mapLayers getLayers])
    {
        if ([layer conformsToProtocol:@protocol(OAContextMenuProvider)])
        {
            OATargetPoint *targetPoint = [((id<OAContextMenuProvider>)layer) getTargetPoint:obj];
            if (targetPoint)
                return targetPoint;
        }
    }
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    OAMapViewController *mapViewController = self.mapViewController;
    for (OAMapLayer *layer in [mapViewController.mapLayers getLayers])
    {
        if ([layer conformsToProtocol:@protocol(OAContextMenuProvider)])
        {
            OATargetPoint *targetPoint = [((id<OAContextMenuProvider>)layer) getTargetPointCpp:obj];
            if (targetPoint)
                return targetPoint;
        }
    }
    return nil;
}

- (BOOL) isSecondaryProvider
{
    return NO;
}

- (OATargetPoint *) getUnknownTargetPoint:(double)latitude longitude:(double)longitude
{
    NSString *addressString = nil;
    BOOL isAddressFound = NO;
    NSString *formattedTargetName = nil;
    NSString *roadTitle = [[OAReverseGeocoder instance] lookupAddressAtLat:latitude lon:longitude];
    if (!roadTitle || roadTitle.length == 0)
    {
        addressString = OALocalizedString(@"map_no_address");
    }
    else
    {
        addressString = roadTitle;
        isAddressFound = YES;
    }
    
    if (isAddressFound || addressString)
    {
        formattedTargetName = addressString;
    }
    else
    {
        formattedTargetName = [OAPointDescription getLocationName:latitude lon:longitude sh:NO];
    }
    
    OAPOIType *poiType = [[OAPOILocationType alloc] init];
    
    OAPOI *poi = [[OAPOI alloc] init];
    poi.latitude = latitude;
    poi.longitude = longitude;
    poi.type = poiType;
    
    if (poi.name.length == 0)
        poi.name = poiType.name;
    if (poi.nameLocalized.length == 0)
        poi.nameLocalized = poiType.nameLocalized;
    if (poi.nameLocalized.length == 0)
        poi.nameLocalized = formattedTargetName;
    
    formattedTargetName = poi.nameLocalized;
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.location = CLLocationCoordinate2DMake(latitude, longitude);
    targetPoint.title = formattedTargetName;
    targetPoint.icon = [poiType icon];
    targetPoint.titleAddress = roadTitle;
    targetPoint.type = OATargetPOI;
    targetPoint.targetObj = poi;

    return targetPoint;
}

- (BOOL) showContextMenu:(CGPoint)touchPoint showUnknownLocation:(BOOL)showUnknownLocation forceHide:(BOOL)forceHide
{
    MapSelectionResult *result = [_mapSelectionHelper collectObjectsFromMap:touchPoint showUnknownLocation:showUnknownLocation];
    CLLocation *pointLatLon = result.pointLatLon;
    NSMutableArray<SelectedMapObject *> *selectedObjects = [[result getProcessedObjects] mutableCopy];
    
    int64_t objectSelectionThreshold = 0;
    for (SelectedMapObject *selectedObject in selectedObjects)
    {
        if (selectedObject.provider && [selectedObject.provider conformsToProtocol:@protocol(OAContextMenuProvider)])
        {
            id<OAContextMenuProvider> provider = selectedObject.provider;
            int64_t selectionThreshold = [provider getSelectionPointOrder:selectedObject.object];
            if (selectionThreshold <= objectSelectionThreshold)
            {
                objectSelectionThreshold = selectionThreshold;
            }
        }
    }
    NSMutableArray<SelectedMapObject *> *objectsAvailableForSelection = [NSMutableArray new];
    
    for (SelectedMapObject *selectedObject in selectedObjects)
    {
        if (objectSelectionThreshold < 0)
        {
            if (selectedObject.provider && [selectedObject.provider conformsToProtocol:@protocol(OAContextMenuProvider)])
            {
                id<OAContextMenuProvider> provider = selectedObject.provider;
                if ([provider isKindOfClass:OAMapLayer.class])
                {
                    OAMapLayer *layer = provider;
                    if ([layer pointsOrder] <= objectSelectionThreshold)
                    {
                        [objectsAvailableForSelection addObject:selectedObject];
                    }
                    else
                    {
                        continue;
                    }
                }
            }
        }
        id<OAContextMenuProvider> provider = selectedObject.provider;
        if (provider && [provider runExclusiveAction:selectedObject.object unknownLocation:showUnknownLocation])
        {
            return YES;
        }
    }
    
    if (objectSelectionThreshold < 0)
    {
        // FIXME:
        selectedObjects = objectsAvailableForSelection;
    }
    
    if (selectedObjects.count == 1)
    {
        SelectedMapObject *selectedObject = selectedObjects[0];
        CLLocation *latLon = [result objectLatLon];
        
        if (objectSelectionThreshold < 0)
            latLon = nil;
        
        [self showContextMenu:selectedObject latLon:latLon touchPointLatLon:pointLatLon];
        return YES;
    }
    else if (selectedObjects.count > 1)
    {
        [self showContextMenu:pointLatLon selectedObjects:selectedObjects];
        return YES;
        
    }
    else if (showUnknownLocation)
    {
        [OsmAndApp instance].mapMode = OAMapModeFree;
        CLLocationCoordinate2D coord = [self getTouchPointCoord:touchPoint];
        OATargetPoint *unknownTargetPoint = [self getUnknownTargetPoint:coord.latitude longitude:coord.longitude];
        [[OARootViewController instance].mapPanel showContextMenu:unknownTargetPoint];
        return YES;
        
    }
    CLLocationCoordinate2D coord = [self getTouchPointCoord:touchPoint];
    [[OARootViewController instance].mapPanel processNoSymbolFound:coord forceHide:forceHide];
    return NO;
}

- (void) showContextMenu:(CLLocation *)touchPointLatLon selectedObjects:(NSArray<SelectedMapObject *> *)selectedObjects
{
    OAMapPanelViewController *mapPanel = OARootViewController.instance.mapPanel;
    
    // Android calls context menu without TargetPoint, but with SelectedMapObject directly
    NSMutableArray<OATargetPoint *> *targetPoints = [NSMutableArray new];
    NSMutableArray<SelectedMapObject *> *filteredSelectedObjects = [NSMutableArray new];
    for (SelectedMapObject *selectedObject in selectedObjects)
    {
        id<OAContextMenuProvider> provider = selectedObject.provider;
        if (!provider)
            provider = self.mapViewController.mapLayers.poiLayer;
        
        if (provider)
        {
            OATargetPoint *targetPoint = [provider getTargetPoint:selectedObject.object];
            if (targetPoint)
            {
                [filteredSelectedObjects addObject:selectedObject];
                [targetPoints addObject:targetPoint];
            }
        }
    }
    if (!NSArrayIsEmpty(targetPoints))
        [mapPanel showContextMenuWithPoints:targetPoints selectedObjects:filteredSelectedObjects touchPointLatLon:touchPointLatLon];
}

- (void) showContextMenu:(SelectedMapObject *)selectedObject touchPointLatLon:(CLLocation *)touchPointLatLon
{
    [self showContextMenu:selectedObject latLon:nil touchPointLatLon:touchPointLatLon];
}

- (void) showContextMenu:(SelectedMapObject *)selectedObject latLon:(CLLocation *)latLon touchPointLatLon:(CLLocation *)pointLatLon
{
    id selectedObj = selectedObject.object;
    OAPointDescription *pointDescription;
    
    id<OAContextMenuProvider> provider = selectedObject.provider;
    if (provider)
    {
        if (!latLon)
            latLon = [provider getObjectLocation:selectedObj];

        pointDescription = [provider getObjectName:selectedObj];
    }
    
    if (!latLon)
        latLon = pointLatLon;
        
    [self showContextMenu:latLon pointDescription:pointDescription object:selectedObj selectedObject:selectedObject provider:provider touchPointLatLon:pointLatLon];
}

- (void) showContextMenu:(CLLocation *)latLon pointDescription:(OAPointDescription *)pointDescription object:(id)object selectedObject:(SelectedMapObject *)selectedObject provider:(id<OAContextMenuProvider>)provider touchPointLatLon:(CLLocation *)touchPointLatLon
{
    if (!provider || ![provider showMenuAction:object])
    {
        OATargetPoint *targetPoint;
        if (provider)
            targetPoint = [provider getTargetPoint:object];
        else
            targetPoint = [self.mapViewController.mapLayers.poiLayer getTargetPoint:object];
            
        if (targetPoint)
        {
            targetPoint.location = latLon.coordinate;
            [targetPoint initAdderssIfNeeded];
            [targetPoint initDetailsObjectIfNeeded:selectedObject.object];
            
            [OARootViewController.instance.mapPanel showContextMenuWithPoints:@[targetPoint] selectedObjects:@[selectedObject] touchPointLatLon:touchPointLatLon];
        }
    }
}

- (BOOL) showMenuAction:(id)object
{
    return NO;
}

- (BOOL) runExclusiveAction:(id)obj unknownLocation:(BOOL)unknownLocation
{
    return NO;
}

- (int64_t) getSelectionPointOrder:(id)selectedObject
{
    return 0;
}

- (void) highlightPolygon:(QVector<OsmAnd::PointI>)points;
{
    if (_outlineCollection != nullptr)
        [self hideRegionHighlight];

    [self.mapViewController runWithRenderSync:^{
        _outlineCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
        OsmAnd::VectorLineBuilder builder;
        builder.setPoints(points)
            .setIsHidden(false)
            .setLineId(1)
            .setLineWidth(2 * kWidthCorrectionValue * [[UIScreen mainScreen] scale])
            .setFillColor(OsmAnd::ColorARGB(color_osmand_orange_argb))
            .setApproximationEnabled(false)
            .setBaseOrder(self.pointsOrder + 1);
        builder.buildAndAddToCollection(_outlineCollection);
        [self.mapView addKeyedSymbolsProvider:_outlineCollection];
    }];
}

- (void) hideRegionHighlight
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeKeyedSymbolsProvider:_outlineCollection];
        _outlineCollection = nullptr;
    }];
}

- (NSArray<OARenderedObject *> *) retrievePolygonsAroundMapObject:(double)lat lon:(double)lon mapObject:(OAMapObject *)mapObject
{
    OAMapRendererView *mapView = (OAMapRendererView *)OARootViewController.instance.mapPanel.mapViewController.mapView;
    OsmAnd::ZoomLevel zoomLevel = mapView.zoomLevel;
    OsmAnd::PointI point(OsmAnd::Utilities::get31TileNumberX(lon), OsmAnd::Utilities::get31TileNumberY(lat));
    return [self retrievePolygonsAroundMapObject:point mapObject:mapObject zoomLevel:zoomLevel];
}

- (NSArray<OARenderedObject *> *) retrievePolygonsAroundMapObject:(OsmAnd::PointI)point mapObject:(OAMapObject *)mapObject zoomLevel:(OsmAnd::ZoomLevel)zoomLevel
{
    NSMutableArray<OARenderedObject *> *res = [NSMutableArray new];
    if (!mapObject)
        return res;
    
    NSArray<OARenderedObject *> *rendPolygons = [self retrievePolygonsAroundPoint:point zoomLevel:zoomLevel];
    QVector<OsmAnd::PointI> objectPolygon = [mapObject getPointsPolygon];
    if (objectPolygon.size() > 0)
    {
        for (OARenderedObject *r in rendPolygons)
        {
            if ([OAMapUtils isFirstPolygonInsideSecond:objectPolygon secondPolygon:[r getPointsPolygon]])
            {
                [res addObject:r];
            }
        }
    }
    else
    {
        [res addObjectsFromArray:rendPolygons];
    }
    return res;
}

- (NSArray<OARenderedObject *> *) retrievePolygonsAroundPoint:(OsmAnd::PointI)point zoomLevel:(OsmAnd::ZoomLevel)zoomLevel
{
    NSMutableArray<OARenderedObject *> *res = [NSMutableArray new];
    
    OAMapViewController *mapViewController = OARootViewController.instance.mapPanel.mapViewController;
    OAMapRendererEnvironment *menv = [mapViewController mapRendererEnv];
    QList<std::shared_ptr<const OsmAnd::MapObject>> polygons = menv.mapPrimitivesProvider->retreivePolygons(point, zoomLevel);
    if (!polygons.isEmpty())
    {
        for (int i = 0; i < polygons.size(); i++)
        {
            std::shared_ptr<const OsmAnd::MapObject> polygon = polygons[i];
            OARenderedObject *renderedObject = [self createRenderedObjectForPolygon:polygon order:i];
            if (renderedObject)
                [res addObject:renderedObject];
        }
    }
    return res;
}

- (OARenderedObject *)createRenderedObjectForPolygon:(std::shared_ptr<const OsmAnd::MapObject>)mapObject order:(int)order
{
    OARenderedObject *renderedObject = [OARenderedObject new];
    QList<QPair<QString, QString>> tags = mapObject->getResolvedAttributesListPairs();
    
    MutableOrderedDictionary<NSString *, NSString *> *parsedTags = [MutableOrderedDictionary new];
    for (int i = 0; i < tags.size(); i++)
    {
      QPair<QString, QString> tagPair = tags[i];
      NSString *key = tagPair.first.toNSString();
      NSString *value = tagPair.second.toNSString();
      if ([key isEqualToString:@"osmand_change"] && [value isEqualToString:@"delete"])
      {
        return nil;
      }
      if (key && value)
        parsedTags[key] = value;
    }
    renderedObject.tags = parsedTags;
    
    QHash<QString, QString> names = mapObject->getCaptionsInAllLanguages();
    QList<QString> namesKeys = names.keys();
    for (int i = 0; i < namesKeys.size(); i++)
    {
        NSString *key = namesKeys[i].toNSString();
        NSString *value = names[namesKeys[i]].toNSString();
        if ([key isEqualToString:@"osmand_change"] && [value isEqualToString:@"delete"])
        {
            return nil;
        }
        [renderedObject setName:key name:value];
    }

    QVector<OsmAnd::PointI> points31 = mapObject->points31;
    OASKQuadRect *rect = [OASKQuadRect new];
    for (int i = 0; i < points31.size(); i++)
    {
        OsmAnd::PointI p = points31[i];
        [renderedObject addLocation:p.x y:p.y];
        [rect expandLeft:p.x top:p.y right:p.x bottom:p.y];
    }
    [renderedObject setBBox:rect.left top:rect.top right:rect.right bottom:rect.bottom];
    
    const auto& obfMapObject = std::dynamic_pointer_cast<const OsmAnd::ObfMapObject>(mapObject);
    if (obfMapObject)
    {
        renderedObject.obfId = obfMapObject->id;
    }
    renderedObject.isPolygon = YES;
    renderedObject.order = order;
    renderedObject.labelX = mapObject->getLabelCoordinateX();
    renderedObject.labelY = mapObject->getLabelCoordinateY();
    double lat = OsmAnd::Utilities::get31LatitudeY(renderedObject.labelY);
    double lon = OsmAnd::Utilities::get31LongitudeX(renderedObject.labelX);
    [renderedObject setLabelLatLon:[[CLLocation alloc] initWithLatitude:lat longitude:lon]];
    
    if (!renderedObject.name || renderedObject.name.length == 0)
    {
        QString captionInNativeLanguage = mapObject->getCaptionInNativeLanguage();
        if (!captionInNativeLanguage.isEmpty())
        {
            renderedObject.name = captionInNativeLanguage.toNSString();
        }
        else
        {
            if (renderedObject.localizedNames.count > 0)
                renderedObject.name = renderedObject.localizedNames.allValues.firstObject;
        }
    }
    
    NSMutableDictionary *localizedNames = [NSMutableDictionary dictionary];
    renderedObject.nameLocalized = [OAPOIHelper processLocalizedNames:obfMapObject->getCaptionsInAllLanguages() nativeName:obfMapObject->getCaptionInNativeLanguage() names:localizedNames];
    if (!renderedObject.nameLocalized || renderedObject.nameLocalized.length == 0)
        renderedObject.nameLocalized = renderedObject.name;
    
    return renderedObject;
}

#pragma  mark - CAAnimationDelegate

- (void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    _animationDone = YES;
    _contextPinMarker->setIsHidden(false);
}

@end
