//
//  OAMapRendererController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapRendererController.h"

#import "OAMapRendererView.h"

@interface OAMapRendererController ()

@end

@implementation OAMapRendererController

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
    /*
    // - Panning
    UIPanGestureRecognizer* grPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureDetected:)];
    [mapView addGestureRecognizer:grPan];
*/
    
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
    NSLog(@"zoom gesture %f %f", recognizer.scale, recognizer.velocity);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"MEMWARNING");
}

@end
