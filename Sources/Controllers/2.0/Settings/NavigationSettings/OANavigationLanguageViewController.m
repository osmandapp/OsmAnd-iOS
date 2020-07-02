//
//  OANavigationLanguageViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavigationLanguageViewController.h"
#import "OASettingsTitleTableViewCell.h"
#import "OAAppSettings.h"
#import "OAFileNameTranslationHelper.h"
#import "OrderedDictionary.h"

#import "Localization.h"
#import "OAColors.h"

@interface OANavigationLanguageViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OANavigationLanguageViewController
{
    NSArray<NSArray *> *_data;
    NSArray<NSString *> *_languagesArray;
    NSDictionary *_screenVoiceProviders;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
    _screenVoiceProviders = [self getSortedVoiceProviders];
    NSMutableArray *dataArr = [NSMutableArray array];
    for (NSString *key in _screenVoiceProviders.allKeys)
    {
        [dataArr addObject: @{
           @"name" : _screenVoiceProviders[key],
           @"title" : key,
           @"type" : @"OASettingsTitleCell",
           @"isSelected" : @NO,
         }];
    }
    _data = [NSArray arrayWithObject:dataArr];
}

- (NSDictionary *) getSortedVoiceProviders // have taken from OANavigationSettingsViewController
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSArray *screenVoiceProviderNames = [OAFileNameTranslationHelper getVoiceNames:settings.ttsAvailableVoices];
    OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjects:settings.ttsAvailableVoices forKeys:screenVoiceProviderNames];
    
    NSArray *sortedKeys = [mapping.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    MutableOrderedDictionary *res = [[MutableOrderedDictionary alloc] init];
    for (NSString *key in sortedKeys)
    {
        [res setObject:[mapping objectForKey:key] forKey:key];
    }
    return res;
}

- (void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"language");
    self.subtitleLabel.text = OALocalizedString(@"app_mode_car");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setupView];
}

- (void) setupView
{
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"OASettingsTitleCell"])
    {
        static NSString* const identifierCell = @"OASettingsTitleCell";
        OASettingsTitleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
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
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
