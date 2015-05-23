//
//  OASettingsViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASettingsViewController.h"
#import "OASettingsTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAIAPHelper.h"

@interface OASettingsViewController ()
@property NSArray* data;
@end

@implementation OASettingsViewController

-(id)initWithSettingsType:(kSettingsScreen)settingsType {
    self = [super init];
    if (self) {
        self.settingsType = settingsType;
    }
    return self;
}

-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"sett_settings");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated {

    [self setupView];
}

- (NSString *)getMapLangValueStr
{
    OAAppSettings* settings = [OAAppSettings sharedManager];

    NSString *prefLang;
    NSString *prefLangId = settings.settingPrefMapLanguage;
    if (prefLangId)
        prefLang = [[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:prefLangId] capitalizedStringWithLocale:[NSLocale currentLocale]];
    else
        prefLang = OALocalizedString(@"map_settings_none");
    
    NSString* languageValue;
    switch (settings.settingMapLanguage)
    {
        case 0: // NativeOnly
            languageValue = OALocalizedString(@"sett_lang_local");
            break;
        case 4: // LocalizedAndNative
            languageValue = [NSString stringWithFormat:@"%@ %@ %@", prefLang, OALocalizedString(@"shared_string_and"), OALocalizedString(@"sett_lang_local")];
            break;
        case 1: // LocalizedOrNative
            languageValue = [NSString stringWithFormat:@"%@ %@ %@", prefLang, OALocalizedString(@"shared_string_or"), OALocalizedString(@"sett_lang_local")];
            break;
        case 5: // LocalizedOrTransliteratedAndNative
            languageValue = [NSString stringWithFormat:@"%@ (%@) %@ %@", prefLang, OALocalizedString(@"sett_lang_trans"), OALocalizedString(@"shared_string_and"), OALocalizedString(@"sett_lang_local")];
            break;
        case 3: // LocalizedOrTransliterated
            languageValue = [NSString stringWithFormat:@"%@ (%@)", prefLang, OALocalizedString(@"sett_lang_trans")];
            break;
            
        default:
            break;
    }

    return languageValue;
}

