//
//  OADeleteProfileBottomSheetViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADeleteProfileBottomSheetViewController.h"
#import "OABottomSheetHeaderButtonCell.h"
#import "OAMainSettingsViewController.h"
#import "OARootViewController.h"

#import "Localization.h"
#import "OAColors.h"

#define kButtonsDividerTag 150
#define kButtonsTag 1

@interface OADeleteProfileBottomSheetScreen ()

@end

@implementation OADeleteProfileBottomSheetScreen
{
    OAApplicationMode *_appMode;
    OADeleteProfileBottomSheetViewController *vwController;
    NSArray* _data;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OADeleteProfileBottomSheetViewController *)viewController appMode:(OAApplicationMode *)am
{
    self = [super init];
    if (self)
    {
        _appMode = am;
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OADeleteProfileBottomSheetViewController *)viewController
{
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (void) setupView
{
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableArray *arr = [NSMutableArray array];
    
    [arr addObject:@{
        @"type" : [OABottomSheetHeaderButtonCell getCellIdentifier],
        @"title" : [NSString stringWithFormat:@"%@?", OALocalizedString(@"profile_alert_delete_title")],
        @"img" : @"ic_custom_remove_outlined",
        @"description" : @""
    }];
    
    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (void) onCloseButtonPressed:(id)sender
{
    [vwController dismiss];
}

- (void) doneButtonPressed
{
    [OAApplicationMode deleteCustomModes:[NSArray arrayWithObject:_appMode]];
    [vwController dismiss];
    for (UIViewController *vc in [[OARootViewController instance].navigationController viewControllers])
    {
        if ([vc isKindOfClass:OAMainSettingsViewController.class])
        {
            [[OARootViewController instance].navigationController popToViewController:vc animated:YES];
            break;
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderButtonCell getCellIdentifier]])
    {
        OABottomSheetHeaderButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:[OABottomSheetHeaderButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OABottomSheetHeaderButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OABottomSheetHeaderButtonCell *)[nib objectAtIndex:0];
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

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    return UITableViewAutomaticDimension;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *descriptionString = [NSString stringWithFormat:OALocalizedString(@"profile_alert_delete_msg"), _appMode.toHumanString];
    CGFloat textWidth = tableView.bounds.size.width - 32;
    CGFloat heightForHeader = [OAUtilities heightForHeaderViewText:descriptionString width:textWidth font:[UIFont systemFontOfSize:15] lineSpacing:6.] + 16;
    UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0., 0., tableView.bounds.size.width, heightForHeader)];
    UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(16., 8., textWidth, heightForHeader)];
    description.attributedText = [OAUtilities getStringWithBoldPart:descriptionString mainString:[NSString stringWithFormat:OALocalizedString(@"profile_alert_delete_msg"), @""] boldString:_appMode.toHumanString lineSpacing:4. fontSize:15 highlightColor:UIColor.blackColor];
    description.numberOfLines = 0;
    description.lineBreakMode = NSLineBreakByWordWrapping;
    description.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [vw addSubview:description];
    return vw;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    CGFloat labelHeight = [OAUtilities heightForHeaderViewText:[NSString stringWithFormat:OALocalizedString(@"profile_alert_delete_msg"), _appMode.toHumanString] width:tableView.bounds.size.width - 32 font:[UIFont systemFontOfSize:15] lineSpacing:6.];
    return labelHeight + 60;
}

@synthesize vwController;

@end


@interface OADeleteProfileBottomSheetViewController ()

@end

@implementation OADeleteProfileBottomSheetViewController
{
    OAApplicationMode *_appMode;
}

- (instancetype) initWithMode:(OAApplicationMode *)am
{
    _appMode = am;
    return [super initWithParam:nil];
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OADeleteProfileBottomSheetScreen alloc] initWithTable:self.tableView viewController:self appMode:_appMode];
    
    [super setupView];
}

- (void) additionalSetup
{
    [super additionalSetup];
    self.tableBackgroundView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
    self.buttonsView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
    for (UIView *v in self.buttonsView.subviews)
    {
        if (v.tag != kButtonsTag)
            v.backgroundColor = UIColor.clearColor;
    }
    [self.cancelButton setBackgroundColor:UIColorFromRGB(color_route_button_inactive)];
    self.doneButton.layer.borderWidth = 2.0;
    self.doneButton.layer.borderColor = UIColorFromRGB(color_route_button_inactive).CGColor;
    [self.doneButton setBackgroundColor:UIColorFromRGB(color_route_button_inactive)];
    [self.doneButton setTitleColor:UIColorFromRGB(color_support_red) forState:UIControlStateNormal];
}

- (void) applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
}

- (void) dismiss
{
    [super dismiss];
    if (self.delegate)
        [self.delegate onDeleteProfileDismissed];
}

- (void) dismiss:(id)sender
{
    [super dismiss:sender];
    if (self.delegate)
        [self.delegate onDeleteProfileDismissed];
}

@end

