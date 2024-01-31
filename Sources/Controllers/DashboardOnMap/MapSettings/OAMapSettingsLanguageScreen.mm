//
//  OAMapSettingsLanguageScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 10/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsLanguageScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#include "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"


@implementation OAMapSettingsLanguageScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    NSString *_prefLang;
    NSString *_prefLangId;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self) {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        
        title = OALocalizedString(@"map_locale");
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
    _prefLangId = _settings.settingPrefMapLanguage.get;
    if (_prefLangId)
        _prefLang = [[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:_prefLangId] capitalizedStringWithLocale:[NSLocale currentLocale]];
    else
        _prefLang = OALocalizedString(@"local_map_names");
    
    [tblView reloadData];
}


-(void)initData
{
}

-(void)updateMapLanguageSetting
{
    int currentValue = _settings.settingMapLanguage.get;
    
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
    if (_settings.settingPrefMapLanguage.get == nil)
    {
        newValue = 0;
        
        if (_settings.settingMapLanguageShowLocal && _settings.settingMapLanguageTranslit.get)
        {
            newValue = 5;
        }
        else if (_settings.settingMapLanguageTranslit.get)
        {
            newValue = 6;
        }
        
    }
    else if (_settings.settingMapLanguageShowLocal && _settings.settingMapLanguageTranslit.get)
    {
        newValue = 5;
    }
    else if (_settings.settingMapLanguageShowLocal)
    {
        newValue = 4;
    }
    else if (_settings.settingMapLanguageTranslit.get)
    {
        newValue = 6;
    }
    else
    {
        newValue = 1;
    }
    
    if (newValue != currentValue)
    {
        [_settings.settingMapLanguage set:newValue];
        [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        OAValueTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        if (cell)
        {
            [cell.titleLabel setText: OALocalizedString(@"sett_pref_lang")];
            [cell.valueLabel setText: _prefLang];
        }
        return cell;
    }
    else
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            if (indexPath.row == 1)
            {
                cell.titleLabel.text = OALocalizedString(@"sett_lang_show_local");

                [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
                [cell.switchView setOn:_settings.settingMapLanguageShowLocal];
                [cell.switchView addTarget:self action:@selector(showLocalChanged:) forControlEvents:UIControlEventValueChanged];
                
                if (!_prefLangId && !_settings.settingMapLanguageTranslit.get)
                {
                    cell.titleLabel.textColor = [UIColor lightGrayColor];
                    cell.switchView.enabled = NO;
                }
                else
                {
                    cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
                    cell.switchView.enabled = YES;
                }
            }
            else
            {
                cell.titleLabel.text = OALocalizedString(@"translit_names");
                cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];

                cell.switchView.enabled = YES;
                [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
                [cell.switchView setOn:_settings.settingMapLanguageTranslit.get];
                [cell.switchView addTarget:self action:@selector(showTranslitChanged:) forControlEvents:UIControlEventValueChanged];
            }
            
        }
        return cell;
    }
    return nil;
}

- (void) showLocalChanged:(id)sender
{
    UISwitch *sw = sender;
    _settings.settingMapLanguageShowLocal = sw.isOn;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMapLanguageSetting];
    });
}

- (void) showTranslitChanged:(id)sender
{
    UISwitch *sw = sender;
    [_settings.settingMapLanguageTranslit set:sw.isOn];

    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self updateMapLanguageSetting];
        
        [self.tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    });
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
    {
        OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenPreferredLanguage];
        
        [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
        
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