-(void)setupView
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    switch (self.settingsType)
    {
        case kSettingsScreenGeneral:
        {
            NSString *languageValue = [self getMapLangValueStr];
            NSString* metricSystemValue = settings.settingMetricSystem == 0 ? OALocalizedString(@"sett_km") : OALocalizedString(@"sett_ml");
            NSString* zoomButtonValue = settings.settingShowZoomButton ? OALocalizedString(@"sett_show") : OALocalizedString(@"sett_notshow");
            NSString* geoFormatValue = settings.settingGeoFormat == 0 ? OALocalizedString(@"sett_deg") : OALocalizedString(@"sett_deg_min");
            NSString *recIntervalValue = [settings getFormattedTrackInterval:settings.mapSettingSaveTrackIntervalGlobal];
            
            if (![[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_TrackRecording])
            {
                self.data = @[
                              @{@"name": OALocalizedString(@"sett_lang"), @"value": languageValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"sett_units"), @"value": metricSystemValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"sett_zoom"), @"value": zoomButtonValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"sett_loc_fmt"), @"value": geoFormatValue, @"img": @"menu_cell_pointer.png"}
                              ];
            }
            else
            {
                self.data = @[
                              @{@"name": OALocalizedString(@"sett_lang"), @"value": languageValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"sett_units"), @"value": metricSystemValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"sett_zoom"), @"value": zoomButtonValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"sett_loc_fmt"), @"value": geoFormatValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"rec_interval"), @"value": recIntervalValue, @"img": @"menu_cell_pointer.png"}
                              ];
            }
            break;
        }
        case kSettingsScreenMetricSystem:
        {
            _titleView.text = OALocalizedString(@"sett_units");
            self.data = @[@{@"name": OALocalizedString(@"sett_km"), @"value": @"", @"img": settings.settingMetricSystem == 0 ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"sett_ml"), @"value": @"", @"img": settings.settingMetricSystem == 1 ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        }
        case kSettingsScreenZoomButton:
        {
            _titleView.text = OALocalizedString(@"sett_zoom");
            self.data = @[@{@"name": OALocalizedString(@"sett_show"), @"value": @"", @"img": settings.settingShowZoomButton ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"sett_notshow"), @"value": @"", @"img": !settings.settingShowZoomButton ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        }
        case kSettingsScreenGeoCoords:
        {
            _titleView.text = OALocalizedString(@"sett_loc_fmt");
            self.data = @[@{@"name": OALocalizedString(@"sett_deg"), @"value": @"", @"img": settings.settingGeoFormat == 0 ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"sett_deg_min"), @"value": @"", @"img": settings.settingGeoFormat == 1 ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        }
        case kSettingsScreenRecInterval:
        {
            _titleView.text = OALocalizedString(@"rec_interval");
            NSMutableArray *arr = [NSMutableArray array];
            for (NSNumber *num in settings.trackIntervalArray)
            {
                [arr addObject:@{@"name": [settings getFormattedTrackInterval:[num intValue]], @"value": @"", @"img": settings.mapSettingSaveTrackIntervalGlobal == [num intValue] ? @"menu_cell_selected.png" : @""}];
            }
            self.data = [NSArray arrayWithArray:arr];
            
            break;
        }
        
        case kSettingsScreenMapLanguage:
        {
            OAAppSettings* settings = [OAAppSettings sharedManager];
            
            NSString *prefLang;
            NSString *prefLangId = settings.settingPrefMapLanguage;
            if (prefLangId)
                prefLang = [[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:prefLangId] capitalizedStringWithLocale:[NSLocale currentLocale]];
            else
                prefLang = OALocalizedString(@"map_settings_none");

            _titleView.text = OALocalizedString(@"sett_lang");
            if (prefLangId)
            {
                self.data = @[
                              @{@"name": OALocalizedString(@"sett_pref_lang"), @"value": prefLang, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"sett_lang_show_local"), @"value": settings.settingMapLanguageShowLocal ? OALocalizedString(@"sett_show") : OALocalizedString(@"sett_notshow"), @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"sett_lang_show_trans"), @"value": settings.settingMapLanguageTranslit ? OALocalizedString(@"sett_show") : OALocalizedString(@"sett_notshow"), @"img": @"menu_cell_pointer.png"}
                              ];
            }
            else
            {
                self.data = @[
                              @{@"name": OALocalizedString(@"sett_pref_lang"), @"value": prefLang, @"img": @"menu_cell_pointer.png"}
                              ];
            }

            break;
        }
        case kSettingsScreenMapLanguagePreferred:
        {
            OAAppSettings* settings = [OAAppSettings sharedManager];
            
            _titleView.text = OALocalizedString(@"sett_pref_lang");
            
            NSString *prefLang = settings.settingPrefMapLanguage;
            
            NSMutableArray *arr = [NSMutableArray array];

            [arr addObject:@{@"name": OALocalizedString(@"map_settings_none"), @"value": @"", @"img": (prefLang == nil ? @"menu_cell_selected.png" : @"")}];
            
            for (NSString *lang in settings.mapLanguages)
            {
                BOOL isSelected = (prefLang && [prefLang isEqualToString:lang]);
                NSString *langName = [[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:lang] capitalizedStringWithLocale:[NSLocale currentLocale]];
                [arr addObject:@{@"name": langName, @"value": lang, @"img": (isSelected ? @"menu_cell_selected.png" : @"")}];
            }
            self.data = [NSArray arrayWithArray:arr];
            
            break;
        }
        case kSettingsScreenMapLanguageShowNative:
        {
            _titleView.text = OALocalizedString(@"sett_lang_show_local");
            self.data = @[@{@"name": OALocalizedString(@"sett_show"), @"value": @"", @"img": settings.settingMapLanguageShowLocal ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"sett_notshow"), @"value": @"", @"img": !settings.settingMapLanguageShowLocal ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        }
        case kSettingsScreenMapLanguageTranslit:
        {
            _titleView.text = OALocalizedString(@"sett_lang_show_trans");
            self.data = @[@{@"name": OALocalizedString(@"sett_show"), @"value": @"", @"img": settings.settingMapLanguageTranslit ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"sett_notshow"), @"value": @"", @"img": !settings.settingMapLanguageTranslit ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        }
        default:
            break;
    }
    
    [self.settingsTableView setDataSource: self];
    [self.settingsTableView setDelegate:self];
    self.settingsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.settingsTableView reloadData];
    [self.settingsTableView reloadInputViews];
    

}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString* const identifierCell = @"OASettingsTableViewCell";
    OASettingsTableViewCell* cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
        cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell) {
        [cell.textView setText: [[self.data objectAtIndex:indexPath.row] objectForKey:@"name"]];
        [cell.descriptionView setText: [[self.data objectAtIndex:indexPath.row] objectForKey:@"value"]];
        [cell.iconView setImage:[UIImage imageNamed:[[self.data objectAtIndex:indexPath.row] objectForKey:@"img"]]];
    }
    
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (self.settingsType) {
        case kSettingsScreenGeneral:
            [self selectSettingGeneral:indexPath.row];
            break;
            
        case kSettingsScreenMapLanguage:
            [self selectSettingMapLanguage:indexPath.row];
            break;
        case kSettingsScreenMapLanguagePreferred:
            [self selectSettingMapLanguagePreferred:indexPath.row];
            break;
        case kSettingsScreenMapLanguageShowNative:
            [self selectSettingMapLanguageShowNative:indexPath.row];
            break;
        case kSettingsScreenMapLanguageTranslit:
            [self selectSettingMapLanguageTranslit:indexPath.row];
            break;

        case kSettingsScreenMetricSystem:
            [self selectSettingMetricSystem:indexPath.row];
            break;
        case kSettingsScreenZoomButton:
            [self selectSettingZoomButton:indexPath.row];
            break;
        case kSettingsScreenGeoCoords:
            [self selectSettingGeoCode:indexPath.row];
            break;
        case kSettingsScreenRecInterval:
            [self selectSettingRecInterval:indexPath.row];
            break;
        default:
            break;
    }
}


