//
//  OANavigationLanguageViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavigationLanguageViewController.h"
#import "OASettingsTitleTableViewCell.h"
#import "OAVoicePromptsViewController.h"
#import "OAAppSettings.h"

#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

@implementation OANavigationLanguageViewController
{
    OAAppSettings *_settings;
    NSArray<NSArray *> *_data;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_language");
}

#pragma mark - Table data

- (void)generateData
{
    NSDictionary *_screenVoiceProviders = [OAUtilities getSortedVoiceProviders];
    NSMutableArray *dataArr = [NSMutableArray array];
    NSString *selectedValue = [_settings.voiceProvider get:self.appMode];
    for (NSString *key in _screenVoiceProviders.allKeys)
    {
        [dataArr addObject: @{
           @"name" : _screenVoiceProviders[key],
           @"title" : key,
           @"type" : [OASettingsTitleTableViewCell getCellIdentifier],
           @"isSelected" : @([_screenVoiceProviders[key] isEqualToString:selectedValue]),
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
    if ([cellType isEqualToString:[OASettingsTitleTableViewCell getCellIdentifier]])
    {
        OASettingsTitleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
            [cell.iconView setHidden:YES];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            if ([item[@"isSelected"] boolValue])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
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
    [self slectVoiceLanguage:_data[indexPath.section][indexPath.row]];
}

#pragma mark - Selectors

- (void) slectVoiceLanguage:(NSDictionary *)item
{
    [_settings.voiceProvider set:item[@"name"] mode:self.appMode];
    [[OsmAndApp instance] initVoiceCommandPlayer:self.appMode warningNoneProvider:NO showDialog:YES force:NO];
    if (self.delegate)
        [self.delegate onSettingsChanged];
    [self dismissViewController];
}

@end
