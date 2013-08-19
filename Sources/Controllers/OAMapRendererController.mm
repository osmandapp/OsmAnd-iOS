//
//  OAMapRendererController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapRendererController.h"

#import "OAMapRendererView.h"

#include <QtMath>

@interface OAMapRendererController ()

@end

@implementation OAMapRendererController
{
    float _initialZoomLevelDuringPinch;
    OsmAnd::PointI _initialPositionDuringMove;
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
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

- (void)ctor
{
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
    NSLog(@"Creating Map Renderer View...");
    
    // Inflate map renderer view
    OAMapRendererView* view = [[OAMapRendererView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.contentScaleFactor = [[UIScreen mainScreen] scale];
    self.view = view;
#if !__has_feature(objc_arc)
    [view release];
#endif
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return TRUE;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Tell view to create context
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    [mapView createContext];
    
    // Attach gesture recognizers:
    mapView.userInteractionEnabled = YES;
    
    // - Zoom gesture
    UIPinchGestureRecognizer* grZoom = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomGestureDetected:)];
    [mapView addGestureRecognizer:grZoom];

    // - Move gesture
    UIPanGestureRecognizer* grMove = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveGestureDetected:)];
    grMove.minimumNumberOfTouches = 1;
    grMove.maximumNumberOfTouches = 1;
    [mapView addGestureRecognizer:grMove];
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

- (void)zoomGestureDetected:(UIPinchGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    if(recognizer.state == UIGestureRecognizerStateBegan)
    {
        // Save initial value of zoom
    }
    else if(recognizer.state == UIGestureRecognizerStateChanged)
    {
        mapView.mapRenderer->setZoom(_initialZoomLevelDuringPinch - (1.0f - recognizer.scale));
    }
    else if(recognizer.state == UIGestureRecognizerStateCancelled)
    {
        // Since gesture was cancelled, restore initial zoom
        mapView.mapRenderer->setZoom(_initialZoomLevelDuringPinch);
    }
    else if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        float initialZoomLevelForAnimation = _initialZoomLevelDuringPinch - (1.0f - recognizer.scale);
        //TODO: proceed gesture with given velocity
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
        // Save initial position of moving
    }
    else if(recognizer.state == UIGestureRecognizerStateChanged)
    {
        // Get movement delta in points (not pixels, that is for retina and non-retina devices value is the same)
        /*CGPoint translation = [recognizer translationInView:recognizer.view];
        translation.x *= mapView.contentScaleFactor;
        translation.y *= mapView.contentScaleFactor;

        // Take into account current azimuth and reproject to map space (points)
        const float angle = qDegreesToRadians(mapView.mapRenderer->configuration.azimuth);
        const float cosAngle = cosf(angle);
        const float sinAngle = sinf(angle);
        CGPoint translationInMapSpace;
        translationInMapSpace.x = translation.x * cosAngle - translation.y * sinAngle;
        translationInMapSpace.y = translation.x * sinAngle + translation.y * cosAngle;

        // Taking into account current zoom, get how many 31-coordinates there are in 1 point
        int32_t tileSize31 = 1;
        if(mapView.mapRenderer->configuration.zoomBase != 31)
            tileSize31 = (1u << (31 - mapView.mapRenderer->configuration.zoomBase)) - 1;
        const double scale31 = static_cast<double>(tileSize31) / mapView.mapRenderer->getScaledTileSizeOnScreen();

        // Rescale movement to 31 coordinates
        OsmAnd::PointI newTarget31;
        newTarget31.x = _initialPositionDuringMove.x - static_cast<int32_t>(round(translationInMapSpace.x * scale31));
        newTarget31.y = _initialPositionDuringMove.y - static_cast<int32_t>(round(translationInMapSpace.y * scale31));

        mapView.mapRenderer->setTarget(newTarget31);*/
    }
    else if(recognizer.state == UIGestureRecognizerStateCancelled)
    {
        // Since gesture was cancelled, restore initial target
        //mapView.mapRenderer->setTarget(_initialPositionDuringMove);
    }
    else if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        //float initialZoomLevelForAnimation = _initialZoomLevelDuringPinch - (1.0f - recognizer.scale);
        //TODO: proceed gesture with given velocity
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"MEMWARNING");
}

@end
