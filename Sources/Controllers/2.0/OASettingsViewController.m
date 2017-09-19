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
        case kSettingsScreenGeneral:
        {
            NSString* metricSystemValue = settings.settingMetricSystem == 0 ? OALocalizedString(@"sett_km") : OALocalizedString(@"sett_ml");
            NSString* geoFormatValue = settings.settingGeoFormat == MAP_GEO_FORMAT_DEGREES ? OALocalizedString(@"sett_deg") : OALocalizedString(@"sett_deg_min");
            NSString* showAltValue = settings.settingShowAltInDriveMode ? OALocalizedString(@"sett_show") : OALocalizedString(@"sett_notshow");
            NSString *recIntervalValue = [settings getFormattedTrackInterval:settings.mapSettingSaveTrackIntervalGlobal];
            NSString* doNotShowDiscountValue = settings.settingDoNotShowPromotions ? OALocalizedString(@"shared_string_yes") : OALocalizedString(@"shared_string_no");
            NSString* doNotUseFirebaseValue = settings.settingDoNotUseFirebase ? OALocalizedString(@"shared_string_yes") : OALocalizedString(@"shared_string_no");
            
            if (![[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_TrackRecording])
            {
                self.data = @[
                              @{@"name": OALocalizedString(@"sett_units"), @"value": metricSystemValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"sett_loc_fmt"), @"value": geoFormatValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"show_alt_in_drive"), @"value": showAltValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"do_not_show_discount"), @"value": doNotShowDiscountValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"do_not_send_anonymous_data"), @"value": doNotUseFirebaseValue, @"img": @"menu_cell_pointer.png"}
                              ];
            }
            else
            {
                self.data = @[
                              @{@"name": OALocalizedString(@"sett_units"), @"value": metricSystemValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"sett_loc_fmt"), @"value": geoFormatValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"show_alt_in_drive"), @"value": showAltValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"do_not_show_discount"), @"value": doNotShowDiscountValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"do_not_send_anonymous_data"), @"value": doNotUseFirebaseValue, @"img": @"menu_cell_pointer.png"},
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
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.settingsType)
    {
        case kSettingsScreenGeneral:
            [self selectSettingGeneral:indexPath.row];
            break;

        case kSettingsScreenMetricSystem:
            [self selectSettingMetricSystem:indexPath.row];
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


-(void)selectSettingGeneral:(NSInteger)index {

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

-(void)selectSettingMetricSystem:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingMetricSystem:index];
    [self backButtonClicked:nil];
}

-(void)selectSettingGeoCode:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingGeoFormat:index];
    [self backButtonClicked:nil];
}

-(void)selectSettingShowAltInDrive:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingShowAltInDriveMode:index == 0];
    [self backButtonClicked:nil];
}

-(void)selectSettingRecInterval:(NSInteger)index
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings setMapSettingSaveTrackIntervalGlobal:[settings.trackIntervalArray[index] intValue]];
    [self backButtonClicked:nil];
}

-(void)selectSettingDoNotShowDiscount:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingDoNotShowPromotions:index == 0];
    [self backButtonClicked:nil];
}

-(void)selectSettingDoNotUseFirebase:(NSInteger)index
{
    [[OAAppSettings sharedManager] setSettingDoNotUseFirebase:index == 0];
    [self backButtonClicked:nil];
}

@end
