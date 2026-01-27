//
//  OADestinationsLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 09/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADestinationsLayer.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OALocationServices.h"
#import "OAObservable.h"
#import "OAMapRendererView.h"
#import "OADestination.h"
#import "OAAutoObserverProxy.h"
#import "OATargetPointsHelper.h"
#import "OAStateChangedListener.h"
#import "OATargetPoint.h"
#import "OADestinationsHelper.h"
#import "OADestinationsLineWidget.h"
#import "OAReverseGeocoder.h"
#import "OAPointDescription.h"
#import "OAMapLayers.h"
#import "OACompoundIconUtils.h"
#import "OARTargetPoint.h"
#import "OAAppSettings.h"
#import "OAAppData.h"
#import "OAPOI.h"
#import "OAFavoritesHelper.h"
#import "OASelectedGPXHelper.h"
#import "OAMapSelectionHelper.h"
#import "OAOsmAndFormatter.h"
#import "OASymbolMapLayer+cpp.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/SingleSkImage.h>

#define kLabelOffset 6

@interface OADestinationsLayer () <OAStateChangedListener>

@end

@implementation OADestinationsLayer
{
    std::shared_ptr<OsmAnd::MapMarkersCollection> _destinationsMarkersCollection;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _distanceMarkersCollection;
    std::shared_ptr<OsmAnd::VectorLinesCollection> _linesCollection;

    std::shared_ptr<OsmAnd::MapMarker> _firstDistanceMarker;
    std::shared_ptr<OsmAnd::VectorLine> _firstLine;
    std::shared_ptr<OsmAnd::VectorLine> _firstOutline;

    std::shared_ptr<OsmAnd::MapMarker> _secondDistanceMarker;
    std::shared_ptr<OsmAnd::VectorLine> _secondLine;
    std::shared_ptr<OsmAnd::VectorLine> _secondOutline;

    OAAutoObserverProxy* _destinationAddObserver;
    OAAutoObserverProxy* _destinationRemoveObserver;
    OAAutoObserverProxy* _destinationShowObserver;
    OAAutoObserverProxy* _destinationHideObserver;
    OAAutoObserverProxy* _destinationsChangeObserver;
    OAAutoObserverProxy* _locationUpdateObserver;

    OATargetPointsHelper *_targetPoints;
    OADestinationsLineWidget *_destinationLayerWidget;

    BOOL _showCaptionsCache;
    double _textSize;

    NSMutableArray<OAPOI *> *_amenities;

    BOOL _reconstructMarker;
}

- (NSString *) layerId
{
    return kDestinationsLayerId;
}

- (void) initLayer
{
    [super initLayer];
    
    _showCaptionsCache = self.showCaptions;
    _textSize = OAAppSettings.sharedManager.textSize.get;

    _destinationAddObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onDestinationAdded:withKey:)
                                                            andObserve:self.app.data.destinationAddObservable];

    _destinationRemoveObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onDestinationRemoved:withKey:)
                                                            andObserve:self.app.data.destinationRemoveObservable];

    _destinationShowObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onDestinationShow:withKey:)
                                                          andObserve:self.app.data.destinationShowObservable];
    _destinationHideObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onDestinationHide:withKey:)
                                                          andObserve:self.app.data.destinationHideObservable];
    
    _destinationsChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                            withHandler:@selector(onDestinationsChange:)
                                                             andObserve:self.app.data.destinationsChangeObservable];

    _locationUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onLocationUpdate)
                                                         andObserve:self.app.locationServices.updateLocationObserver];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProfileSettingSet:) name:kNotificationSetProfileSetting object:nil];

    _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _distanceMarkersCollection = std::make_shared<OsmAnd::MapMarkersCollection>();

    [self.app.data.mapLayersConfiguration setLayer:self.layerId Visibility:YES];
    
    _targetPoints = [OATargetPointsHelper sharedInstance];
    [_targetPoints addListener:self];

    _destinationLayerWidget = [[OADestinationsLineWidget alloc] init];
    [self.mapView addSubview:_destinationLayerWidget];

    [self refreshDestinationsMarkersCollection];

    _amenities = [NSMutableArray new];

    _reconstructMarker = false;
}

