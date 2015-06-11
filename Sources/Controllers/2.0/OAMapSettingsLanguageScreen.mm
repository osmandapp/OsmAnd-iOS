//
//  OAMapSettingsLanguageScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 10/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsLanguageScreen.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#include "Localization.h"


@implementation OAMapSettingsLanguageScreen
{
    NSString *_prefLang;
    NSString *_prefLangId;
}

@synthesize settingsScreen, app, tableData, vwController, tblView, settings, title, isOnlineMapSource;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self) {
        app = [OsmAndApp instance];
        settings = [OAAppSettings sharedManager];
        
        title = OALocalizedString(@"sett_lang");
        settingsScreen = EMapSettingsScreenLanguage;
        
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
    _prefLangId = settings.settingPrefMapLanguage;
    if (_prefLangId)
        _prefLang = [[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:_prefLangId] capitalizedStringWithLocale:[NSLocale currentLocale]];
    else
        _prefLang = OALocalizedString(@"not_selected");
    
    [tblView reloadData];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (_prefLangId ? 3 : 1);
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* outCell = nil;
    
    if (indexPath.row == 0)
    {
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: OALocalizedString(@"sett_pref_lang")];
            [cell.descriptionView setText: _prefLang];
        }
        outCell = cell;
        
    }
    else
    {        
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            if (indexPath.row == 1)
            {
                [cell.textView setText: OALocalizedString(@"sett_lang_show_local")];

                [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
                [cell.switchView setOn:settings.settingMapLanguageShowLocal];
                [cell.switchView addTarget:self action:@selector(showLocalChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else
            {
                [cell.textView setText: OALocalizedString(@"sett_lang_show_trans")];
                
                [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
                [cell.switchView setOn:settings.settingMapLanguageTranslit];
                [cell.switchView addTarget:self action:@selector(showTranslitChanged:) forControlEvents:UIControlEventValueChanged];
            }
            
        }
        outCell = cell;
    }
    
    return outCell;
}

- (void)showLocalChanged:(id)sender
{
    UISwitch *sw = sender;
    settings.settingMapLanguageShowLocal = sw.isOn;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMapLanguageSetting];
    });
}

- (void)showTranslitChanged:(id)sender
{
    UISwitch *sw = sender;
    settings.settingMapLanguageTranslit = sw.isOn;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMapLanguageSetting];
    });
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenPreferredLanguage];
        
        [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
