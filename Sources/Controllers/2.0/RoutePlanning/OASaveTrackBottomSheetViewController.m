//
//  OASaveTrackBottomSheetViewController.m
//  OsmAnd
//
//  Created by Anna Bibyk on 14.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASaveTrackBottomSheetViewController.h"
#import "OARootViewController.h"
#import "OARoutePlanningHudViewController.h"
#import "OAUtilities.h"

#import "Localization.h"
#import "OAColors.h"

#define kOABottomSheetWidth 320.0
#define kOABottomSheetWidthIPad (DeviceScreenWidth / 2)

@interface OASaveTrackBottomSheetViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIButton *openSavedTrackButton;
@property (strong, nonatomic) IBOutlet UIButton *createNewRouteButton;
@property (strong, nonatomic) IBOutlet UIButton *shareButton;
@property (strong, nonatomic) IBOutlet UIButton *closeBottomSheetButton;

@end

@implementation OASaveTrackBottomSheetViewController
{
    OAGPX* _track;
}

- (instancetype) initWithNewTrack:(OAGPX *)track
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _track = track;
    }
    return self;
}

- (void) commonInit
{
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"OASaveTrackBottomSheetViewController"
                           bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.iconImageView setImage:[UIImage imageNamed:@"ic_custom_save_complete.png"]];
    self.openSavedTrackButton.layer.cornerRadius = 9.;
    self.createNewRouteButton.layer.cornerRadius = 9.;
    self.shareButton.layer.cornerRadius = 9.;
    self.closeBottomSheetButton.layer.cornerRadius = 9.;
    
    NSString *titleString = [NSString stringWithFormat:OALocalizedString(@"track_is_saved"), _track.gpxFileName];
    self.titleLabel.attributedText = [OAUtilities getColoredString:titleString highlightedString:_track.gpxFileName highlightColor:UIColorFromRGB(color_primary_purple) fontSize:17. centered:YES];
}

- (void) applyLocalization
{
    [self.openSavedTrackButton setTitle:OALocalizedString(@"open_saved_track") forState:UIControlStateNormal];
    [self.createNewRouteButton setTitle:OALocalizedString(@"plan_route_create_new_route") forState:UIControlStateNormal];
    [self.shareButton setTitle:OALocalizedString(@"ctx_mnu_share") forState:UIControlStateNormal];
}

- (CGFloat) initialHeight
{
    return self.bottomSheetView.frame.size.height;
}

- (IBAction)openSavedTrackPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [[OARootViewController instance].mapPanel openTargetViewWithGPX:_track pushed:YES];
}

- (IBAction)createNewTrackButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [[OARootViewController instance].mapPanel showScrollableHudViewController:[[OARoutePlanningHudViewController alloc] init]];
}

- (IBAction)shareButtonPressed:(id)sender
{
    
}

- (IBAction)closeBottomSheetButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