- (void) onMapFrameRendered
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_destinationLayerWidget drawLayer];
        self.mapViewController.mapView.renderer->updateSubsection(kDystanceMarkersSymbolSection);
    });
}

- (void) deinitLayer
{
    [super deinitLayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
     
    [_targetPoints removeListener:self];

    if (_destinationShowObserver)
    {
        [_destinationShowObserver detach];
        _destinationShowObserver = nil;
    }
    if (_destinationHideObserver)
    {
        [_destinationHideObserver detach];
        _destinationHideObserver = nil;
    }
    if (_destinationAddObserver)
    {
        [_destinationAddObserver detach];
        _destinationAddObserver = nil;
    }
    if (_destinationRemoveObserver)
    {
        [_destinationRemoveObserver detach];
        _destinationRemoveObserver = nil;
    }
    if (_destinationsChangeObserver)
    {
        [_destinationsChangeObserver detach];
        _destinationsChangeObserver = nil;
    }
    if (_locationUpdateObserver)
    {
        [_locationUpdateObserver detach];
        _locationUpdateObserver = nil;
    }
}

- (void) onProfileSettingSet:(NSNotification *)notification
{
    OACommonPreference *obj = notification.object;
    OAAppSettings *settings = [OAAppSettings sharedManager];
    OACommonActiveMarkerConstant *activeMarkers = settings.activeMarkers;
    OACommonBoolean *directionLines = settings.directionLines;
    if (obj)
    {
        if (obj == activeMarkers || obj == directionLines)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self drawDestinationLines];
            });
        }
    }
}

- (BOOL) updateLayer
{
    if (![super updateLayer])
        return NO;

    BOOL widgetUpdated = [_destinationLayerWidget updateLayer];
    BOOL attributesChanged = [_destinationLayerWidget areAttributesChanged];
    if (widgetUpdated || self.showCaptions != _showCaptionsCache || _textSize != OAAppSettings.sharedManager.textSize.get || attributesChanged)
    {
        _showCaptionsCache = self.showCaptions;
        _textSize = OAAppSettings.sharedManager.textSize.get;
        [self updateCaptionStyle];
        _reconstructMarker = true;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hide];
            [self refreshDestinationsMarkersCollection];
            [self show];
        });
    }
    
    return YES;
}

- (void) refreshDestinationsMarkersCollection
{
    [self.mapViewController runWithRenderSync:^{
        _destinationsMarkersCollection.reset(new OsmAnd::MapMarkersCollection());

        for (OADestination *destination in self.app.data.destinations)
        {
            if (!destination.hidden)
            {
                [self addDestinationPin:destination.markerResourceName color:destination.color latitude:destination.latitude longitude:destination.longitude description:destination.desc];
                [_destinationLayerWidget drawLineArrowWidget:destination];
            }
        }

        [self drawDestinationLines];
    }];
}

- (void) addDestinationPin:(NSString *)markerResourceName color:(UIColor *)color latitude:(double)latitude longitude:(double)longitude description:(NSString *)description
{
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    OsmAnd::FColorRGB col(r, g, b);
    const OsmAnd::LatLon latLon(latitude, longitude);

    auto markerIcon = [OACompoundIconUtils getScaledIcon:markerResourceName
                                     defaultResourceName:@"ic_destination_pin_1"
                                                   scale:_textSize
                                                   color:nil];
    if (!markerIcon)
        return;

    OsmAnd::MapMarkerBuilder builder;
    builder.setIsAccuracyCircleSupported(false)
    .setBaseOrder(self.baseOrder)
    .setIsHidden(false)
    .setPinIcon(OsmAnd::SingleSkImage(markerIcon))
    .setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon))
    .setPinIconVerticalAlignment(OsmAnd::MapMarker::Top)
    .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
    .setAccuracyCircleBaseColor(col);
    
    if (self.showCaptions && description.length > 0)
    {
        builder.setCaption(QString::fromNSString(description));
        builder.setCaptionStyle(self.captionStyle);
        builder.setCaptionTopSpace(self.captionTopSpace);
    }
    
    std::shared_ptr<OsmAnd::MapMarker> marker = builder.buildAndAddToCollection(_destinationsMarkersCollection);
    marker->setUpdateAfterCreated(true);
}

