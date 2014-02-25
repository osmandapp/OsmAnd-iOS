//
//  OAMapRendererController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapRendererViewController.h"

#import "OsmAndApp.h"
#import "OAMapRendererView.h"
#import "OAAutoObserverProxy.h"

#include <QtMath>
#include <QStandardPaths>
#include <OsmAndCore/Map/OnlineMapRasterTileProvider.h>
#include <OsmAndCore/Map/OfflineMapDataProvider.h>
#include <OsmAndCore/Map/OfflineMapRasterTileProvider_Software.h>
#include <OsmAndCore/Map/OfflineMapSymbolProvider.h>

#include "ExternalResourcesProvider.h"

#define kElevationGestureMaxThreshold 50
#define kElevationGestureMinAngle 30
#define kElevationGesturePointsPerDegree 3
#define kRotationGestureThresholdDegrees 5
#define kZoomDeceleration 40.0f
#define kTargetMoveDeceleration 4800.0f
#define kRotateDeceleration 500.0f

@interface OAMapRendererViewController ()

@end

@implementation OAMapRendererViewController
{
    OsmAndAppInstance _app;
    
    OAAutoObserverProxy* _mapModeObserver;
    
    UIPinchGestureRecognizer* _grZoom;
    CGFloat _initialZoomLevelDuringGesture;

    UIPanGestureRecognizer* _grMove;
    
    UIRotationGestureRecognizer* _grRotate;
    CGFloat _accumulatedRotationAngle;
    
    UITapGestureRecognizer* _grZoomIn;
    
    UITapGestureRecognizer* _grZoomOut;
    
    UIPanGestureRecognizer* _grElevation;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor
{
    _app = [OsmAndApp instance];
    _mapModeObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onMapModeChanged)];
    [_mapModeObserver observe:_app.mapModeObservable];
    
    // Create gesture recognizers:
    
    // - Zoom gesture
    _grZoom = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomGestureDetected:)];
    _grZoom.delegate = self;
    
    // - Move gesture
    _grMove = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveGestureDetected:)];
    _grMove.delegate = self;
    
    // - Rotation gesture
    _grRotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateGestureDetected:)];
    _grRotate.delegate = self;
    
    // - Zoom-in gesture
    _grZoomIn = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomInGestureDetected:)];
    _grZoomIn.delegate = self;
    _grZoomIn.numberOfTapsRequired = 2;
    _grZoomIn.numberOfTouchesRequired = 1;
    
    // - Zoom-out gesture
    _grZoomOut = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomOutGestureDetected:)];
    _grZoomOut.delegate = self;
    _grZoomOut.numberOfTapsRequired = 2;
    _grZoomOut.numberOfTouchesRequired = 2;
    
    // - Elevation gesture
    _grElevation = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(elevationGestureDetected:)];
    _grElevation.delegate = self;
    _grElevation.minimumNumberOfTouches = 2;
    _grElevation.maximumNumberOfTouches = 2;
}

- (void)dtor
{
    // Allow view to tear down OpenGLES context
    if([self isViewLoaded])
    {
        OAMapRendererView* mapView = (OAMapRendererView*)self.view;
        [mapView releaseContext];
    }
}

