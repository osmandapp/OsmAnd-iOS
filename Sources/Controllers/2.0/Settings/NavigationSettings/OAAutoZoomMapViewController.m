//
//  OAAutoZoomMapViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAutoZoomMapViewController.h"
#import "OASettingsTitleTableViewCell.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

@interface OAAutoZoomMapViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAAutoZoomMapViewController
{
    OAAppSettings *_settings;
    NSArray<NSArray *> *_data;
    NSArray<NSNumber *> *_zoomValues;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        [self generateData];
    }
    return self;
}

- (void) generateData
{
    NSMutableArray *dataArr = [NSMutableArray array];
    [dataArr addObject:
     @{
       @"title" : OALocalizedString(@"auto_zoom_none"),
       @"isSelected" : @(![_settings.autoZoomMap get:self.appMode]),
       @"type" : [OASettingsTitleTableViewCell getCellIdentifier]
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
           @"type" : [OASettingsTitleTableViewCell getCellIdentifier]
         }];
    }
    _data = [NSArray arrayWithObject:dataArr];
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"auto_zoom_map");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
    {
        OASettingsTitleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.iconView.image = [[UIImage imageNamed:@"ic_checkmark_default"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.hidden = ![item[@"isSelected"] boolValue];
        }
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 17.0;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectAutoZoomMap:_data[indexPath.section][indexPath.row]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

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
    [self backButtonClicked:nil];
}

@end