- (void) removeDestinationPin:(double)latitude longitude:(double)longitude;
{
    for (const auto &marker : _destinationsMarkersCollection->getMarkers())
    {
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(marker->getPosition());
        if ([OAUtilities doublesEqualUpToDigits:5 source:latLon.latitude destination:latitude] &&
            [OAUtilities doublesEqualUpToDigits:5 source:latLon.longitude destination:longitude])
        {
            _destinationsMarkersCollection->removeMarker(marker);
            break;
        }
    }
}

- (void) show
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:kDystanceMarkersSymbolSection provider:_destinationsMarkersCollection];
        [self.mapView addKeyedSymbolsProvider:kDystanceMarkersSymbolSection provider:_distanceMarkersCollection];
        [self.mapView addKeyedSymbolsProvider:_linesCollection];
    }];
}

- (void) hide
{
    [self.mapViewController runWithRenderSync:^{
        [self.mapView removeKeyedSymbolsProvider:_destinationsMarkersCollection];
        [self.mapView removeKeyedSymbolsProvider:_distanceMarkersCollection];
        [self.mapView removeKeyedSymbolsProvider:_linesCollection];
    }];
}

- (void) onDestinationAdded:(id)observable withKey:(id)key
{
    OADestination *destination = key;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self addDestinationPin:destination.markerResourceName color:destination.color latitude:destination.latitude longitude:destination.longitude description:destination.desc];
        [_destinationLayerWidget drawLineArrowWidget:destination];
    });
}

- (void) onDestinationRemoved:(id)observable withKey:(id)key
{
    OADestination *destination = key;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeDestinationPin:destination.latitude longitude:destination.longitude];
        [_destinationLayerWidget removeLineToDestinationPin:destination];
    });
}

- (void) onDestinationShow:(id)observer withKey:(id)key
{
    OADestination *destination = key;
    
    if (destination)
    {
        BOOL exists = NO;
        for (const auto &marker : _destinationsMarkersCollection->getMarkers())
        {
            OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(marker->getPosition());
            if ([OAUtilities doublesEqualUpToDigits:5 source:latLon.latitude destination:destination.latitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:latLon.longitude destination:destination.longitude])
            {
                exists = YES;
                break;
            }
        }
        
        if (!exists)
        {
            [self addDestinationPin:destination.markerResourceName color:destination.color latitude:destination.latitude longitude:destination.longitude description:destination.desc];
            [_destinationLayerWidget drawLineArrowWidget:destination];
        }
    }
}

- (void) onDestinationHide:(id)observer withKey:(id)key
{
    OADestination *destination = key;
    
    if (destination)
    {
        for (const auto &marker : _destinationsMarkersCollection->getMarkers())
        {
            OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(marker->getPosition());
            if ([OAUtilities doublesEqualUpToDigits:5 source:latLon.latitude destination:destination.latitude] &&
                [OAUtilities doublesEqualUpToDigits:5 source:latLon.longitude destination:destination.longitude])
            {
                _destinationsMarkersCollection->removeMarker(marker);
                break;
            }
        }
    }
}

- (void) onDestinationsChange:(id)observable
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self drawDestinationLines];
    });
}

