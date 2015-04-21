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

-(void)setupView {
    OAAppSettings* settings = [OAAppSettings sharedManager];
    switch (self.settingsType) {
        case kSettingsScreenGeneral: {
            NSString* metricSystemValue = settings.settingMetricSystem == 0 ? OALocalizedString(@"sett_km") : OALocalizedString(@"sett_ml");
            NSString* zoomButtonValue = settings.settingShowZoomButton ? OALocalizedString(@"sett_show") : OALocalizedString(@"sett_notshow");
            NSString* geoFormatValue = settings.settingGeoFormat == 0 ? OALocalizedString(@"sett_deg") : OALocalizedString(@"sett_deg_min");
            NSString* mapArrowsValue = settings.settingMapArrows == MAP_ARROWS_LOCATION ? OALocalizedString(@"sett_arr_loc") : OALocalizedString(@"sett_arr_map");
            
            self.data = @[
                          @{@"name": OALocalizedString(@"sett_units"), @"value": metricSystemValue, @"img": @"menu_cell_pointer.png"},
                          @{@"name": OALocalizedString(@"sett_zoom"), @"value": zoomButtonValue, @"img": @"menu_cell_pointer.png"},
                          @{@"name": OALocalizedString(@"sett_loc_fmt"), @"value": geoFormatValue, @"img": @"menu_cell_pointer.png"},
                          @{@"name": OALocalizedString(@"sett_arr"), @"value": mapArrowsValue, @"img": @"menu_cell_pointer.png"}
                          ];
        }
            break;
        case kSettingsScreenMetricSystem:
            self.data = @[@{@"name": OALocalizedString(@"sett_km"), @"value": @"", @"img": settings.settingMetricSystem == 0 ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"sett_ml"), @"value": @"", @"img": settings.settingMetricSystem == 1 ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        case kSettingsScreenZoomButton:
            self.data = @[@{@"name": OALocalizedString(@"sett_show"), @"value": @"", @"img": settings.settingShowZoomButton ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"sett_notshow"), @"value": @"", @"img": !settings.settingShowZoomButton ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        case kSettingsScreenGeoCoords:
            self.data = @[@{@"name": OALocalizedString(@"sett_deg"), @"value": @"", @"img": settings.settingGeoFormat == 0 ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"sett_deg_min"), @"value": @"", @"img": settings.settingGeoFormat == 1 ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        case kSettingsScreenMapArrows:
            self.data = @[@{@"name": OALocalizedString(@"sett_arr_loc"), @"value": @"", @"img": settings.settingMapArrows == MAP_ARROWS_LOCATION ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"sett_arr_map"), @"value": @"", @"img": settings.settingMapArrows == MAP_ARROWS_MAP_CENTER ? @"menu_cell_selected.png" : @""}
                          ];
            break;
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
        case kSettingsScreenMetricSystem:
            [self selectSettingMetricSystem:indexPath.row];
            break;
        case kSettingsScreenZoomButton:
            [self selectSettingZoomButton:indexPath.row];
            break;
        case kSettingsScreenGeoCoords:
            [self selectSettingGeoCode:indexPath.row];
            break;
        case kSettingsScreenMapArrows:
            [self selectSettingMapArrows:indexPath.row];
            break;
        default:
            break;
    }
}


-(void)selectSettingGeneral:(NSInteger)index {

    switch (index) {
        case 0: {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenMetricSystem];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
            break;
        case 1: {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenZoomButton];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
            break;
        case 2: {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenGeoCoords];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
            break;
        case 3: {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenMapArrows];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
            break;
            
        default:
            break;
    }
}


-(void)selectSettingMetricSystem:(NSInteger)index {
    [[OAAppSettings sharedManager] setSettingMetricSystem:index];
    [self backButtonClicked:nil];
}

-(void)selectSettingZoomButton:(NSInteger)index {
    [[OAAppSettings sharedManager] setSettingShowZoomButton:index==0];
    [self backButtonClicked:nil];
}

-(void)selectSettingGeoCode:(NSInteger)index {
    [[OAAppSettings sharedManager] setSettingGeoFormat:index];
    [self backButtonClicked:nil];
}

-(void)selectSettingMapArrows:(NSInteger)index {
    [[OAAppSettings sharedManager] setSettingMapArrows:index];
    [self backButtonClicked:nil];
}


@end
