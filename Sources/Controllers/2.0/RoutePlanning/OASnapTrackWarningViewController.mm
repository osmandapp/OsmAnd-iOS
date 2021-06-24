//
//  OASnapTrackWarningViewController.mm
//  OsmAnd
//
//  Created by Skalii on 28.05.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OASnapTrackWarningViewController.h"
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
    self.buttonsSectionDividerView.hidden = YES;
    
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
    return OAUtilities.getBottomMargin + 75. + [OAUtilities calculateTextBounds:OALocalizedString(@"route_between_points_warning_desc") width:DeviceScreenWidth font:[UIFont systemFontOfSize:15.]].height + 16. + self.headerView.frame.size.height;
}

- (void)onRightButtonPressed
{
    [self dismissViewControllerAnimated:NO completion:^{
        if (self.delegate)
            [self.delegate onContinueSnapApproximation];
    }];
    
}

- (void) onBottomSheetDismissed
{
    if (self.delegate)
        [self.delegate onCancelSnapApproximation];
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