- (void) drawDestinationLines
{
    OAAppSettings *settings = OAAppSettings.sharedManager;
    if ([settings.directionLines get] && [OADestinationsHelper instance].sortedDestinations.count > 0)
    {
        NSArray *destinations = [OADestinationsHelper instance].sortedDestinations;
        OADestination *firstMarkerDestination = (destinations.count > 0 ? destinations[0] : nil);
        OADestination *secondMarkerDestination = (destinations.count > 1 ? destinations[1] : nil);
        CLLocation *currLoc = [self.app.locationServices lastKnownLocation];
        if (currLoc)
        {
            if (firstMarkerDestination)
                [self drawLine:firstMarkerDestination fromLocation:currLoc vectorLine:_firstLine vectorLine:_firstOutline mapMarker:_firstDistanceMarker];

            if (secondMarkerDestination && [settings.activeMarkers get] == TWO_ACTIVE_MARKERS)
            {
                [self drawLine:secondMarkerDestination fromLocation:currLoc vectorLine:_secondLine vectorLine:_secondOutline mapMarker:_secondDistanceMarker];
            }
            else
            {
                [self clearLine:_secondLine vectorLine:_secondOutline mapMarker:_secondDistanceMarker];
            }
        }
    }
    else
    {
        [self clearLine:_firstLine vectorLine:_firstOutline mapMarker:_firstDistanceMarker];
        [self clearLine:_secondLine vectorLine:_secondOutline mapMarker:_secondDistanceMarker];
        _distanceMarkersCollection->removeAllMarkers();
        _linesCollection->removeAllLines();
    }
}

- (void) clearLine:(std::shared_ptr<OsmAnd::VectorLine>&)line
        vectorLine:(std::shared_ptr<OsmAnd::VectorLine>&)outline
        mapMarker:(std::shared_ptr<OsmAnd::MapMarker>&)marker
{
    _linesCollection->removeLine(outline);
    _linesCollection->removeLine(line);

    _distanceMarkersCollection->removeMarker(marker);

    outline->detachMarker(marker);

    outline.reset();
    line.reset();
    marker.reset();
}

- (void) drawLine:(OADestination *)destination fromLocation:(CLLocation *)currLoc
        vectorLine:(std::shared_ptr<OsmAnd::VectorLine>&)line
        vectorLine:(std::shared_ptr<OsmAnd::VectorLine>&)outline
        mapMarker:(std::shared_ptr<OsmAnd::MapMarker>&)marker
{
    QVector<OsmAnd::PointI> points;
    points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(destination.latitude, destination.longitude)));
    points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(currLoc.coordinate.latitude, currLoc.coordinate.longitude)));

    double mapDensity = [[OAAppSettings sharedManager].mapDensity get];
    std::vector<double> outlinePattern;
    outlinePattern.push_back(75 / mapDensity);
    outlinePattern.push_back(55 / mapDensity);

    double strokeWidth = [_destinationLayerWidget getStrokeWidth];
    std::vector<double> inlinePattern;
    inlinePattern.push_back(-strokeWidth / 2 / mapDensity);
    inlinePattern.push_back((75 - strokeWidth) / mapDensity);
    inlinePattern.push_back((55 + strokeWidth) / mapDensity);

    const auto color = [destination.color toFColorARGB];
    const auto outlineColor = OsmAnd::FColorARGB(1.0, 1.0, 1.0, 1.0);
    if (line == nullptr || outline == nullptr)
    {
        OsmAnd::VectorLineBuilder outlineBuilder;
        outlineBuilder.setBaseOrder(self.baseOrder + 1);
        outline = outlineBuilder.buildAndAddToCollection(_linesCollection);

        OsmAnd::VectorLineBuilder inlineBuilder;
        inlineBuilder.setBaseOrder(self.baseOrder);
        line = inlineBuilder.buildAndAddToCollection(_linesCollection);
    }

    outline->setIsHidden(false);
    outline->setLineWidth(strokeWidth * 1.5);
    outline->setLineDash(outlinePattern);
    outline->setFillColor(outlineColor);

    line->setIsHidden(false);
    line->setLineWidth(strokeWidth);
    line->setLineDash(inlinePattern);
    line->setFillColor(color);

    if (_reconstructMarker)
    {
        // set empty points to trigger _hasUnappliedChanges
        outline->setPoints(QVector<OsmAnd::PointI>());
        _reconstructMarker = false;
    }

    if (points != outline->getPoints())
    {
        outline->setPoints(points);
        outline->detachMarker(marker);

        line->setPoints(points);

        _distanceMarkersCollection->removeMarker(marker);

        const auto dist = OsmAnd::Utilities::distance(destination.longitude, destination.latitude,
              currLoc.coordinate.longitude, currLoc.coordinate.latitude);
        NSString *distance = [OAOsmAndFormatter getFormattedDistance:dist];

        OsmAnd::MapMarkerBuilder distanceMarkerBuilder;
        distanceMarkerBuilder.setIsHidden(false);
        distanceMarkerBuilder.setBaseOrder(self.baseOrder - 1);
        distanceMarkerBuilder.setCaption([distance UTF8String]);
        distanceMarkerBuilder.setCaptionStyle(self.captionStyle);

        // We need to recreate marker each time as new caption needs new symbol
        marker = distanceMarkerBuilder.buildAndAddToCollection(_distanceMarkersCollection);
        marker->setOffsetFromLine(kLabelOffset);
        marker->setUpdateAfterCreated(true);

        outline->attachMarker(marker);
    }
}

