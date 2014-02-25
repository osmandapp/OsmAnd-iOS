//
//  OAMapHudViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapHudViewController.h"
#import "UIViewController+JASidePanel.h"

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"

@interface OAMapHudViewController ()

@end

@implementation OAMapHudViewController
{
    OsmAndAppInstance _app;
    OAAutoObserverProxy* _mapModeObserver;
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
    switch (_app.mapMode)
    {
        case OAMapModeFree:
            _app.mapMode = OAMapModePositionTrack;
            break;
            
        case OAMapModePositionTrack:
            _app.mapMode = OAMapModeFollow;
            break;
            
        case OAMapModeFollow:
            _app.mapMode = OAMapModePositionTrack;
            break;
            
        default:
            break;
    }
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
            
        default:
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

- (IBAction)onCompassButtonClicked:(id)sender
{
}

@end
