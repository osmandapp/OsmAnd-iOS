//
//  OAMapHudViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapModeHudViewController.h"
#import "UIViewController+JASidePanel.h"

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OAMapRendererViewController.h"

@interface OAMapModeHudViewController ()

@end

@implementation OAMapModeHudViewController
{
    OsmAndAppInstance _app;
    OAAutoObserverProxy* _mapModeObserver;
    OAAutoObserverProxy* _mapAzimuthObserver;
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
    _mapAzimuthObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onMapAzimuthChanged:withKey:andValue:)];
    [_mapAzimuthObserver observe:[OAMapRendererViewController instance].azimuthObservable];
}

- (void)dtor
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@synthesize compassBox = _compassBox;
@synthesize compassButton = _compassButton;
@synthesize compassImage = _compassImage;

@synthesize mapModeButton = _mapModeButton;

- (IBAction)onMapModeButtonClicked:(id)sender
{
    OAMapMode newMode = _app.mapMode;
    switch (_app.mapMode)
    {
        case OAMapModeFree:
            newMode = OAMapModePositionTrack;
            break;
            
        case OAMapModePositionTrack:
            // Perform switch to follow-mode only in case location services have compass
            if(_app.locationServices.compassPresent)
                newMode = OAMapModeFollow;
            break;
            
        case OAMapModeFollow:
            newMode = OAMapModePositionTrack;
            break;
    }
    
    // If user have denied location services for the application, show notification about that and
    // don't change the mode
    if(_app.locationServices.denied && (newMode == OAMapModePositionTrack || newMode == OAMapModeFollow))
    {
        [OALocationServices showDeniedAlert];
        return;
    }
    
    _app.mapMode = newMode;
}

- (void)onMapModeChanged
{
    UIImage* modeImage = nil;
    switch (_app.mapMode)
    {
        case OAMapModeFree:
            modeImage = [UIImage imageNamed:@"freeMapMode.png"];
            break;
            
        case OAMapModePositionTrack:
            modeImage = [UIImage imageNamed:@"positionTrackMapMode.png"];
            break;
            
        case OAMapModeFollow:
            modeImage = [UIImage imageNamed:@"followMapMode.png"];
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_mapModeButton setImage:modeImage forState:UIControlStateNormal];
    });
}

- (IBAction)onOptionsMenuButtonClicked:(id)sender
{
    [self.sidePanelController showLeftPanelAnimated:YES];
}

- (void)onMapAzimuthChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.compassImage.transform = CGAffineTransformMakeRotation(-[value floatValue] / 180.0f * M_PI);
    });
}

- (IBAction)onCompassButtonClicked:(id)sender
{
    [[OAMapRendererViewController instance] animatedAlignAzimuthToNorth];
}

@end