- (BOOL) isMarkerOnWaypoint:(OADestination *)marker
{
    return marker && [OASelectedGPXHelper.instance getVisibleWayPointByLat:marker.latitude lon:marker.longitude];
}

- (BOOL) isMarkerOnFavorite:(OADestination *)marker
{
    return marker && [OAFavoritesHelper getVisibleFavByLat:marker.latitude lon:marker.longitude];
}

- (OAPOI *)getMapObjectByMarker:(OADestination *)marker
{
    if (!NSStringIsEmpty(marker.mapObjectName) && marker.latitude != 0 && marker.longitude != 0)
    {
        NSString *mapObjName = [marker.mapObjectName componentsSeparatedByString:@"_"][0];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:marker.latitude longitude:marker.longitude];
        return [OAMapSelectionHelper findAmenity:location names:@[mapObjName] obfId:-1 radius:15];
    }
    return nil;
}

#pragma mark - OAStateChangedListener

- (void) stateChanged:(id)change
{
    if (![change boolValue])
        return;
    
    [self.mapViewController runWithRenderSync:^{

        auto markers = _destinationsMarkersCollection->getMarkers();
        NSArray<OARTargetPoint *> *targets = [_targetPoints getAllPoints];
        for (auto marker : markers)
        {
            auto latLon = OsmAnd::Utilities::convert31ToLatLon(marker->getPosition());
            bool hide = false;
            for (OARTargetPoint *target in targets)
            {
                if ([OAUtilities isCoordEqual:latLon.latitude srcLon:latLon.longitude destLat:target.point.coordinate.latitude destLon:target.point.coordinate.longitude])
                {
                    hide = true;
                    break;
                }
            }
            if (hide && !marker->isHidden())
                marker->setIsHidden(true);
            if (!hide && marker->isHidden())
                marker->setIsHidden(false);
        }
        [self drawDestinationLines];
    }];
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:[OADestination class]])
    {
        OADestination *destination = (OADestination *)obj;
        
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.location = CLLocationCoordinate2DMake(destination.latitude, destination.longitude);
        targetPoint.title = destination.desc;
        
        targetPoint.icon = [UIImage imageNamed:destination.markerResourceName];
        targetPoint.type = OATargetDestination;
        
        targetPoint.targetObj = destination;
        
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        return targetPoint;
    }
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

