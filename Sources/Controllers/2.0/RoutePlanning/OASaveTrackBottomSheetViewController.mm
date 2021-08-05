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
#import "OAGPXDatabase.h"
#import "OAUtilities.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"

#import "Localization.h"
#import "OAColors.h"

#include <OsmAndCore/Utilities.h>

#define kOABottomSheetWidth 320.0
#define kOABottomSheetWidthIPad (DeviceScreenWidth / 2)
#define kVerticalMargin 16.
#define kHorizontalMargin 20.

@interface OASaveTrackBottomSheetViewController () <UIDocumentInteractionControllerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIButton *openSavedTrackButton;
@property (strong, nonatomic) IBOutlet UIButton *createNewRouteButton;
@property (strong, nonatomic) IBOutlet UIButton *shareButton;
@property (strong, nonatomic) UIDocumentInteractionController* exportController;

@end

@implementation OASaveTrackBottomSheetViewController
{
    NSString* _fileName;
}

- (instancetype) initWithFileName:(NSString *)fileName
{
    self = [super init];
    if (self)
    {
        _fileName = fileName;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"OASaveTrackBottomSheetViewController"
                           bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.iconImageView setImage:[UIImage templateImageNamed:@"ic_custom_save_complete.png"]];
    self.iconImageView.tintColor = UIColorFromRGB(color_primary_purple);
    self.openSavedTrackButton.layer.cornerRadius = 9.;
    self.createNewRouteButton.layer.cornerRadius = 9.;
    self.shareButton.layer.cornerRadius = 9.;

    self.isFullScreenAvailable = NO;

    NSString *gpxTitle = _fileName.lastPathComponent.stringByDeletingPathExtension;
    NSString *titleString = [NSString stringWithFormat:OALocalizedString(@"track_is_saved"), gpxTitle];
    self.titleLabel.attributedText = [OAUtilities getColoredString:titleString highlightedString:gpxTitle highlightColor:UIColorFromRGB(color_primary_purple) fontSize:17. centered:YES];
}

- (void) applyLocalization
{
    [self.openSavedTrackButton setTitle:OALocalizedString(@"open_saved_track") forState:UIControlStateNormal];
    [self.createNewRouteButton setTitle:OALocalizedString(@"plan_route_create_new_route") forState:UIControlStateNormal];
    [self.shareButton setTitle:OALocalizedString(@"ctx_mnu_share") forState:UIControlStateNormal];

    [self.leftButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
}

- (CGFloat) initialHeight
{
    CGFloat width = DeviceScreenWidth - 2 * kHorizontalMargin;
    CGFloat contentHeight = self.iconImageView.frame.size.height + [OAUtilities calculateTextBounds:[NSString stringWithFormat:OALocalizedString(@"track_is_saved"), _fileName.lastPathComponent.stringByDeletingPathExtension] width:width font:[UIFont systemFontOfSize:15.]].height + self.openSavedTrackButton.frame.size.height + self.createNewRouteButton.frame.size.height + self.shareButton.frame.size.height + kVerticalMargin * 6;
    CGFloat buttonsHeight = self.buttonsViewHeight + [OAUtilities getBottomMargin];
    return contentHeight + buttonsHeight + kVerticalMargin * 2;
}


- (IBAction)openSavedTrackPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *gpxFilePath = [OAUtilities getGpxShortPath:_fileName];
    OAGPX *gpx = [OAGPXDatabase.sharedDb getGPXItem:gpxFilePath];
    if (gpx)
        [[OARootViewController instance].mapPanel openTargetViewWithGPX:gpx pushed:YES];
}

- (IBAction)createNewTrackButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
    const auto point = OsmAnd::Utilities::convert31ToLatLon(OARootViewController.instance.mapPanel.mapViewController.mapView.target31);
    CLLocation *coord = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
    [[OARootViewController instance].mapPanel showScrollableHudViewController:[[OARoutePlanningHudViewController alloc] initWithInitialPoint:coord]];
}

- (IBAction)shareButtonPressed:(id)sender
{
    NSURL* sourceGpxUrl = [NSURL fileURLWithPath:_fileName];
    NSString* tempFolderPath = [NSTemporaryDirectory() stringByAppendingString:[_fileName lastPathComponent]];
    NSURL* destinationGpxUrl = [NSURL fileURLWithPath:tempFolderPath];
    [[NSData dataWithContentsOfURL:sourceGpxUrl] writeToURL:destinationGpxUrl options:NSDataWritingAtomic error:nil];

    _exportController = [UIDocumentInteractionController interactionControllerWithURL:destinationGpxUrl];
    _exportController.UTI = @"com.topografix.gpx";
    _exportController.delegate = self;
    _exportController.name = [tempFolderPath.lastPathComponent stringByDeletingPathExtension];

    [_exportController presentOptionsMenuFromRect:self.shareButton.frame
                                           inView:[self.shareButton superview]
                                         animated:YES];
}


#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
