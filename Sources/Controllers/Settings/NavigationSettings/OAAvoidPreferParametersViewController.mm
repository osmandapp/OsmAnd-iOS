//
//  OAAvoidRoadsViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAvoidPreferParametersViewController.h"
#import "OASwitchTableViewCell.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAApplicationMode.h"
#import "OARouteProvider.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16

@implementation OAAvoidPreferParametersViewController
{
    NSArray<NSDictionary *> *_data;
    UIView *_tableHeaderView;
    
    BOOL _isAvoid;
}

#pragma mark - Initialization

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode isAvoid:(BOOL)isAvoid
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        _isAvoid = isAvoid;
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _isAvoid ? OALocalizedString(@"impassable_road") : OALocalizedString(@"prefer_in_routing_title");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSString *)getTableHeaderDescription
{
    return OALocalizedString(@"avoid_in_routing_descr_");
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *dataArr = [NSMutableArray array];
    OAAppSettings* settings = [OAAppSettings sharedManager];
    auto router = [OsmAndApp.instance getRouter:self.appMode];
    NSString *prefix = _isAvoid ? @"avoid_" : @"prefer_";
    if (router)
    {
        auto parameters = router->getParameters(string(self.appMode.getDerivedProfile.UTF8String));
        for (auto it = parameters.begin(); it != parameters.end(); ++it)
        {
            auto& p = it->second;
            NSString *param = [NSString stringWithUTF8String:p.id.c_str()];
            if ([param hasPrefix:prefix])
            {
                NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
                NSString *title = [OAUtilities getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
                OACommonBoolean *value = [settings getCustomRoutingBooleanProperty:paramId defaultValue:p.defaultBoolean];

                [dataArr addObject:
                 @{
                   @"name" : param,
                   @"title" : title,
                   @"value" : value,
                   @"type" : [OASwitchTableViewCell getCellIdentifier] }
                 ];
            }
        }
    }
    _data = [NSArray arrayWithArray:dataArr];
}

- (BOOL)hideFirstHeader
{
    return YES;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];

            id v = item[@"value"];
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            if ([v isKindOfClass:[OACommonBoolean class]])
            {
                OACommonBoolean *value = v;
                cell.switchView.on = [value get:self.appMode];
            }
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return 1;
}

#pragma mark - Selectors

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = _data[indexPath.row];
        BOOL isChecked = ((UISwitch *) sender).on;
        id v = item[@"value"];
        if ([v isKindOfClass:[OACommonBoolean class]])
        {
            OACommonBoolean *value = v;
            [value set:isChecked mode:self.appMode];
        }
        if (self.delegate)
            [self.delegate onSettingsChanged];
    }
}

#pragma mark - Additions

+ (BOOL) hasPreferParameters:(OAApplicationMode *)appMode
{
    auto router = [OsmAndApp.instance getRouter:appMode];
    if (router)
    {
        auto parameters = router->getParameters(string(appMode.getDerivedProfile.UTF8String));
        for (auto it = parameters.begin(); it != parameters.end(); ++it)
        {
            auto& p = it->second;
            NSString *param = [NSString stringWithUTF8String:p.id.c_str()];
            if ([param hasPrefix:@"prefer_"])
                return YES;
        }
    }
    return NO;
}

@end
