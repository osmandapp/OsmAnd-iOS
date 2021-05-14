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

@interface OANavigationLanguageViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OANavigationLanguageViewController
{
    OAAppSettings *_settings;
    NSArray<NSArray *> *_data;
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
    NSDictionary *_screenVoiceProviders = [OAUtilities getSortedVoiceProviders];
    NSMutableArray *dataArr = [NSMutableArray array];
    NSString *selectedValue = [_settings.voiceProvider get:self.appMode];
    for (NSString *key in _screenVoiceProviders.allKeys)
    {
        [dataArr addObject: @{
           @"name" : _screenVoiceProviders[key],
           @"title" : key,
           @"type" : @"OASettingsTitleCell",
           @"isSelected" : @([_screenVoiceProviders[key] isEqualToString:selectedValue]),
         }];
    }
    _data = [NSArray arrayWithObject:dataArr];
}


- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"language");
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
            cell.iconView.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
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
    [self slectVoiceLanguage:_data[indexPath.section][indexPath.row]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void) slectVoiceLanguage:(NSDictionary *)item
{
    [_settings.voiceProvider set:item[@"name"] mode:self.appMode];
    [[OsmAndApp instance] initVoiceCommandPlayer:self.appMode warningNoneProvider:NO showDialog:YES force:NO];
    [self dismissViewController];
}

@end
