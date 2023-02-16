//
//  OAOsmandDevelopmentSimulateSpeedSelectorViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 02.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAOsmandDevelopmentSimulateSpeedSelectorViewController.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAOpenAddTrackViewController.h"

@implementation OASimulateNavigationSpeed

+ (NSString *) toTitle:(EOASimulateNavigationSpeed)enumValue
{
    switch (enumValue)
    {
        case EOASimulateNavigationSpeedOriginal:
            return OALocalizedString(@"simulate_location_movement_speed_original");
        case EOASimulateNavigationSpeed2x:
            return OALocalizedString(@"simulate_location_movement_speed_x2");
        case EOASimulateNavigationSpeed3x:
            return OALocalizedString(@"simulate_location_movement_speed_x3");
        case EOASimulateNavigationSpeed4x:
            return OALocalizedString(@"simulate_location_movement_speed_x4");
    }
}

+ (NSString *) toDescription:(EOASimulateNavigationSpeed)enumValue
{
    switch (enumValue)
    {
        case EOASimulateNavigationSpeedOriginal:
            return OALocalizedString(@"simulate_location_movement_speed_original_desc");
        case EOASimulateNavigationSpeed2x:
            return OALocalizedString(@"simulate_location_movement_speed_x2_desc");
        case EOASimulateNavigationSpeed3x:
            return OALocalizedString(@"simulate_location_movement_speed_x3_desc");
        case EOASimulateNavigationSpeed4x:
            return OALocalizedString(@"simulate_location_movement_speed_x4_desc");
    }
}

+ (NSString *) toKey:(EOASimulateNavigationSpeed)enumValue
{
    switch (enumValue)
    {
        case EOASimulateNavigationSpeedOriginal:
            return @"SpeedOriginalKey";
        case EOASimulateNavigationSpeed2x:
            return @"Speed2xKey";
        case EOASimulateNavigationSpeed3x:
            return @"Speed3xKey";
        case EOASimulateNavigationSpeed4x:
            return @"Speed4xKey";
    }
}

+ (EOASimulateNavigationSpeed) fromKey:(NSString *)key
{
    if ([key isEqualToString:@"SpeedOriginalKey"])
        return EOASimulateNavigationSpeedOriginal;
    else if ([key isEqualToString:@"Speed2xKey"])
        return EOASimulateNavigationSpeed2x;
    else if ([key isEqualToString:@"Speed3xKey"])
        return EOASimulateNavigationSpeed3x;
    else if ([key isEqualToString:@"Speed4xKey"])
        return EOASimulateNavigationSpeed4x;
    else
        return EOASimulateNavigationSpeedOriginal;
}

@end


@implementation OAOsmandDevelopmentSimulateSpeedSelectorViewController
{
    NSArray<NSArray *> *_data;
    NSString *_headerDescription;
    EOASimulateNavigationSpeed _selectedSpeedMode;
}

NSString *const kUICellKey = @"kUICellKey";

#pragma mark - Initialization

- (void)commonInit
{
    _selectedSpeedMode = [OASimulateNavigationSpeed fromKey:OAAppSettings.sharedManager.simulateNavigationGpxTrackSpeedMode];
}

#pragma mark - UIViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadData];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"simulate_location_movement_speed");
}

#pragma mark - Table data

- (void) generateData
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *speedSection = [NSMutableArray array];
    [speedSection addObject:@{
        @"type" : kUICellKey,
        @"key" : [OASimulateNavigationSpeed toKey:EOASimulateNavigationSpeedOriginal],
        @"title" : [OASimulateNavigationSpeed toTitle:EOASimulateNavigationSpeedOriginal],
        @"selected" : @(_selectedSpeedMode == EOASimulateNavigationSpeedOriginal),
        @"actionBlock" : (^void(){ [self onSelectMode:EOASimulateNavigationSpeedOriginal]; }),
        @"footerTitle" : [OASimulateNavigationSpeed toDescription:_selectedSpeedMode],
    }];
    [speedSection addObject:@{
        @"type" : kUICellKey,
        @"key" : [OASimulateNavigationSpeed toKey:EOASimulateNavigationSpeed2x],
        @"title" : [OASimulateNavigationSpeed toTitle:EOASimulateNavigationSpeed2x],
        @"selected" : @(_selectedSpeedMode == EOASimulateNavigationSpeed2x),
        @"actionBlock" : (^void(){ [self onSelectMode:EOASimulateNavigationSpeed2x]; }),
    }];
    [speedSection addObject:@{
        @"type" : kUICellKey,
        @"key" : [OASimulateNavigationSpeed toKey:EOASimulateNavigationSpeed3x],
        @"title" : [OASimulateNavigationSpeed toTitle:EOASimulateNavigationSpeed3x],
        @"selected" : @(_selectedSpeedMode == EOASimulateNavigationSpeed3x),
        @"actionBlock" : (^void(){ [self onSelectMode:EOASimulateNavigationSpeed3x]; }),
    }];
    [speedSection addObject:@{
        @"type" : kUICellKey,
        @"key" : [OASimulateNavigationSpeed toKey:EOASimulateNavigationSpeed4x],
        @"title" : [OASimulateNavigationSpeed toTitle:EOASimulateNavigationSpeed4x],
        @"selected" : @(_selectedSpeedMode == EOASimulateNavigationSpeed4x),
        @"actionBlock" : (^void(){ [self onSelectMode:EOASimulateNavigationSpeed4x]; }),
    }];
    [tableData addObject:speedSection];
    
    _data = [NSArray arrayWithArray:tableData];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (void) reloadData
{
    [self generateData];
    [self.tableView reloadData];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    NSDictionary *item = [self getItem:[NSIndexPath indexPathForRow:0 inSection:section]];
    return item[@"footerTitle"];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kUICellKey])
    {
        UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:kUICellKey];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kUICellKey];
        }
        BOOL isSelected = [item[@"selected"] boolValue];
        cell.accessoryView = isSelected ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_cell_selected.png"]] : nil;
        NSString *regularText = item[@"title"];
        cell.textLabel.text = regularText;
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowPressed:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    void (^actionBlock)() = item[@"actionBlock"];
    if (actionBlock)
        actionBlock();
}

#pragma mark - Selectors

- (void) onSelectMode:(EOASimulateNavigationSpeed)mode
{
    if (_speedSelectorDelegate)
        [_speedSelectorDelegate onSpeedSelectorInformationUpdated:mode];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