- (void)loadView
{
#if defined(DEBUG)
    NSLog(@"Creating Map Renderer view...");
#endif
    
    // Inflate map renderer view
    OAMapRendererView* view = [[OAMapRendererView alloc] init];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.contentScaleFactor = [[UIScreen mainScreen] scale];
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Tell view to create context
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    mapView.userInteractionEnabled = YES;
    mapView.multipleTouchEnabled = YES;
    [mapView createContext];
    
    // Attach gesture recognizers:
    [mapView addGestureRecognizer:_grZoom];
    [mapView addGestureRecognizer:_grMove];
    [mapView addGestureRecognizer:_grRotate];
    [mapView addGestureRecognizer:_grZoomIn];
    [mapView addGestureRecognizer:_grZoomOut];
    [mapView addGestureRecognizer:_grElevation];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Resume rendering
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    [mapView resumeRendering];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if(![self isViewLoaded])
        return;

    // Suspend rendering
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    [mapView suspendRendering];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if(![self isViewLoaded])
        return NO;
    
    if(gestureRecognizer == _grElevation)
    {
        // Elevation gesture recognizer requires 2 touch points
        if(gestureRecognizer.numberOfTouches != 2)
            return NO;

        // Calculate vertical distance between touches
        const auto touch1 = [gestureRecognizer locationOfTouch:0 inView:self.view];
        const auto touch2 = [gestureRecognizer locationOfTouch:1 inView:self.view];
        const auto verticalDistance = fabsf(touch1.y - touch2.y);

        // Ignore this touch if vertical distance is too large
        if(verticalDistance >= kElevationGestureMaxThreshold)
        {
#if defined(DEBUG)
            NSLog(@"Elevation gesture ignored due to vertical distance %f", verticalDistance);
#endif
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // Elevation gesture recognizer should not be mixed with others
    if(gestureRecognizer == _grElevation || otherGestureRecognizer == _grElevation)
        return NO;
    
    return YES;
}

- (void)zoomGestureDetected:(UIPinchGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    // If gesture has just began, just capture current zoom
    if(recognizer.state == UIGestureRecognizerStateBegan)
    {
        [mapView cancelAnimation];
        _app.mapMode = OAMapModeFree;
        
        _initialZoomLevelDuringGesture = mapView.zoom;
        return;
    }
    
    // If gesture has been cancelled or failed, restore previous zoom
    if(recognizer.state == UIGestureRecognizerStateFailed || recognizer.state == UIGestureRecognizerStateCancelled)
    {
        mapView.zoom = _initialZoomLevelDuringGesture;
        return;
    }
    
    // Capture current touch center point
    CGPoint centerPoint = [recognizer locationOfTouch:0 inView:self.view];
    for(NSInteger touchIdx = 1; touchIdx < recognizer.numberOfTouches; touchIdx++)
    {
        CGPoint touchPoint = [recognizer locationOfTouch:touchIdx inView:self.view];
        
        centerPoint.x += touchPoint.x;
        centerPoint.y += touchPoint.y;
    }
    centerPoint.x /= recognizer.numberOfTouches;
    centerPoint.y /= recognizer.numberOfTouches;
    centerPoint.x *= mapView.contentScaleFactor;
    centerPoint.y *= mapView.contentScaleFactor;
    OsmAnd::PointI centerLocationBefore;
    [mapView convert:centerPoint toLocation:&centerLocationBefore];
    
    // Change zoom
    mapView.zoom = _initialZoomLevelDuringGesture - (1.0f - recognizer.scale);
    
    // Adjust current target position to keep touch center the same
    OsmAnd::PointI centerLocationAfter;
    [mapView convert:centerPoint toLocation:&centerLocationAfter];
    const auto centerLocationDelta = centerLocationAfter - centerLocationBefore;
    [mapView setTarget31:mapView.target31 - centerLocationDelta];
    
    // If this is the end of gesture, get velocity for animation
    if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        [mapView animateZoomWith:recognizer.velocity andDeceleration:kZoomDeceleration];
        [mapView resumeAnimation];
    }
}

- (void)moveGestureDetected:(UIPanGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    if(recognizer.state == UIGestureRecognizerStateBegan)
    {
        [mapView cancelAnimation];
        _app.mapMode = OAMapModeFree;
    }
    
    // Get movement delta in points (not pixels, that is for retina and non-retina devices value is the same)
    CGPoint translation = [recognizer translationInView:self.view];
    translation.x *= mapView.contentScaleFactor;
    translation.y *= mapView.contentScaleFactor;

    // Take into account current azimuth and reproject to map space (points)
    const float angle = qDegreesToRadians(mapView.azimuth);
    const float cosAngle = cosf(angle);
    const float sinAngle = sinf(angle);
    CGPoint translationInMapSpace;
    translationInMapSpace.x = translation.x * cosAngle - translation.y * sinAngle;
    translationInMapSpace.y = translation.x * sinAngle + translation.y * cosAngle;

    // Taking into account current zoom, get how many 31-coordinates there are in 1 point
    const uint32_t tileSize31 = (1u << (31 - mapView.zoomLevel));
    const double scale31 = static_cast<double>(tileSize31) / mapView.scaledTileSizeOnScreen;

    // Rescale movement to 31 coordinates
    OsmAnd::PointI target31 = mapView.target31;
    target31.x -= static_cast<int32_t>(round(translationInMapSpace.x * scale31));
    target31.y -= static_cast<int32_t>(round(translationInMapSpace.y * scale31));
    mapView.target31 = target31;
    
    if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        // Obtain velocity from recognizer
        CGPoint screenVelocity = [recognizer velocityInView:self.view];
        screenVelocity.x *= mapView.contentScaleFactor;
        screenVelocity.y *= mapView.contentScaleFactor;
        
        // Take into account current azimuth and reproject to map space (points)
        CGPoint velocityInMapSpace;
        velocityInMapSpace.x = screenVelocity.x * cosAngle - screenVelocity.y * sinAngle;
        velocityInMapSpace.y = screenVelocity.x * sinAngle + screenVelocity.y * cosAngle;
        
        // Rescale speed to 31 coordinates
        OsmAnd::PointD velocity;
        velocity.x = -velocityInMapSpace.x * scale31;
        velocity.y = -velocityInMapSpace.y * scale31;
        
        [mapView animateTargetWith:velocity andDeceleration:OsmAnd::PointD(kTargetMoveDeceleration * scale31, kTargetMoveDeceleration * scale31)];
        [mapView resumeAnimation];
    }
    [recognizer setTranslation:CGPointZero inView:self.view];
}

