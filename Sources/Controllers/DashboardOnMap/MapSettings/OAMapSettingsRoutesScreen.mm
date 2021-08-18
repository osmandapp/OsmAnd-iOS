//
//  OAMapSettingsRoutesScreen.mm
//  OsmAnd
//
//  Created by Skalii on 16.08.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAMapSettingsRoutesScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OATableViewCustomFooterView.h"
#import "OADividerCell.h"
#import "OASettingSwitchCell.h"
#import "OASwitchTableViewCell.h"
#import "OASettingsTableViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAMapStyleSettings.h"

static const NSInteger visibilitySection = 0;
static const NSInteger colorsSection = 1;

typedef enum
{
    ERoutesSettingCycle = 0,
    ERoutesSettingHiking,
    ERoutesSettingTravel

} ERoutesSettingType;

@implementation OAMapSettingsRoutesScreen
{
    OsmAndAppInstance _app;
    OAMapViewController *_mapViewController;

//    OAMapStyleSettings *_styleSettings;
//    NSArray<OAMapStyleParameter *> *_parameters;
//    ERoutesSettingType _routesSettingType;

    NSArray<NSArray <NSDictionary *> *> *_data;
    BOOL _routesEnabled;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;

- (id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        /*_styleSettings = [OAMapStyleSettings sharedInstance];

        if ([param isEqualToString:@"cycle"])
        {
            _routesSettingType = ERoutesSettingCycle;
            title = OALocalizedString(@"rendering_attr_showCycleRoutes_name");
            settingsScreen = EMapSettingsScreenCycleRoutes;
        }
        else if ([param isEqualToString:@"hiking"])
        {
            _routesSettingType = ERoutesSettingHiking;
            title = OALocalizedString(@"rendering_attr_hikingRoutesOSMC_name");
            settingsScreen = EMapSettingsScreenHikingRoutes;
        }
        else
        {
            _routesSettingType = ERoutesSettingTravel;
            title = OALocalizedString(@"travel_routes");
            settingsScreen = EMapSettingsScreenTravelRoutes;
        }*/

        vwController = viewController;
        tblView = tableView;
        _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void)commonInit
{

}

- (void)initData
{
    NSMutableArray *dataArr = [@[
            @[
                    @{@"type": [OADividerCell getCellIdentifier]},
                    @{@"type": [OASettingSwitchCell getCellIdentifier]},
                    @{@"type": [OADividerCell getCellIdentifier]}
            ]
    ] mutableCopy];

    _data = [NSArray arrayWithArray:dataArr];
}
- (void)setupView
{
    [self.tblView.tableFooterView removeFromSuperview];
    self.tblView.tableFooterView = nil;
    [self.tblView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    tblView.estimatedRowHeight = kEstimatedRowHeight;
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSString *)getTextForFooter:(NSInteger)section
{
    if (!_routesEnabled)
        return @"";

    /*switch (section)
    {
        case languagesSection:
            return OALocalizedString(@"select_wikipedia_article_langs");
        case availableMapsSection:
            return _mapItems.count > 0 ?  OALocalizedString(@"wiki_menu_download_descr") : @"";
        default:
            return @"";
    }*/

    return @"";
}

- (CGFloat)getFooterHeightForSection:(NSInteger)section
{
    return [OATableViewCustomFooterView getHeight:[self getTextForFooter:section] width:tblView.frame.size.width];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section != visibilitySection && !_routesEnabled)
        return 0;

    return section == visibilitySection ? 1 : 0/*_parameters.count*/;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*OAMapStyleParameter *p = _parameters[indexPath.row];
    if (p.dataType != OABoolean)
    {
        OASettingsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTableViewCell *) nib[0];
        }
        if (cell)
        {
            [cell.textView setText:p.title];
            [cell.descriptionView setText:[p getValueTitle]];
        }
        return cell;
    }
    else
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
        }
        if (cell)
        {
            [cell.textView setText:p.title];
            [cell.switchView setOn:[p.storedValue isEqualToString:@"true"]];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.switchView.tag = indexPath.row;
        }
        return cell;
    }*/
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[self getItem:indexPath][@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsZero];
    else
        return UITableViewAutomaticDimension;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section != visibilitySection ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != visibilitySection)
        [self onItemClicked:indexPath];
    else
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self onItemClicked:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if (section == colorsSection/* && .count > 0*/ && _routesEnabled)
    {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (!_routesEnabled || section == visibilitySection)
        return 0.01;

    return 56.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (!_routesEnabled || section == visibilitySection)
        return @"";

    return OALocalizedString(@"routes_color_by_type");
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self getFooterHeightForSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (!_routesEnabled || section == visibilitySection)
        return nil;

    OATableViewCustomFooterView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    NSString *text = [self getTextForFooter:section];
    vw.label.text = text;
    return vw;
}

#pragma mark - Selectors

- (void)onItemClicked:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
}

@end
