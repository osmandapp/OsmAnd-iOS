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
            NSString* appModeValue = settings.settingAppMode == 0 ? @"День" : (settings.settingAppMode == 1 ? @"Ночь" : @"Автовыбор");
            NSString* metricSystemValue = settings.settingMetricSystem == 0 ? @"Километры" : @"Милли";
            NSString* zoomButtonValue = settings.settingShowZoomButton ? @"Показывать" : @"Не показывать";
            NSString* geoFormatValue = settings.settingGeoFormat == 0 ? @"DDD.DD" : @"DD.DDD";
            
            self.data = @[@{@"name": @"Карты и ресурсы", @"value": @"", @"img": @"menu_cell_pointer.png"},
                          @{@"name": @"Режим приложения", @"value": appModeValue, @"img": @"menu_cell_pointer.png"},
                          @{@"name": @"Единицы измерения", @"value": metricSystemValue, @"img": @"menu_cell_pointer.png"},
                          @{@"name": @"Кнопка зума", @"value": zoomButtonValue, @"img": @"menu_cell_pointer.png"},
                          @{@"name": @"Формат гео координат", @"value": geoFormatValue, @"img": @"menu_cell_pointer.png"}
                          ];
        }
            break;
        case kSettingsScreenMapsAndResources:
            break;
        case kSettingsScreenAppMode:
            self.data = @[@{@"name": @"День", @"value": @"", @"img": settings.settingAppMode == 0 ? @"menu_cell_selected.png" : @""},
                          @{@"name": @"Ночь", @"value": @"", @"img": settings.settingAppMode == 1 ? @"menu_cell_selected.png" : @""},
                          @{@"name": @"Автовыбор", @"value": @"", @"img": settings.settingAppMode == 2 ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        case kSettingsScreenMetricSystem:
            self.data = @[@{@"name": @"Километры", @"value": @"", @"img": settings.settingMetricSystem == 0 ? @"menu_cell_selected.png" : @""},
                          @{@"name": @"Милли", @"value": @"", @"img": settings.settingMetricSystem == 1 ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        case kSettingsScreenZoomButton:
            self.data = @[@{@"name": @"Показывать", @"value": @"", @"img": settings.settingShowZoomButton ? @"menu_cell_selected.png" : @""},
                          @{@"name": @"Не показывать", @"value": @"", @"img": !settings.settingShowZoomButton ? @"menu_cell_selected.png" : @""}
                          ];
            break;
        case kSettingsScreenGeoCoords:
            self.data = @[@{@"name": @"DDD.DD", @"value": @"", @"img": settings.settingGeoFormat == 0 ? @"menu_cell_selected.png" : @""},
                          @{@"name": @"DD.DDD", @"value": @"", @"img": settings.settingGeoFormat == 1 ? @"menu_cell_selected.png" : @""}
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
    
    OASettingsTableViewCell* cell = nil;
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
    cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
    
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
        case kSettingsScreenMapsAndResources:
            [self selectSettingMaps:indexPath.row];
            break;
        case kSettingsScreenAppMode:
            [self selectSettingAppMode:indexPath.row];
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
        default:
            break;
    }
}


-(void)selectSettingGeneral:(NSInteger)index {

    switch (index) {
        case 0: {
            OASettingsViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
            [self.navigationController pushViewController:resourcesViewController animated:YES];

        }
            break;
        case 1: {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenAppMode];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
            break;
        case 2: {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenMetricSystem];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
            break;
        case 3: {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenZoomButton];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
            break;
        case 4: {
            OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenGeoCoords];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
            break;
            
        default:
            break;
    }
}

-(void)selectSettingMaps:(NSInteger)index {
    
    [self backButtonClicked:nil];
}

-(void)selectSettingAppMode:(NSInteger)index {
    [[OAAppSettings sharedManager] setSettingAppMode:index];
    [self backButtonClicked:nil];
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



@end
