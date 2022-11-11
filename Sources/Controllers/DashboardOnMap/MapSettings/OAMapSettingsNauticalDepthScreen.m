//
//  OAMapSettingsNauticalDepthScreen.mm
//  OsmAnd
//
//  Created by Skalii on 10.11.2022.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAMapSettingsNauticalDepthScreen.h"
#import "OANauticalDepthParametersViewController.h"
#import "OAMapSettingsViewController.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OAValueTableViewCell.h"
#import "OATableViewCellSwitch.h"
#import "OAMapStyleSettings.h"
#import "OASizes.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAMapSettingsNauticalDepthScreen () <OANauticalDepthParametersDelegate>

@end

@implementation OAMapSettingsNauticalDepthScreen
{
    OsmAndAppInstance _app;
    OAMapViewController *_mapViewController;

    OAMapStyleSettings *_styleSettings;
    OAMapStyleParameter *_depthContours;
    OAMapStyleParameter *_depthContourWidth;
    OAMapStyleParameter *_depthContourColorScheme;

    NSArray<NSArray<NSDictionary *> *> *_data;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _styleSettings = [OAMapStyleSettings sharedInstance];
        tblView = tableView;
        settingsScreen = EMapSettingsScreenNauticalDepth;
        vwController = viewController;
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        _depthContours = [_styleSettings getParameter:NAUTICAL_DEPTH_CONTOURS];
        _depthContourWidth = [_styleSettings getParameter:NAUTICAL_DEPTH_CONTOUR_WIDTH_ATTR];
        _depthContourColorScheme = [_styleSettings getParameter:NAUTICAL_DEPTH_CONTOUR_COLOR_SCHEME_ATTR];

        [self initData];
    }
    return self;
}

- (void)initData
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray new];

    [data addObject:@[@{ @"type": [OATableViewCellSwitch getCellIdentifier] }]];

    if ([_depthContours.value isEqualToString:@"true"])
    {
        NSMutableArray<NSDictionary *> *cells = [NSMutableArray new];
        if (_depthContourWidth)
        {
            [cells addObject:@{
                @"type": [OAValueTableViewCell getCellIdentifier],
                @"parameter": _depthContourWidth
            }];
        }
        if (_depthContourColorScheme)
        {
            [cells addObject:@{
                @"type": [OAValueTableViewCell getCellIdentifier],
                @"parameter": _depthContourColorScheme
            }];
        }
        [data addObject:cells];
    }

    _data = data;
}

- (void)setupView
{
    title = OALocalizedString(@"product_title_sea_depth_contours");
    tblView.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OATableViewCellSwitch getCellIdentifier]])
    {
        OATableViewCellSwitch *cell = [tableView dequeueReusableCellWithIdentifier:[OATableViewCellSwitch getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATableViewCellSwitch getCellIdentifier] owner:self options:nil];
            cell = (OATableViewCellSwitch *) nib[0];
            [cell descriptionVisibility:NO];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleLabel.text = OALocalizedString(@"product_title_sea_depth_contours");

            BOOL isOn = [_depthContours.value isEqualToString:@"true"];
            if (!isOn)
            {
                cell.leftIconView.image = [UIImage templateImageNamed:@"ic_custom_nautical_depth_colored_day"];
                cell.leftIconView.tintColor = UIColorFromRGB(color_tint_gray);
            }
            else
            {
                cell.leftIconView.image = [UIImage imageNamed:@"ic_custom_nautical_depth_colored_day"];
            }

            cell.switchView.on = isOn;
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAMapStyleParameter *parameter = item[@"parameter"];
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = parameter.title;
            cell.valueLabel.text = [parameter getValueTitle];
        }
        return cell;
    }

    return nil;
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1)
        return OALocalizedString(@"depth_contour_lines");

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 1)
    {
        CGFloat headerHeight = [OAUtilities calculateTextBounds:OALocalizedString(@"depth_contour_lines")
                                                          width:tableView.frame.size.width - (kPaddingOnSideOfContent + [OAUtilities getLeftMargin]) * 2
                                                           font:[UIFont systemFontOfSize:13.]].height + kPaddingOnSideOfHeaderWithText;
        return headerHeight;
    }

    return 0.;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *item = [self getItem:indexPath];
    OAMapStyleParameter *parameter = item[@"parameter"];
    if (parameter)
    {
        OANauticalDepthParametersViewController *depthParametersViewController = [[OANauticalDepthParametersViewController alloc] initWithParameter:parameter];
        depthParametersViewController.depthDelegate = self;
        [vwController presentViewController:depthParametersViewController animated:YES completion:nil];
    }
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        _depthContours.value = switchView.on ? @"true" : @"false";
        [_styleSettings save:_depthContours];
        [self initData];
        [UIView transitionWithView:tblView
                          duration:.35
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^(void) {
                            [tblView reloadData];
                        }
                        completion:nil];
    }
}

#pragma mark - OANauticalDepthParametersDelegate

- (void)onValueSelected:(OAMapStyleParameter *)parameter
{
    if ([_depthContours.value isEqualToString:@"true"])
    {
        [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:parameter == _depthContourWidth ? 0 : 1 inSection:1]]
                       withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

@end
