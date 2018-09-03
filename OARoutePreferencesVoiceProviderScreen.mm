//
//  OARoutePreferencesVoiceProvider.m
//  OsmAnd
//
//  Created by Paul on 8/24/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARoutePreferencesVoiceProviderScreen.h"
#import "OARoutePreferencesAvoidRoadsScreen.h"
#import "OARoutePreferencesViewController.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAUtilities.h"
#import "OAAvoidSpecificRoads.h"
#import "OARoutingHelper.h"
#import "OAIconTextButtonCell.h"
#import "OAIconButtonCell.h"
#import "OAColors.h"
#import "OAStateChangedListener.h"
#import "OASettingsTitleTableViewCell.h"
#import "OAFileNameTranslationHelper.h"

#include <OsmAndCore/Utilities.h>

#define kCellTypeCheck @"check"

@implementation OARoutePreferencesVoiceProviderScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    NSArray<NSString *> *screenVoiceProviderValues;
    NSArray<NSString *> *screenVoiceProviderNames;
    
    NSArray<NSArray<NSDictionary *> *> *_data;
}

@synthesize preferencesScreen, tableData, vwController, tblView, title;

- (id) initWithTable:(UITableView *)tableView viewController:(OARoutePreferencesViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        
        title = OALocalizedString(@"voice_provider");
        preferencesScreen = ERoutePreferencesScreenVoiceProvider;
        
        screenVoiceProviderValues = [_settings.ttsAvailableVoices sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
        screenVoiceProviderNames = [OAFileNameTranslationHelper getVoiceNames:screenVoiceProviderValues];
        vwController = viewController;
        tblView = tableView;
        [self initData];
    }
    return self;
}

- (void) initData
{
}

- (void) deinitView
{
}

- (void) setupView
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray array];
    NSMutableArray *dataArr = [NSMutableArray array];
    for (int i = 0; i < screenVoiceProviderValues.count; i++)
    {
        [dataArr addObject:
         @{
           @"name" : screenVoiceProviderValues[i],
           @"title" : screenVoiceProviderNames[i],
           @"type" : kCellTypeCheck }
         ];
    }
    [data addObject:dataArr];
    
    _data = [NSArray arrayWithArray:data];
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *data = _data[indexPath.section][indexPath.row];
    NSString *type = data[@"type"];
    NSString *title = data[@"title"];
    if ([type isEqualToString:kCellTypeCheck])
    {
        return [OASettingsTitleTableViewCell getHeight:title cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return 44.0;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *type = item[@"type"];
    NSString *selectedValue = _settings.voiceProvider;
    
    if ([type isEqualToString:kCellTypeCheck])
    {
        static NSString* const identifierCell = @"OASettingsTitleTableViewCell";
        OASettingsTitleTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsTitleCell" owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.iconView setImage:[UIImage imageNamed:[item[@"name"] isEqualToString: selectedValue] ? @"menu_cell_selected.png" : @""]];
        }
        return cell;
    }
    
    return nil;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *data = _data[indexPath.section][indexPath.row];
    [_settings setVoiceProvider:data[@"name"]];
    [_app initVoiceCommandPlayer:nil warningNoneProvider:NO showDialog:YES force:NO];
    [vwController.parentVC.tableView reloadData];
    [vwController backButtonClicked:nil];
}

@end
