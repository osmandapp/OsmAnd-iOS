//
//  OABrowseMapAppModeHudViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OABrowseMapAppModeHudViewController.h"
#import "OAAppSettings.h"
#import "OAMapRulerView.h"

#import <JASidePanelController.h>
#import <UIViewController+JASidePanel.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OAMapViewController.h"
#if defined(OSMAND_IOS_DEV)
#   import "OADebugHudViewController.h"
#endif // defined(OSMAND_IOS_DEV)
#import "OARootViewController.h"

#define _(name) OAMapModeHudViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

@interface OABrowseMapAppModeHudViewController ()

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

@property (strong, nonatomic) IBOutlet OAMapRulerView *rulerLabel;


@end

@implementation OABrowseMapAppModeHudViewController
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _mapModeObserver;
    OAAutoObserverProxy* _mapAzimuthObserver;
    OAAutoObserverProxy* _mapZoomObserver;

    OAMapViewController* _mapViewController;

#if defined(OSMAND_IOS_DEV)
    OADebugHudViewController* _debugHudViewController;
#endif // defined(OSMAND_IOS_DEV)
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc
{
    [self deinit];
}

- (void)commonInit
{
    _app = [OsmAndApp instance];

    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    
    _mapModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapModeChanged)
                                                  andObserve:_app.mapModeObservable];
    _mapAzimuthObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                    withHandler:@selector(onMapAzimuthChanged:withKey:andValue:)
                                                     andObserve:_mapViewController.azimuthObservable];
    _mapZoomObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapZoomChanged:withKey:andValue:)
                                                  andObserve:_mapViewController.zoomObservable];
}

- (void)deinit
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    if (_app.mapMode == OAMapModeFollow || _app.mapMode == OAMapModePositionTrack)
        _driveModeButton.hidden = NO;
    else
        _driveModeButton.hidden = YES;

    _compassImage.transform = CGAffineTransformMakeRotation(-_mapViewController.mapRendererView.azimuth / 180.0f * M_PI);
    _zoomInButton.enabled = [_mapViewController canZoomIn];
    
    UIImageView *backgroundViewIn = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD_button_bg"]];
    [backgroundViewIn setFrame:CGRectMake(_zoomInButton.frame.origin.x + 8, _zoomInButton.frame.origin.y, _zoomInButton.frame.size.width - 16, _zoomInButton.frame.size.height)];
    [_zoomInButton.superview insertSubview:backgroundViewIn belowSubview:_zoomInButton];
    
    UIImageView *backgroundViewOut = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD_button_bg"]];
    [backgroundViewOut setFrame:CGRectMake(_zoomOutButton.frame.origin.x + 8, _zoomOutButton.frame.origin.y, _zoomOutButton.frame.size.width - 16, _zoomOutButton.frame.size.height)];
    [_zoomOutButton.superview insertSubview:backgroundViewOut belowSubview:_zoomOutButton];
    
    _zoomOutButton.enabled = [_mapViewController canZoomOut];
    
    self.rulerLabel = [[OAMapRulerView alloc] initWithFrame:CGRectMake(50, DeviceScreenHeight - 40, kMapRulerMinWidth, 25)];
    self.rulerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.rulerLabel];
    
    
    // Constraints
    NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:self.rulerLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:-15.0f];
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.rulerLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0f constant:50.0f];
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.rulerLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:25];
    [self.view addConstraint:constraint];
    


#if !defined(OSMAND_IOS_DEV)
    _debugButton.hidden = YES;
#endif // !defined(OSMAND_IOS_DEV)
}

-(void)viewWillAppear:(BOOL)animated {
    [self.rulerLabel setHidden: ![[OAAppSettings sharedManager] settingShowMapRulet]];
}

-(void)viewDidAppear:(BOOL)animated {
    [self.rulerLabel setHidden: ![[OAAppSettings sharedManager] settingShowMapRulet]];
}

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
            if (_app.locationServices.compassPresent)
                newMode = OAMapModeFollow;
            break;
            
        case OAMapModeFollow:
            newMode = OAMapModePositionTrack;
            break;

        default:
            return;
    }
    
    // If user have denied location services for the application, show notification about that and
    // don't change the mode
    if (_app.locationServices.denied && (newMode == OAMapModePositionTrack || newMode == OAMapModeFollow))
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

        default:
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_app.mapMode == OAMapModeFollow || _app.mapMode == OAMapModePositionTrack)
            _driveModeButton.hidden = NO;
        else
            _driveModeButton.hidden = YES;
        
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
    [_mapViewController animatedAlignAzimuthToNorth];
}

- (IBAction)onZoomInButtonClicked:(id)sender
{
    [_mapViewController animatedZoomIn];
}

- (IBAction)onZoomOutButtonClicked:(id)sender
{
    [_mapViewController animatedZoomOut];
    [_mapViewController calculateMapRuler];
}

- (void)onMapZoomChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _zoomInButton.enabled = [_mapViewController canZoomIn];
        _zoomOutButton.enabled = [_mapViewController canZoomOut];
        
        [self.rulerLabel setRulerData:[_mapViewController calculateMapRuler]];
    });
}

- (IBAction)onDriveModeButtonClicked:(id)sender
{
    _app.appMode = OAAppModeDrive;
}

- (IBAction)onActionsMenuButtonClicked:(id)sender
{
    [self.sidePanelController showRightPanelAnimated:YES];
}

- (IBAction)onDebugButtonClicked:(id)sender
{
#if defined(OSMAND_IOS_DEV)
    if (_debugHudViewController == nil)
    {
        _debugHudViewController = [OADebugHudViewController attachTo:self];
    }
    else
    {
        [_debugHudViewController.view removeFromSuperview];
        [_debugHudViewController removeFromParentViewController];
        _debugHudViewController = nil;
    }
#endif // defined(OSMAND_IOS_DEV)
}

@end
