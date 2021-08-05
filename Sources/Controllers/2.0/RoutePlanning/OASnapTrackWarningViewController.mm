//
//  OASnapTrackWarningViewController.mm
//  OsmAnd
//
//  Created by Skalii on 28.05.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OASnapTrackWarningViewController.h"
#import "OAGpxApproximationViewController.h"
#import "OAApplicationMode.h"
#import "OAMeasurementEditingContext.h"
#import "OAGpxApproximationViewController.h"
#import "Localization.h"
#import "OAColors.h"

@interface OASnapTrackWarningViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OASnapTrackWarningViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.leftIconView setImage:[UIImage templateImageNamed:@"ic_custom_attach_track"]];
    self.leftIconView.tintColor = UIColorFromRGB(color_primary_purple);
    
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"route_between_points_warning_desc") font:[UIFont systemFontOfSize:15.] textColor:UIColor.blackColor lineSpacing:0. isTitle:NO];
}

- (void)applyLocalization
{
    self.titleView.text = OALocalizedString(@"attach_to_the_roads");
    [self.leftButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.rightButton setTitle:OALocalizedString(@"shared_string_continue") forState:UIControlStateNormal];
}

- (CGFloat)initialHeight
{
    return OAUtilities.getBottomMargin + 75. + [OAUtilities calculateTextBounds:OALocalizedString(@"route_between_points_warning_desc") width:DeviceScreenWidth font:[UIFont systemFontOfSize:15.]].height + 16. + self.headerView.frame.size.height + 60.;
}

- (void)onRightButtonPressed
{
    OAMeasurementEditingContext *editingCtx = self.delegate.getCurrentEditingContext;
    if (editingCtx.appMode == OAApplicationMode.DEFAULT || [editingCtx.appMode.getRoutingProfile isEqualToString:@"public_transport"])
        editingCtx.appMode = nil;
    OAGpxApproximationViewController *approximationVC = [[OAGpxApproximationViewController alloc] initWithMode:editingCtx.appMode routePoints:[editingCtx getPointsSegments:YES route:NO]];
    approximationVC.delegate = self.delegate;
    if (self.delegate)
        [self.delegate onContinueSnapApproximation:approximationVC];
    [self.navigationController pushViewController:approximationVC animated:YES];
}

- (void) onBottomSheetDismissed
{
    if (self.delegate)
        [self.delegate onCancelSnapApproximation:NO];
    [self dismiss];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

@end
