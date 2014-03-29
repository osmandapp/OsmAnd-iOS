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

@interface OADebugHudViewController ()

@property (weak, nonatomic) IBOutlet UIView *_overlayContainer;
@property (weak, nonatomic) IBOutlet UITextView *_stateTextview;
@property (weak, nonatomic) IBOutlet UITextView *_outputTextview;
@property (weak, nonatomic) IBOutlet UIButton *_debugActionsButton;
@property (weak, nonatomic) IBOutlet UIButton *_debugPinOverlayButton;

@end

@implementation OADebugHudViewController
{
    OAAutoObserverProxy* _rendererStateObserver;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self collectState];
    [_rendererStateObserver observe:[OAMapRendererViewController instance].stateObservable];

    [self._debugPinOverlayButton setImage:[UIImage imageNamed:
                                           self._overlayContainer.userInteractionEnabled
                                           ? @"HUD_debug_pin_filled_button.png"
                                           : @"HUD_debug_pin_button.png"]
                                 forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onDebugActionsButtonClicked:(id)sender
{
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
    __weak OAMapRendererView* mapRendererView = [[OAMapRendererViewController instance] mapRendererView];

    NSMutableString* stateDump = [[NSMutableString alloc] init];

    [stateDump appendFormat:@"target          : %d %d\n", mapRendererView.target31.x, mapRendererView.target31.y];
    [stateDump appendFormat:@"zoom            : %f\n", mapRendererView.zoom];
    [stateDump appendFormat:@"zoom level      : %d\n", static_cast<int>(mapRendererView.zoomLevel)];
    [stateDump appendFormat:@"azimuth         : %f\n", mapRendererView.azimuth];
    [stateDump appendFormat:@"elevation angle : %f\n", mapRendererView.elevationAngle];
//    [stateDump appendFormat:@"zoom            : %f\n", mapRendererView.zoom];

    [self._stateTextview setText:stateDump];
}

- (void)onRendererStateChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self collectState];
    });
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
