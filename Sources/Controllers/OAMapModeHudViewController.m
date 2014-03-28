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
#import "OADebugHudViewController.h"
#import "UIView+VisibilityAndInput.h"

@interface OAMapModeHudViewController ()

@property (weak, nonatomic) IBOutlet UIView *compassBox;
@property (weak, nonatomic) IBOutlet UIButton *compassButton;
@property (weak, nonatomic) IBOutlet UIImageView *compassImage;
@property (weak, nonatomic) IBOutlet UIButton *mapModeButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomInButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomOutButton;
@property (weak, nonatomic) IBOutlet UIButton *driveModeButton;
@property (weak, nonatomic) IBOutlet UIButton *debugButton;
@property (weak, nonatomic) IBOutlet UITextField *searchQueryTextfield;
@property (weak, nonatomic) IBOutlet UIButton *optionsMenuButton;
@property (weak, nonatomic) IBOutlet UIButton *actionsMenuButton;

@end

@implementation OAMapModeHudViewController
{
    OsmAndAppInstance _app;
    OAAutoObserverProxy* _mapModeObserver;
    OAAutoObserverProxy* _mapAzimuthObserver;
    OAAutoObserverProxy* _mapZoomObserver;

    OADebugHudViewController* _debugHudViewController;
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
    
    _mapModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapModeChanged)];
    [_mapModeObserver observe:_app.mapModeObservable];
    
    _mapAzimuthObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                    withHandler:@selector(onMapAzimuthChanged:withKey:andValue:)];
    [_mapAzimuthObserver observe:[OAMapRendererViewController instance].azimuthObservable];
    
    _mapZoomObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                    withHandler:@selector(onMapZoomChanged:withKey:andValue:)];
    [_mapZoomObserver observe:[OAMapRendererViewController instance].zoomObservable];
}

- (void)dtor
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    if(_app.mapMode == OAMapModeFollow || _app.mapMode == OAMapModePositionTrack)
        [_driveModeButton showAndEnableInput];
    else
        [_driveModeButton hideAndDisableInput];
    
    _zoomInButton.enabled = [[OAMapRendererViewController instance] canZoomIn];
    _zoomOutButton.enabled = [[OAMapRendererViewController instance] canZoomOut];
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
            modeImage = [UIImage imageNamed:@"free_map_mode_button.png"];
            break;
            
        case OAMapModePositionTrack:
            modeImage = [UIImage imageNamed:@"position_track_map_mode_button.png"];
            break;
            
        case OAMapModeFollow:
            modeImage = [UIImage imageNamed:@"follow_map_mode_button.png"];
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(_app.mapMode == OAMapModeFollow || _app.mapMode == OAMapModePositionTrack)
            [_driveModeButton showAndEnableInput];
        else
            [_driveModeButton hideAndDisableInput];
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
        _compassImage.transform = CGAffineTransformMakeRotation(-[value floatValue] / 180.0f * M_PI);
    });
}

- (IBAction)onCompassButtonClicked:(id)sender
{
    [[OAMapRendererViewController instance] animatedAlignAzimuthToNorth];
}

- (IBAction)onZoomInButtonClicked:(id)sender
{
    [[OAMapRendererViewController instance] animatedZoomIn];
}

- (IBAction)onZoomOutButtonClicked:(id)sender
{
    [[OAMapRendererViewController instance] animatedZoomOut];
}

- (void)onMapZoomChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _zoomInButton.enabled = [[OAMapRendererViewController instance] canZoomIn];
        _zoomOutButton.enabled = [[OAMapRendererViewController instance] canZoomOut];
    });
}

- (IBAction)onDriveModeButtonClicked:(id)sender
{
}

- (IBAction)onActionsMenuButtonClicked:(id)sender
{
}

- (IBAction)onDebugButtonClicked:(id)sender
{
    if(_debugHudViewController == nil)
    {
        _debugHudViewController = [[OADebugHudViewController alloc] initWithNibName:@"DebugHUD" bundle:nil];
        [self addChildViewController:_debugHudViewController];
        _debugHudViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _debugHudViewController.view.frame = self.view.frame;
        [self.view addSubview:_debugHudViewController.view];
    }
    else
    {
        [_debugHudViewController.view removeFromSuperview];
        [_debugHudViewController removeFromParentViewController];
        _debugHudViewController = nil;
    }
}

@end
