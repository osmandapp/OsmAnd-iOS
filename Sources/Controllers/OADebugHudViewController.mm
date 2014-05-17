//
//  OADebugHudViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADebugHudViewController.h"

#import "OAMapRendererViewController.h"
#import "OAMapRendererView.h"
#import "OAAutoObserverProxy.h"

#define _(name) OADebugHudViewController__##name
#define ctor _(ctor)
#define dtor _(dtor)

@interface OADebugHudViewController () <UIPopoverControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *_overlayContainer;
@property (weak, nonatomic) IBOutlet UITextView *_stateTextview;
@property (weak, nonatomic) IBOutlet UITextView *_outputTextview;
@property (weak, nonatomic) IBOutlet UIButton *_debugActionsButton;
@property (weak, nonatomic) IBOutlet UIButton *_debugPinOverlayButton;
@property (weak, nonatomic) IBOutlet UILabel *_stateTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *_outputTitleLabel;

@end

@implementation OADebugHudViewController
{
    OAAutoObserverProxy* _rendererStateObserver;
    OAAutoObserverProxy* _rendererSettingsObserver;
    UIStoryboard* _debugActionsStoryboard;
    UIPopoverController* _lastMenuPopoverController;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)ctor
{
    _rendererStateObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onRendererStateChanged)];
    _rendererSettingsObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onRendererSettingsChanged)];
    _debugActionsStoryboard = [UIStoryboard storyboardWithName:@"DebugActions" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self collectState];
    [_rendererStateObserver observe:[OAMapRendererViewController instance].stateObservable];
    [_rendererSettingsObserver observe:[OAMapRendererViewController instance].settingsObservable];

    [self._debugPinOverlayButton setImage:[UIImage imageNamed:
                                           self._overlayContainer.userInteractionEnabled
                                           ? @"HUD_debug_pin_filled_button.png"
                                           : @"HUD_debug_pin_button.png"]
                                 forState:UIControlStateNormal];
}

- (void)openMenu:(UIViewController*)menuViewController fromView:(UIView*)view
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        // For iPhone and iPod, push menu to navigation controller
        [self.navigationController pushViewController:menuViewController
                                             animated:YES];
    }
    else //if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        // For iPad, open menu in a popover with it's own navigation controller
        UINavigationController* popoverNavigationController = [[UINavigationController alloc] initWithRootViewController:menuViewController];
        _lastMenuPopoverController = [[UIPopoverController alloc] initWithContentViewController:popoverNavigationController];
        _lastMenuPopoverController.delegate = self;

        [_lastMenuPopoverController presentPopoverFromRect:view.frame
                                                    inView:self.view
                                  permittedArrowDirections:UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight
                                                  animated:YES];
    }
}

- (IBAction)onDebugActionsButtonClicked:(id)sender
{
    [self openMenu:[_debugActionsStoryboard instantiateInitialViewController]
          fromView:self._debugActionsButton];
}

- (IBAction)onDebugPinOverlayButtonClicked:(id)sender
{
    self._overlayContainer.userInteractionEnabled = !self._overlayContainer.userInteractionEnabled;
    [self._debugPinOverlayButton setImage:[UIImage imageNamed:
                                           self._overlayContainer.userInteractionEnabled
                                           ? @"HUD_debug_pin_filled_button.png"
                                           : @"HUD_debug_pin_button.png"]
                                 forState:UIControlStateNormal];
}

- (void)collectState
{
    OAMapRendererView* __weak mapRendererView = (OAMapRendererView*)[[OAMapRendererViewController instance] mapRendererView];

    NSMutableString* stateDump = [[NSMutableString alloc] init];

    [stateDump appendFormat:@"forced re-rendering  : %s\n", mapRendererView.forcedRenderingOnEachFrame ? "yes" : "no"];
    [stateDump appendFormat:@"target               : %d %d\n", mapRendererView.target31.x, mapRendererView.target31.y];
    [stateDump appendFormat:@"zoom                 : %f\n", mapRendererView.zoom];
    [stateDump appendFormat:@"zoom level           : %d\n", static_cast<int>(mapRendererView.zoomLevel)];
    [stateDump appendFormat:@"azimuth              : %f\n", mapRendererView.azimuth];
    [stateDump appendFormat:@"elevation angle      : %f\n", mapRendererView.elevationAngle];
//    [stateDump appendFormat:@"zoom                 : %f\n", mapRendererView.zoom];

    [self._stateTextview setText:stateDump];
}

- (void)onRendererStateChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self collectState];
    });
}

- (void)onRendererSettingsChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self collectState];
    });
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad &&
       _lastMenuPopoverController == popoverController)
    {
        _lastMenuPopoverController = nil;
    }
}

#pragma mark -

@end
