//
//  OAMapSettingsPreferredLanguageScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 10/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsPreferredLanguageScreen.h"
#import "OASettingsTableViewCell.h"
#include "Localization.h"


@implementation OAMapSettingsPreferredLanguageScreen
{
    NSArray *_data;
}

@synthesize settingsScreen, app, tableData, vwController, tblView, settings, title, isOnlineMapSource;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self) {
        app = [OsmAndApp instance];
        settings = [OAAppSettings sharedManager];
        
        title = OALocalizedString(@"sett_pref_lang");
        settingsScreen = EMapSettingsScreenPreferredLanguage;
        
        vwController = viewController;
        tblView = tableView;
        
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void)dealloc
{
    [self deinit];
}

- (void)commonInit
{
}

- (void)deinit
{
}

- (void)setupView
{
    
    NSString *prefLang = settings.settingPrefMapLanguage;
    
    NSMutableArray *arr = [NSMutableArray array];
    
    [arr addObject:@{@"name": OALocalizedString(@"not_selected"), @"value": @"", @"img": (prefLang == nil ? @"menu_cell_selected.png" : @"")}];
    
    for (NSString *lang in settings.mapLanguages)
    {
        BOOL isSelected = (prefLang && [prefLang isEqualToString:lang]);
        NSString *langName = [[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:lang] capitalizedStringWithLocale:[NSLocale currentLocale]];
        [arr addObject:@{@"name": langName, @"value": lang, @"img": (isSelected ? @"menu_cell_selected.png" : @"")}];
    }
    _data = [NSArray arrayWithArray:arr];
}


-(void)initData
{
}

-(void)updateMapLanguageSetting
{
    int currentValue = settings.settingMapLanguage;
    
    /*
     // "name" only
     0 NativeOnly,
     
     // "name:$locale" or "name"
     1 LocalizedOrNative,
     
     // "name" and "name:$locale"
     2 NativeAndLocalized,
     
     // "name" and ( "name:$locale" or transliterate("name") )
     3 NativeAndLocalizedOrTransliterated,
     
     // "name:$locale" and "name"
     4 LocalizedAndNative,
     
     // ( "name:$locale" or transliterate("name") ) and "name"
     5 LocalizedOrTransliteratedAndNative
     
     // ( "name:$locale" or transliterate("name") )
     6 LocalizedOrTransliterated,
     
     */
    
    int newValue;
    if (settings.settingPrefMapLanguage == nil)
    {
        newValue = 0;
    }
    else if (settings.settingMapLanguageShowLocal && settings.settingMapLanguageTranslit)
    {
        newValue = 5;
    }
    else if (settings.settingMapLanguageShowLocal)
    {
        newValue = 4;
    }
    else if (settings.settingMapLanguageTranslit)
    {
        newValue = 6;
    }
    else
    {
        newValue = 1;
    }
    
    if (newValue != currentValue)
        [settings setSettingMapLanguage:newValue];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const identifierCell = @"OASettingsTableViewCell";
    OASettingsTableViewCell* cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
        cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        [cell.textView setText: [[_data objectAtIndex:indexPath.row] objectForKey:@"name"]];
        [cell.descriptionView setText: [[_data objectAtIndex:indexPath.row] objectForKey:@"value"]];
        [cell.iconView setImage:[UIImage imageNamed:[[_data objectAtIndex:indexPath.row] objectForKey:@"img"]]];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    int index = indexPath.row;
    if (index == 0)
        [settings setSettingPrefMapLanguage:nil];
    else
        [settings setSettingPrefMapLanguage:settings.mapLanguages[index - 1]];

    [self updateMapLanguageSetting];

    [self.vwController hide:NO animated:YES];
}

@end

