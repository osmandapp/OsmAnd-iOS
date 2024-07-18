//
//  OANavigationTypeViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 22.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavigationTypeViewController.h"
#import "OASimpleTableViewCell.h"
#import "OAProfilesGroup.h"
#import "OAApplicationMode.h"
#import "OARoutingDataUtils.h"
#import "OARoutingDataObject.h"
#import "OAAppSettings.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@implementation OANavigationTypeViewController
{
    NSArray<OAProfilesGroup *> *_profileGroups;
    NSArray<NSString *> *_fileNames;
    OATableDataModel *_data;
}

#pragma mark - Initialization

- (void)commonInit
{
    _profileGroups = [OARoutingDataUtils getOfflineProfiles];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"nav_type_hint");
}

- (NSString *)getTableHeaderDescription
{
    return OALocalizedString(@"select_nav_profile_dialog_message");
}

- (NSString *)getTableFooterText
{
    return OALocalizedString(@"import_routing_file_descr");
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];
    for (OAProfilesGroup *group in _profileGroups)
    {
        NSArray<OARoutingDataObject *> *profiles = group.profiles;
        if (profiles.count > 0)
        {
            OATableSectionData *routingSection = [_data createNewSection];
            routingSection.headerText = group.title;
            routingSection.footerText = group.descr;
            
            for (OARoutingDataObject *profile in profiles)
            {
                [routingSection addRowFromDictionary:@{
                    kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
                    @"profile" : profile
                }];
            }
        }
    }
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    OARoutingDataObject *profile = [item objForKey:@"profile"];
    if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = profile.name;
            cell.leftIconView.image = [UIImage templateImageNamed:profile.iconName];

            NSString *derivedProfile = [self.appMode getDerivedProfile];
            BOOL checkForDerived = ![derivedProfile isEqualToString:@"default"];
            BOOL isSelected = [profile.stringKey isEqual:[self.appMode getRoutingProfile]] && ((!checkForDerived && !profile.derivedProfile) || (checkForDerived && [profile.derivedProfile isEqualToString:derivedProfile]));
            cell.accessoryType = isSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            cell.leftIconView.tintColor = isSelected ? [self.appMode getProfileColor] : [UIColor colorNamed:ACColorNameIconColorDisabled];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    OARoutingDataObject *profile = [item objForKey:@"profile"];
    int routeService;
    if ([profile.stringKey isEqualToString:@"STRAIGHT_LINE_MODE"])
        routeService = STRAIGHT;
    else if ([profile.stringKey isEqualToString:@"DIRECT_TO_MODE"])
        routeService = DIRECT_TO;
//    else if (profileKey.equals(RoutingProfilesResources.BROUTER_MODE.name())) {
//        routeService = RouteProvider.RouteService.BROUTER;
    else
        routeService = OSMAND;

    NSString *derivedProfile = profile.derivedProfile ? profile.derivedProfile : @"default";
    [self.appMode setRoutingProfile:profile.stringKey];
    [self.appMode setDerivedProfile:derivedProfile];
    [self.appMode setRouterService:routeService];
    if (self.delegate)
        [self.delegate onSettingsChanged];
    [self dismissViewController];
}

@end
