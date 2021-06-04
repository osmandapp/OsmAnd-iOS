//
//  OASnapTrackWarningViewController.mm
//  OsmAnd
//
//  Created by Skalii on 28.05.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OASnapTrackWarningViewController.h"
#import "OABottomSheetHeaderButtonCell.h"
#import "Localization.h"
#import "OAColors.h"

#define kButtonsDividerTag 150

@interface OASnapTrackWarningBottomSheetScreen ()

@end

@implementation OASnapTrackWarningBottomSheetScreen
{
    OASnapTrackWarningViewController *vwController;
    NSArray* _data;
}

@synthesize tableData, tblView, vwController;

- (id)initWithTable:(UITableView *)tableView viewController:(OASnapTrackWarningViewController *)viewController param:(id)param;
{
    self = [super init];
    if (self)
    {
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void)initOnConstruct:(UITableView *)tableView viewController:(OASnapTrackWarningViewController *)viewController
{
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (void)setupView
{
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
}

- (void)initData
{
    NSMutableArray *arr = [NSMutableArray array];

    [arr addObject:@{
            @"type" : [OABottomSheetHeaderButtonCell getCellIdentifier],
            @"title" : OALocalizedString(@"attach_to_the_roads"),
            @"img" : @"ic_custom_attach_track",
            @"description" : @""
    }];

    _data = [NSArray arrayWithArray:arr];
}

- (void)onCloseButtonPressed:(id)sender
{
    [vwController setContinue:NO];
    [vwController dismiss];
}

- (void)doneButtonPressed
{
    [vwController setContinue:YES];
    [vwController dismiss];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderButtonCell getCellIdentifier]])
    {
        OABottomSheetHeaderButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:[OABottomSheetHeaderButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OABottomSheetHeaderButtonCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.backgroundColor = UIColor.clearColor;
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            cell.descrLabel.text = item[@"description"];
            cell.iconView.image = [UIImage templateImageNamed:item[@"img"]];
            [cell.closeButton removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.closeButton addTarget:self action:@selector(onCloseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    return UITableViewAutomaticDimension;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *descriptionString = OALocalizedString(@"route_between_points_warning_desc");
    CGFloat textWidth = tableView.bounds.size.width - 32;
    CGFloat heightForHeader = [OAUtilities heightForHeaderViewText:descriptionString width:textWidth font:[UIFont systemFontOfSize:15] lineSpacing:6.] + 16;
    UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0., 0., tableView.bounds.size.width, heightForHeader)];
    UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(16., 8., textWidth, heightForHeader)];
    description.text = descriptionString;
    description.font = [UIFont systemFontOfSize:15];
    description.numberOfLines = 0;
    description.lineBreakMode = NSLineBreakByWordWrapping;
    description.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [vw addSubview:description];
    return vw;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat labelHeight = [OAUtilities heightForHeaderViewText:OALocalizedString(@"route_between_points_warning_desc") width:tableView.bounds.size.width - 32 font:[UIFont systemFontOfSize:15] lineSpacing:6.];
    return labelHeight + 60;
}

@end

@interface OASnapTrackWarningViewController ()

@end

@implementation OASnapTrackWarningViewController
{
    BOOL _continue;
}

- (void)setupView
{
    if (!self.screenObj)
        self.screenObj = [[OASnapTrackWarningBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
    
    [super setupView];
}

- (void)additionalSetup
{
    [super additionalSetup];
    self.tableBackgroundView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
    self.buttonsView.subviews.firstObject.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_continue") forState:UIControlStateNormal];
}

- (void)dismiss
{
    [super dismiss];
    if (self.delegate)
    {
        if (_continue)
            [self.delegate onContinueSnapApproximation];
        else
            [self.delegate onCancelSnapApproximation];
    }
}

- (void)dismiss:(id)sender
{
    [super dismiss:sender];
    if (self.delegate)
    {
        if (_continue)
            [self.delegate onContinueSnapApproximation];
        else
            [self.delegate onCancelSnapApproximation];
    }
}

- (void)setContinue:(BOOL)__continue
{
    _continue = __continue;
}

@end
