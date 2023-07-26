//
//  OAAutoZoomMapViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAutoZoomMapViewController.h"
#import "OASimpleTableViewCell.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

@implementation OAAutoZoomMapViewController
{
    OAAppSettings *_settings;
    NSArray<NSArray *> *_data;
    NSArray<NSNumber *> *_zoomValues;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"auto_zoom_map");
}

#pragma mark - Table data

- (void) generateData
{
    NSMutableArray *dataArr = [NSMutableArray array];
    [dataArr addObject:
     @{
       @"title" : OALocalizedString(@"auto_zoom_none"),
       @"isSelected" : @(![_settings.autoZoomMap get:self.appMode]),
       @"type" : [OASimpleTableViewCell getCellIdentifier]
     }];

    EOAAutoZoomMap autoZoomMap = [_settings.autoZoomMapScale get:self.appMode];
    NSArray<OAAutoZoomMap *> *values = [OAAutoZoomMap values];
    for (OAAutoZoomMap *v in values)
    {
        [dataArr addObject:
         @{
           @"name" : @(v.autoZoomMap),
           @"title" : v.name,
           @"isSelected" : @([_settings.autoZoomMap get:self.appMode] && v.autoZoomMap == autoZoomMap),
           @"type" : [OASimpleTableViewCell getCellIdentifier]
         }];
    }
    _data = [NSArray arrayWithObject:dataArr];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.accessoryType = [item[@"isSelected"] boolValue] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return 17.;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    [self selectAutoZoomMap:_data[indexPath.section][indexPath.row]];
}

#pragma mark - Selectors

- (void) selectAutoZoomMap:(NSDictionary *)item
{
    if (!item[@"name"])
    {
        [_settings.autoZoomMap set:NO mode:self.appMode];
    }
    else
    {
        [_settings.autoZoomMap set:YES mode:self.appMode];
        [_settings.autoZoomMapScale set:(EOAAutoZoomMap)((NSNumber *)item[@"name"]).intValue mode:self.appMode];
    }
    [self dismissViewController];
}

@end

