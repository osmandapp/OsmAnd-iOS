//
//  OAExitRoutePlanningBottomSheetViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAExitRoutePlanningBottomSheetViewController.h"

#import "Localization.h"
#import "OAColors.h"

#define kOABottomSheetWidth 320.0
#define kOABottomSheetWidthIPad (DeviceScreenWidth / 2)
#define kVerticalMargin 16.
#define kHorizontalMargin 20.
#define kButttonsHeight 116.

@interface OAExitRoutePlanningBottomSheetViewController ()

@property (strong, nonatomic) IBOutlet UILabel *messageView;
@property (strong, nonatomic) IBOutlet UIButton *exitButton;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation OAExitRoutePlanningBottomSheetViewController


- (instancetype) init
{
    self = [super initWithNibName:@"OAExitRoutePlanningBottomSheetViewController" bundle:nil];

    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    [self.rightButton removeFromSuperview];
    [self.leftIconView setImage:[UIImage imageNamed:@"ic_custom_routes"]];
    
    self.exitButton.layer.cornerRadius = 9.;
    self.saveButton.layer.cornerRadius = 9.;
    self.cancelButton.layer.cornerRadius = 9.;
    
    self.isFullScreenAvailable = NO;
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"osm_editing_lost_changes_title");
    self.messageView.text = OALocalizedString(@"plan_route_exit_message");
    [self.exitButton setTitle:OALocalizedString(@"shared_string_exit") forState:UIControlStateNormal];
    [self.saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (CGFloat) initialHeight
{
    CGFloat width = DeviceScreenWidth - 2 * kHorizontalMargin;
    CGFloat headerHeight = self.headerView.frame.size.height;
    CGFloat contentHeight = [OAUtilities calculateTextBounds:OALocalizedString(@"plan_route_exit_message") width:width font:[UIFont systemFontOfSize:15.]].height + _exitButton.frame.size.height + kVerticalMargin * 2;
    CGFloat buttonsHeight = 132. + [OAUtilities getBottomMargin];
    return headerHeight + contentHeight + buttonsHeight + kVerticalMargin * 2;
}

- (CGFloat) buttonsViewHeight
{
    CGFloat extraBottomOffset = [OAUtilities getBottomMargin] > 0 ? 0 : kVerticalMargin;
    return kButttonsHeight + extraBottomOffset;
}

- (CGFloat) getViewHeight
{
    return self.initialHeight;
}

- (IBAction)exitButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
    if (_delegate)
        [_delegate onExitRoutePlanningPressed];
}

- (IBAction)saveButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
    if (_delegate)
        [_delegate onSaveResultPressed];
}


@end
