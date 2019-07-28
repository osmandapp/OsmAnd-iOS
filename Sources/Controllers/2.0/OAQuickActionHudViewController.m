//
//  OAQuickActionHudViewController.m
//  OsmAnd
//
//  Created by Paul on 7/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickActionHudViewController.h"
#import "OAAppSettings.h"

#import <AudioToolbox/AudioServices.h>

@interface OAQuickActionHudViewController ()
@property (weak, nonatomic) IBOutlet UIButton *quickActionFloatingButton;

@end

@implementation OAQuickActionHudViewController
{
    OAMapHudViewController *_mapHudController;
    
    OAAppSettings *_settings;
    
    UIPanGestureRecognizer *_buttonDragRecognizer;
}

- (instancetype) initWithMapHudViewController:(OAMapHudViewController *)mapHudController
{
    self = [super initWithNibName:@"OAQuickActionHudViewController"
                           bundle:nil];
    if (self)
    {
        _mapHudController = mapHudController;
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _quickActionFloatingButton.hidden = ![_settings.quickActionIsOn get];
    
    _buttonDragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onButtonDragged:)];
    [_buttonDragRecognizer setMaximumNumberOfTouches:1];
    [_quickActionFloatingButton addGestureRecognizer:_buttonDragRecognizer];
    
    [self setQuickActionButtonPosition];
}


// Android counterpart: setQuickActionButtonMargin()
- (void) setQuickActionButtonPosition
{
    CGFloat x, y;
    CGFloat w = _quickActionFloatingButton.frame.size.width;
    CGFloat h = _quickActionFloatingButton.frame.size.height;
    BOOL isLandscape = [self isLandscape];
    if (isLandscape)
    {
        x = _settings.quickActionLandscapeX;
        y = _settings.quickActionLandscapeY;
    }
    else
    {
        x = _settings.quickActionPortraitX;
        y = _settings.quickActionPortraitY;
    }
    if (x == 0. && y == 0.)
    {
        if (isLandscape)
        {
            x = _mapHudController.mapModeButton.frame.origin.x - w;
            y = _mapHudController.mapModeButton.frame.origin.y;
        }
        else
        {
            x = _mapHudController.zoomButtonsView.frame.origin.x;
            y = _mapHudController.zoomButtonsView.frame.origin.y - h;
        }
    }
    _quickActionFloatingButton.frame = CGRectMake(x, y, w, h);
}

- (void)viewWillLayoutSubviews
{
    [self setQuickActionButtonPosition];
}

- (void)moveToPoint:(CGPoint)newPosition
{
    CGSize size = _quickActionFloatingButton.frame.size;
    _quickActionFloatingButton.frame = CGRectMake(newPosition.x - size.width / 2, newPosition.y - size.height / 2, _quickActionFloatingButton.frame.size.width, _quickActionFloatingButton.frame.size.height);
}

- (void) onButtonDragged:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        _quickActionFloatingButton.transform = CGAffineTransformMakeScale(1.5, 1.5);
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        [self moveToPoint:[recognizer locationInView:self.view]];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        [self moveToPoint:[recognizer locationInView:self.view]];
        _quickActionFloatingButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
        CGPoint pos = _quickActionFloatingButton.frame.origin;
        if ([self isLandscape])
            [_settings setQuickActionCoordinatesLandscape:pos.x y:pos.y];
        else
            [_settings setQuickActionCoordinatesPortrait:pos.x y:pos.y];
    }
}

- (BOOL) isLandscape
{
    UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
    return orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight;
}


@end
