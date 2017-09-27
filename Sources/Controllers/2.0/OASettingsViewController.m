//
//  OASettingsViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASettingsViewController.h"
#import "OASettingsTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAIAPHelper.h"
#import "OAUtilities.h"
#import "OANavigationSettingsViewController.h"

@interface OASettingsViewController ()

@property NSArray* data;

@end

@implementation OASettingsViewController

- (id) initWithSettingsType:(kSettingsScreen)settingsType
{
    self = [super init];
    if (self)
    {
        _settingsType = settingsType;
    }
    return self;
}

-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"sett_settings");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [self setupView];
}

- (void) setupView
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    switch (self.settingsType)
    {
        case kSettingsScreenMain:
        {
            self.data = @[
                          @{
                              @"name": OALocalizedString(@"general_settings_2"),
                              @"description": OALocalizedString(@"general_settings_descr"),
                              @"img": @"menu_cell_pointer.png" },
                          @{
                              @"name": OALocalizedString(@"routing_settings_2"),
                              @"description": OALocalizedString(@"routing_settings_descr"),
                              @"img": @"menu_cell_pointer.png" },
                          ];
            break;
        }
        case kSettingsScreenGeneral:
        {
            NSString* metricSystemValue = settings.metricSystem == KILOMETERS_AND_METERS ? OALocalizedString(@"sett_km") : OALocalizedString(@"sett_ml");
            NSString* geoFormatValue = settings.settingGeoFormat == MAP_GEO_FORMAT_DEGREES ? OALocalizedString(@"sett_deg") : OALocalizedString(@"sett_deg_min");
            NSString* showAltValue = settings.settingShowAltInDriveMode ? OALocalizedString(@"sett_show") : OALocalizedString(@"sett_notshow");
            NSString *recIntervalValue = [settings getFormattedTrackInterval:settings.mapSettingSaveTrackIntervalGlobal];
            NSString* doNotShowDiscountValue = settings.settingDoNotShowPromotions ? OALocalizedString(@"shared_string_yes") : OALocalizedString(@"shared_string_no");
            NSString* doNotUseFirebaseValue = settings.settingDoNotUseFirebase ? OALocalizedString(@"shared_string_yes") : OALocalizedString(@"shared_string_no");
            
            if (![[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_TrackRecording])
            {
                self.data = @[
                              @{
                                  @"name": OALocalizedString(@"sett_units"),
                                  @"value": metricSystemValue,
                                  @"img": @"menu_cell_pointer.png" },
                              @{
                                  @"name": OALocalizedString(@"sett_loc_fmt"),
                                  @"value": geoFormatValue,
                                  @"img": @"menu_cell_pointer.png" },
                              @{
                                  @"name": OALocalizedString(@"show_alt_in_drive"),
                                  @"value": showAltValue,
                                  @"img": @"menu_cell_pointer.png" },
                              @{
                                  @"name": OALocalizedString(@"do_not_show_discount"),
                                  @"value": doNotShowDiscountValue,
                                  @"img": @"menu_cell_pointer.png" },
                              @{
                                  @"name": OALocalizedString(@"do_not_send_anonymous_data"),
                                  @"value": doNotUseFirebaseValue,
                                  @"img": @"menu_cell_pointer.png" }
                              ];
            }
            else
            {
                self.data = @[
                              @{
                                  @"name": OALocalizedString(@"sett_units"),
                                  @"value": metricSystemValue,
                                  @"img": @"menu_cell_pointer.png" },
                              @{
                                  @"name": OALocalizedString(@"sett_loc_fmt"),
                                  @"value": geoFormatValue,
                                  @"img": @"menu_cell_pointer.png" },
                              @{
                                  @"name": OALocalizedString(@"show_alt_in_drive"),
                                  @"value": showAltValue,
                                  @"img": @"menu_cell_pointer.png" },
                              @{
                                  @"name": OALocalizedString(@"do_not_show_discount"),
                                  @"value": doNotShowDiscountValue,
                                  @"img": @"menu_cell_pointer.png" },
                              @{
                                  @"name": OALocalizedString(@"do_not_send_anonymous_data"),
                                  @"value": doNotUseFirebaseValue,
                                  @"img": @"menu_cell_pointer.png" },
                              @{
                                  @"name": OALocalizedString(@"rec_interval"),
                                  @"value": recIntervalValue,
                                  @"img": @"menu_cell_pointer.png" }
                              ];
            }
            break;
        }
        case kSettingsScreenMetricSystem:
        {
            _titleView.text = OALocalizedString(@"sett_units");
            self.data = @[@{@"name": OALocalizedString(@"sett_km"), @"value": @"", @"img": settings.metricSystem == KILOMETERS_AND_METERS ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"sett_ml"), @"value": @"", @"img": settings.metricSystem == MILES_AND_FEET ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        }
        case kSettingsScreenGeoCoords:
        {
            _titleView.text = OALocalizedString(@"sett_loc_fmt");
            self.data = @[@{@"name": OALocalizedString(@"sett_deg"), @"value": @"", @"img": settings.settingGeoFormat == MAP_GEO_FORMAT_DEGREES ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"sett_deg_min"), @"value": @"", @"img": settings.settingGeoFormat == MAP_GEO_FORMAT_MINUTES ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        }
        case kSettingsScreenShowAltInDrive:
        {
            _titleView.text = OALocalizedString(@"show_alt_in_drive");
            self.data = @[@{@"name": OALocalizedString(@"sett_show"), @"value": @"", @"img": settings.settingShowAltInDriveMode ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"sett_notshow"), @"value": @"", @"img": !settings.settingShowAltInDriveMode ? @"menu_cell_selected.png" : @""}
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
        case kSettingsScreenDoNotShowDiscount:
        {
            _titleView.text = OALocalizedString(@"do_not_show_discount");
            self.data = @[@{@"name": OALocalizedString(@"shared_string_yes"), @"value": @"", @"img": settings.settingDoNotShowPromotions ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"shared_string_no"), @"value": @"", @"img": !settings.settingDoNotShowPromotions ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        }
        case kSettingsScreenDoNotUseFirebase:
        {
            _titleView.text = OALocalizedString(@"do_not_send_anonymous_data");
            self.data = @[@{@"name": OALocalizedString(@"shared_string_yes"), @"value": @"", @"img": settings.settingDoNotUseFirebase ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"shared_string_no"), @"value": @"", @"img": !settings.settingDoNotUseFirebase ? @"menu_cell_selected.png" : @""}
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

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.data count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = self.data[indexPath.row];
    NSString *name = [item objectForKey:@"name"];
    NSString *value = [item objectForKey:@"value"];
    
    if (value.length > 0)
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
            [cell.textView setText:name];
            [cell.descriptionView setText:value];
            [cell.iconView setImage:[UIImage imageNamed:[item objectForKey:@"img"]]];
        }
        
        return cell;
    }
    else
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
            [cell.textView setText:name];
            [cell.iconView setImage:[UIImage imageNamed:[item objectForKey:@"img"]]];
        }
        
        return cell;
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = self.data[indexPath.row];
    NSString *name = [item objectForKey:@"name"];
    NSString *value = [item objectForKey:@"value"];
    if (value.length > 0)
        return [OASettingsTableViewCell getHeight:name value:value cellWidth:tableView.bounds.size.width];
    else
        return [OASettingsTitleTableViewCell getHeight:name cellWidth:tableView.bounds.size.width];
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.settingsType)
    {
        case kSettingsScreenMain:
            [self selectSettingMain:indexPath.row];
            break;

        case kSettingsScreenGeneral:
            [self selectSettingGeneral:indexPath.row];
            break;
        case kSettingsScreenMetricSystem:
            [self selectMetricSystem:indexPath.row];
            break;
        case kSettingsScreenGeoCoords:
            [self selectSettingGeoCode:indexPath.row];
            break;
        case kSettingsScreenShowAltInDrive:
            [self selectSettingShowAltInDrive:indexPath.row];
            break;
        case kSettingsScreenRecInterval:
            [self selectSettingRecInterval:indexPath.row];
            break;
        case kSettingsScreenDoNotShowDiscount:
            [self selectSettingDoNotShowDiscount:indexPath.row];
            break;
        case kSettingsScreenDoNotUseFirebase:
            [self selectSettingDoNotUseFirebase:indexPath.row];
            break;
        default:
            break;
    }
}

- (void) selectSettingMain:(NSInteger)index
{
    switch (index)
    {
        case 0:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenGeneral];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
        case 1:
        {
            OANavigationSettingsViewController* settingsViewController = [[OANavigationSettingsViewController alloc] initWithSettingsType:kNavigationSettingsScreenGeneral];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
            
        default:
            break;
    }
}

- (void) selectSettingGeneral:(NSInteger)index
{
    switch (index)
    {
        case 0:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenMetricSystem];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
        case 1:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenGeoCoords];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
        case 2:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenShowAltInDrive];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
        case 3:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenDoNotShowDiscount];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
        case 4:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenDoNotUseFirebase];
            [self.navigationController pushViewController:settingsViewController animated:YES];
            break;
        }
        case 5:
        {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenRecInterval];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
            break;
            
        default:
            break;
    }
}

- (void) selectMetricSystem:(NSInteger)index
{
    [[OAAppSettings sharedManager] setMetricSystem:index];
    [self backButtonClicked:nil];
}

- (void) selectSettingGeoCode:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingGeoFormat:(int)index];
    [self backButtonClicked:nil];
}

- (void) selectSettingShowAltInDrive:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingShowAltInDriveMode:index == 0];
    [self backButtonClicked:nil];
}

- (void) selectSettingRecInterval:(NSInteger)index
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings setMapSettingSaveTrackIntervalGlobal:[settings.trackIntervalArray[index] intValue]];
    [self backButtonClicked:nil];
}

- (void) selectSettingDoNotShowDiscount:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingDoNotShowPromotions:index == 0];
    [self backButtonClicked:nil];
}

- (void) selectSettingDoNotUseFirebase:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingDoNotUseFirebase:index == 0];
    [self backButtonClicked:nil];
}

@end