-(void)selectSettingGeneral:(NSInteger)index {

    switch (index)
    {
        case 0:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenMapLanguage];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
        case 1:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenMetricSystem];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
        case 2:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenZoomButton];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
        case 3:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenGeoCoords];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
        case 4:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenRecInterval];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
            break;
            
        default:
            break;
    }
}


-(void)selectSettingMapLanguage:(NSInteger)index {
    
    switch (index)
    {
        case 0:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenMapLanguagePreferred];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
        case 1:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenMapLanguageShowNative];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
        case 2:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenMapLanguageTranslit];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
            
        default:
            break;
    }
}

-(void)updateMapLanguageSetting
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    int currentValue = settings.settingMapLanguage;
    
    /*
     // "name" only
     NativeOnly,
     
     // "name:$locale" or "name"
     LocalizedOrNative,
     
     // "name" and "name:$locale"
     NativeAndLocalized,
     
     // "name" and ( "name:$locale" or transliterate("name") )
     NativeAndLocalizedOrTransliterated,
     
     // "name:$locale" and "name"
     LocalizedAndNative,
     
     // ( "name:$locale" or transliterate("name") ) and "name"
     LocalizedOrTransliteratedAndNative
     
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
        newValue = 3; // ?
    }
    else
    {
        newValue = 1;
    }
    
    if (newValue != currentValue)
        [settings setSettingMapLanguage:newValue];
}

-(void)selectSettingMapLanguagePreferred:(NSInteger)index
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    if (index == 0)
    {
        [settings setSettingPrefMapLanguage:nil];
    }
    else
    {
        [settings setSettingPrefMapLanguage:settings.mapLanguages[index - 1]];
    }
    [self updateMapLanguageSetting];
    [self backButtonClicked:nil];
}

-(void)selectSettingMapLanguageShowNative:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingMapLanguageShowLocal:index == 0];
    [self updateMapLanguageSetting];
    [self backButtonClicked:nil];
}

-(void)selectSettingMapLanguageTranslit:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingMapLanguageTranslit:index == 0];
    [self updateMapLanguageSetting];
    [self backButtonClicked:nil];
}

-(void)selectSettingMetricSystem:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingMetricSystem:index];
    [self backButtonClicked:nil];
}

-(void)selectSettingZoomButton:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingShowZoomButton:index == 0];
    [self backButtonClicked:nil];
}

-(void)selectSettingGeoCode:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingGeoFormat:index];
    [self backButtonClicked:nil];
}

-(void)selectSettingRecInterval:(NSInteger)index
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings setMapSettingSaveTrackIntervalGlobal:[settings.trackIntervalArray[index] intValue]];
    [self backButtonClicked:nil];
}

@end
