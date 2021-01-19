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
#define kVerticalMargin 16.
#define kHorizontalMargin 20.

@interface OASaveTrackBottomSheetViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIButton *openSavedTrackButton;
@property (strong, nonatomic) IBOutlet UIButton *createNewRouteButton;
@property (strong, nonatomic) IBOutlet UIButton *shareButton;

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
    
    [self.iconImageView setImage:[[UIImage imageNamed:@"ic_custom_save_complete.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    self.iconImageView.tintColor = UIColorFromRGB(color_primary_purple);
    self.openSavedTrackButton.layer.cornerRadius = 9.;
    self.createNewRouteButton.layer.cornerRadius = 9.;
    self.shareButton.layer.cornerRadius = 9.;
    
    self.isFullScreenAvailable = NO;
    
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
    CGFloat width = DeviceScreenWidth - 2 * kHorizontalMargin;
    CGFloat contentHeight = self.iconImageView.frame.size.height + [OAUtilities calculateTextBounds:[NSString stringWithFormat:OALocalizedString(@"track_is_saved"), _track.gpxFileName] width:width font:[UIFont systemFontOfSize:15.]].height + self.openSavedTrackButton.frame.size.height + self.createNewRouteButton.frame.size.height + self.shareButton.frame.size.height + kVerticalMargin * 6;
    CGFloat buttonsHeight = 60. + [OAUtilities getBottomMargin];
    return contentHeight + buttonsHeight + kVerticalMargin * 2;
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

@end