- (void) collectObjectsFromPoint:(MapSelectionResult *)result unknownLocation:(BOOL)unknownLocation excludeUntouchableObjects:(BOOL)excludeUntouchableObjects
{
    NSMutableArray<OADestination *> *mapMarkers = self.app.data.destinations;
    if (excludeUntouchableObjects || NSArrayIsEmpty(mapMarkers))
        return;
    
    [_amenities removeAllObjects];
    
    CGPoint point = result.point;
    int radiusPixels = [self getScaledTouchRadius:[self getDefaultRadiusPoi]] * TOUCH_RADIUS_MULTIPLIER;
    
    QList<OsmAnd::PointI> touchPolygon31 = [OANativeUtilities getPolygon31FromPixelAndRadius:point radius:radiusPixels];
    if (touchPolygon31.isEmpty())
        return;
    
    OAAppSettings *settings = OAAppSettings.sharedManager;
    BOOL selectMarkerOnSingleTap = OAAppSettings.sharedManager.selectMarkerOnSingleTap;
    
    for (OADestination *marker in mapMarkers)
    {
        if (!unknownLocation && selectMarkerOnSingleTap)
        {
            BOOL shouldAdd = [OANativeUtilities isPointInsidePolygonLat:marker.latitude lon:marker.longitude polygon31:touchPolygon31];
            if (shouldAdd)
            {
                if (!unknownLocation && selectMarkerOnSingleTap)
                {
                    [result collect:marker provider:self];
                }
                else
                {
                    if (([self isMarkerOnFavorite:marker] && settings.mapSettingShowFavorites) ||
                        ([self isMarkerOnWaypoint:marker] && settings.showGpxWpt))
                    {
                        continue;
                    }
                    
                    OAPOI *mapObj = [self getMapObjectByMarker:marker];
                    if (mapObj)
                    {
                        [_amenities addObject:mapObj];
                        [result collect:mapObj provider:self];
                    }
                    else
                    {
                        [result collect:marker provider:self];
                    }
                }
            }
        
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

- (BOOL)isSecondaryProvider
{
    return NO;
}

- (CLLocation *) getObjectLocation:(id)obj
{
    if ([obj isKindOfClass:OADestination.class])
    {
        OADestination *point = (OADestination *)obj;
        return [[CLLocation alloc] initWithLatitude:[point latitude] longitude:[point longitude]];
    }
    else if ([obj isKindOfClass:OAPOI.class] && [_amenities containsObject:obj])
    {
        OAPOI *amenity = (OAPOI *)obj;
        return [amenity getLocation];
    }
    return nil;
}

- (OAPointDescription *) getObjectName:(id)obj
{
    if ([obj isKindOfClass:OADestination.class])
    {
        OADestination *point = (OADestination *)obj;
        return [point getPointDescription];
    }
    return nil;
}

#pragma mark - OAMoveObjectProvider

- (BOOL)isObjectMovable:(id)object
{
    return [object isKindOfClass:OADestination.class];
}

- (void)applyNewObjectPosition:(id)object position:(CLLocationCoordinate2D)position
{
    if (object && [self isObjectMovable:object])
    {
        OADestination *dest = (OADestination *)object;
        OADestination *destCopy = [dest copy];
        OADestinationsHelper *helper = [OADestinationsHelper instance];
        destCopy.latitude = position.latitude;
        destCopy.longitude = position.longitude;
        NSString *address = [[OAReverseGeocoder instance] lookupAddressAtLat:destCopy.latitude lon:destCopy.longitude];
        address = address && address.length > 0 ? address : [OAPointDescription getLocationNamePlain:destCopy.latitude lon:destCopy.longitude];
        destCopy.desc = address;
        [helper replaceDestination:dest withDestination:destCopy];
        [_destinationLayerWidget moveMarker:-1];
        [self drawDestinationLines];
    }
}

- (UIImage *)getPointIcon:(id)object
{
    if (object && [self isObjectMovable:object])
    {
        OADestination *item = (OADestination *)object;
        return [UIImage imageNamed:item.markerResourceName];
    }
    return nil;
}

- (void)setPointVisibility:(id)object hidden:(BOOL)hidden
{
    if (object && [self isObjectMovable:object])
    {
        OADestination *item = (OADestination *)object;
        const auto& pos = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(item.latitude, item.longitude));
        for (const auto& marker : _destinationsMarkersCollection->getMarkers())
        {
            if (pos == marker->getPosition())
            {
                marker->setIsHidden(hidden);
                [_destinationLayerWidget moveMarker:item.index];
            }
        }
    }
}

- (EOAPinVerticalAlignment) getPointIconVerticalAlignment
{
    return EOAPinAlignmentTop;
}


- (EOAPinHorizontalAlignment) getPointIconHorizontalAlignment
{
    return EOAPinAlignmentCenterHorizontal;
}

#pragma mark - LocationServicesUpdate

- (void) onLocationUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self drawDestinationLines];
    });
}

@end