- (void)rotateGestureDetected:(UIRotationGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    // Zeroify accumulated rotation on gesture begin
    if(recognizer.state == UIGestureRecognizerStateBegan)
    {
        [mapView cancelAnimation];
        _app.mapMode = OAMapModeFree;
        
        _accumulatedRotationAngle = 0.0f;
    }
    
    // Check if accumulated rotation is greater than threshold
    if(fabs(_accumulatedRotationAngle) < kRotationGestureThresholdDegrees)
    {
        _accumulatedRotationAngle += qRadiansToDegrees(recognizer.rotation);
        [recognizer setRotation:0];

        return;
    }
    
    // Get center of all touches as centroid
    CGPoint centerPoint = [recognizer locationOfTouch:0 inView:self.view];
    for(NSInteger touchIdx = 1; touchIdx < recognizer.numberOfTouches; touchIdx++)
    {
        CGPoint touchPoint = [recognizer locationOfTouch:touchIdx inView:self.view];
        
        centerPoint.x += touchPoint.x;
        centerPoint.y += touchPoint.y;
    }
    centerPoint.x /= recognizer.numberOfTouches;
    centerPoint.y /= recognizer.numberOfTouches;
    centerPoint.x *= mapView.contentScaleFactor;
    centerPoint.y *= mapView.contentScaleFactor;
    
    // Convert point from screen to location
    OsmAnd::PointI centerLocation;
    [mapView convert:centerPoint toLocation:&centerLocation];
    
    // Rotate current target around center location
    OsmAnd::PointI target = mapView.target31;
    target -= centerLocation;
    OsmAnd::PointI newTarget;
    const float cosAngle = cosf(-recognizer.rotation);
    const float sinAngle = sinf(-recognizer.rotation);
    newTarget.x = target.x * cosAngle - target.y * sinAngle;
    newTarget.y = target.x * sinAngle + target.y * cosAngle;
    newTarget += centerLocation;
    mapView.target31 = newTarget;
    
    // Set rotation
    mapView.azimuth -= qRadiansToDegrees(recognizer.rotation);
    
    if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        [mapView animateAzimuthWith:-qRadiansToDegrees(recognizer.velocity) andDeceleration:kRotateDeceleration];
        [mapView resumeAnimation];
    }
    [recognizer setRotation:0];
}

- (void)zoomInGestureDetected:(UITapGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;

    // Handle gesture only when it is ended
    if(recognizer.state != UIGestureRecognizerStateEnded)
        return;
    
    // Cancel animation (if any)
    [mapView cancelAnimation];
    _app.mapMode = OAMapModeFree;
    
    // Put tap location to center of screen
    CGPoint centerPoint = [recognizer locationOfTouch:0 inView:self.view];
    centerPoint.x *= mapView.contentScaleFactor;
    centerPoint.y *= mapView.contentScaleFactor;
    OsmAnd::PointI centerLocation;
    [mapView convert:centerPoint toLocation:&centerLocation];
    OsmAnd::PointI currentLocation = mapView.target31;
    OsmAnd::PointI64 deltaMovement;
    deltaMovement.x = static_cast<int64_t>(centerLocation.x) - static_cast<int64_t>(currentLocation.x);
    deltaMovement.y = static_cast<int64_t>(centerLocation.y) - static_cast<int64_t>(currentLocation.y);
    [mapView animateTargetBy64:deltaMovement during:1.0f];
    
    // Increate zoom by 1 using animation
    [mapView animateZoomBy:1.0f during:1.0f];
    
    // Launch animation
    [mapView resumeAnimation];
}

- (void)zoomOutGestureDetected:(UITapGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    // Handle gesture only when it is ended
    if(recognizer.state != UIGestureRecognizerStateEnded)
        return;

    // Cancel animation (if any)
    [mapView cancelAnimation];
    _app.mapMode = OAMapModeFree;
    
    // Put tap location to center of screen
    CGPoint centerPoint = [recognizer locationOfTouch:0 inView:self.view];
    for(NSInteger touchIdx = 1; touchIdx < recognizer.numberOfTouches; touchIdx++)
    {
        CGPoint touchPoint = [recognizer locationOfTouch:touchIdx inView:self.view];
        
        centerPoint.x += touchPoint.x;
        centerPoint.y += touchPoint.y;
    }
    centerPoint.x /= recognizer.numberOfTouches;
    centerPoint.y /= recognizer.numberOfTouches;
    centerPoint.x *= mapView.contentScaleFactor;
    centerPoint.y *= mapView.contentScaleFactor;
    OsmAnd::PointI centerLocation;
    [mapView convert:centerPoint toLocation:&centerLocation];
    OsmAnd::PointI currentLocation = mapView.target31;
    OsmAnd::PointI64 deltaMovement;
    deltaMovement.x = static_cast<int64_t>(centerLocation.x) - static_cast<int64_t>(currentLocation.x);
    deltaMovement.y = static_cast<int64_t>(centerLocation.y) - static_cast<int64_t>(currentLocation.y);
    [mapView animateTargetBy64:deltaMovement during:1.0f];
    
    // Decrease zoom by 1
    [mapView animateZoomBy:-1.0f during:1.0f];
    
    // Launch animation
    [mapView resumeAnimation];
}

