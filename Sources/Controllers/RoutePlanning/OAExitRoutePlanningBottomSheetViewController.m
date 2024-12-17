//
//  OAExitRoutePlanningBottomSheetViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAExitRoutePlanningBottomSheetViewController.h"

#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OATextLineViewCell.h"
#import "OAFilledButtonCell.h"
#import "GeneratedAssetSymbols.h"

#define kOABottomSheetWidth 320.
#define kOABottomSheetWidthIPad (DeviceScreenWidth / 2)
#define kLabelVerticalMargin 16.
#define kButtonHeight 42.
#define kButtonsVerticalMargin 32.
#define kHorizontalMargin 20.

@interface OAExitRoutePlanningBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *messageView;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation OAExitRoutePlanningBottomSheetViewController
{
    NSMutableArray<NSDictionary *> *_data;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OABaseBottomSheetViewController" bundle:nil];

    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    self.tableView.layoutMargins = UIEdgeInsetsMake(0, 20, 0, 20);
    self.buttonsView.layoutMargins = UIEdgeInsetsMake(0, 20, 0, 20);
    self.buttonsSectionDividerView.backgroundColor = UIColor.clearColor;;

    [self.rightButton removeFromSuperview];
    self.leftIconView.image = [UIImage imageNamed:ACImageNameIcCustomRoutes];
    self.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorSelected];
    
    self.exitButton.layer.cornerRadius = 9.;
    self.saveButton.layer.cornerRadius = 9.;
    self.cancelButton.layer.cornerRadius = 9.;
    
    self.isFullScreenAvailable = NO;
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"exit_without_saving");
    [self.exitButton setTitle:OALocalizedString(@"shared_string_exit") forState:UIControlStateNormal];
    [self.saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (CGFloat) initialHeight
{
    CGFloat width;
    if (OAUtilities.isIPad)
        width = kOABottomSheetWidthIPad;
    else if ([OAUtilities isLandscape])
        width = kOABottomSheetWidth;
    else
        width = DeviceScreenWidth;
    
    width -= 2 * kHorizontalMargin;
    CGFloat headerHeight = self.headerView.frame.size.height;
    CGFloat textHeight = [OAUtilities calculateTextBounds:OALocalizedString(@"plan_route_exit_message") width:width font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]].height + kLabelVerticalMargin * 2;
    CGFloat contentHeight = textHeight + 2 * kButtonHeight + 2 * kButtonsVerticalMargin;
    CGFloat buttonsHeight = [self buttonsViewHeight];
    return headerHeight + contentHeight + buttonsHeight;
}

- (CGFloat) getLandscapeHeight
{
    return [self initialHeight];
}

- (void) generateData
{
    _data = [NSMutableArray new];
    
    [_data addObject: @{
        @"type" : [OATextLineViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"plan_route_exit_message"),
    }];
    
    [_data addObject: @{
        @"type" : [OAFilledButtonCell getCellIdentifier],
        @"title" : OALocalizedString(@"shared_string_exit"),
        @"buttonColor" : [UIColor colorNamed:ACColorNameButtonBgColorSecondary],
        @"textColor" : [UIColor colorNamed:ACColorNameButtonTextColorSecondary],
        @"action": @"exitButtonPressed"
    }];

    [_data addObject: @{
        @"type" : [OAFilledButtonCell getCellIdentifier],
        @"title" : OALocalizedString(@"shared_string_save"),
        @"buttonColor" : [UIColor colorNamed:ACColorNameButtonBgColorPrimary],
        @"textColor" : [UIColor colorNamed:ACColorNameButtonTextColorPrimary],
        @"action": @"saveButtonPressed"
    }];
}

- (BOOL) isDraggingUpAvailable
{
    return NO;
}

#pragma mark - Actions

- (void) exitButtonPressed
{
    [self hide:YES];
    if (_delegate)
        [_delegate onExitRoutePlanningPressed];
}

- (void) saveButtonPressed
{
    [self hide:YES completion:^{
        if (_delegate)
            [_delegate onSaveResultPressed];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:[OATextLineViewCell getCellIdentifier]])
    {
        OATextLineViewCell* cell;
        cell = (OATextLineViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATextLineViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextLineViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextLineViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            [cell.textView setTextColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];
            [cell.textView setText:item[@"title"]];
        }
        return cell;
    }
    else if ([type isEqualToString:[OAFilledButtonCell getCellIdentifier]])
    {
        OAFilledButtonCell* cell;
        cell = (OAFilledButtonCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAFilledButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            [cell.button setBackgroundColor:item[@"buttonColor"]];
            [cell.button setTitleColor:item[@"textColor"] forState:UIControlStateNormal];
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            cell.button.layer.cornerRadius = 9.;
            cell.topMarginConstraint.constant = 0;
            cell.bottomMarginConstraint.constant = 0;
            cell.heightConstraint.constant = 42;
            
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self action:NSSelectorFromString(item[@"action"]) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 1)
        return kButtonsVerticalMargin;
    else
        return kLabelVerticalMargin;
}

@end