- (void)elevationGestureDetected:(UIPanGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    CGPoint translation = [recognizer translationInView:self.view];
    CGFloat angleDelta = translation.y / static_cast<CGFloat>(kElevationGesturePointsPerDegree);
    CGFloat angle = mapView.elevationAngle;
    angle -= angleDelta;
    if(angle < kElevationGestureMinAngle)
        angle = kElevationGestureMinAngle;
    mapView.elevationAngle = angle;
    [recognizer setTranslation:CGPointZero inView:self.view];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"MEMWARNING");
}

- (void)activateMapnik
{
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    std::shared_ptr<OsmAnd::IMapBitmapTileProvider> tileProvider = OsmAnd::OnlineMapRasterTileProvider::createMapnikProvider();
    OsmAnd::OnlineMapRasterTileProvider* onlineTileProvider = dynamic_cast<OsmAnd::OnlineMapRasterTileProvider*>(tileProvider.get());
    onlineTileProvider->setLocalCachePath(QDir(QDir(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)).filePath("Mapnik cache")));
    [mapView setProvider:tileProvider ofLayer:OsmAnd::RasterMapLayerId::BaseLayer];
    mapView.azimuth = 0.0f;
    mapView.elevationAngle = 90.0f;
    mapView.target31 = OsmAnd::PointI(1102430866, 704978668);
    mapView.zoom = 10.0f;
}

- (void)activateCyclemap
{
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    std::shared_ptr<OsmAnd::IMapBitmapTileProvider> tileProvider = OsmAnd::OnlineMapRasterTileProvider::createCycleMapProvider();
    OsmAnd::OnlineMapRasterTileProvider* onlineTileProvider = dynamic_cast<OsmAnd::OnlineMapRasterTileProvider*>(tileProvider.get());
    onlineTileProvider->setLocalCachePath(QDir(QDir(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)).filePath("CycleMap cache")));
    [mapView setProvider:tileProvider ofLayer:OsmAnd::RasterMapLayerId::BaseLayer];
    mapView.azimuth = 0.0f;
    mapView.elevationAngle = 90.0f;
    mapView.target31 = OsmAnd::PointI(1102430866, 704978668);
    mapView.zoom = 10.0f;
}

- (void)activateOffline
{
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    std::shared_ptr<const OsmAnd::MapStyle> mapStyle;
    _app.mapStyles->obtainStyle("default", mapStyle);
    std::shared_ptr<OsmAnd::OfflineMapDataProvider> offlineMapDP(new OsmAnd::OfflineMapDataProvider(_app.obfsCollection, mapStyle, mapView.contentScaleFactor, std::shared_ptr<OsmAnd::IExternalResourcesProvider>(new ExternalResourcesProvider(mapView.contentScaleFactor > 1.0f))));
    
    std::shared_ptr<OsmAnd::IMapBitmapTileProvider> tileProvider(new OsmAnd::OfflineMapRasterTileProvider_Software(offlineMapDP, 256 * mapView.contentScaleFactor, mapView.contentScaleFactor));
    [mapView setProvider:tileProvider ofLayer:OsmAnd::RasterMapLayerId::BaseLayer];
    
    std::shared_ptr<OsmAnd::IMapSymbolProvider> symbolProvider(new OsmAnd::OfflineMapSymbolProvider(offlineMapDP));
    [mapView addSymbolProvider:symbolProvider];
    
    mapView.azimuth = 0.0f;
    mapView.elevationAngle = 90.0f;
    mapView.target31 = OsmAnd::PointI(1102430866, 704978668);
    mapView.zoom = 10.0f;
}

- (void)onMapModeChanged
{
    switch (_app.mapMode)
    {
        case OAMapModeFree:
            // Do nothing
            return;
            
        case OAMapModePositionTrack:
            //TODO: animate view to last known location (if it's available)
            break;
            
        case OAMapModeFollow:
            //TODO: animate view to last known location + change blablabla (if it's available)
            break;
            
        default:
            break;
    }
}

@end
