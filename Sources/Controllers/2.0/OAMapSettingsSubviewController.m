//
//  OAMapSettingsSubviewController.m
//  OsmAnd
//
//  Created by Admin on 11/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsSubviewController.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAAppSettings.h"


@interface OAMapSettingsSubviewController ()
@property NSArray* data;
@end

@implementation OAMapSettingsSubviewController

-(id)initWithSettingsType:(kMapSettingsScreen)settingsType {
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
        case kMapSettingsScreenMapType:
            /*
            self.data = @[@{@"name": @"Day", @"value": @"", @"img": settings.settingAppMode == 0 ? @"menu_cell_selected.png" : @""},
                          @{@"name": @"Night", @"value": @"", @"img": settings.settingAppMode == 1 ? @"menu_cell_selected.png" : @""}
                          ];
            */
            break;
        case kMapSettingsScreenDetails:
            self.titleView.text = @"Details";
            self.data = @[@{@"key": mapSettingMoreDetailsKey, @"name": @"More details on map", @"value": settings.mapSettingMoreDetails ? @"YES" : @"NO", @"type": @"OASwitchCell"},
                          @{@"key": mapSettingRoadSurfaceKey, @"name": @"Show road surfaces", @"value": settings.mapSettingRoadSurface ? @"YES" : @"NO", @"type": @"OASwitchCell"},
                          @{@"key": mapSettingRoadQualityKey, @"name": @"Road quality", @"value": settings.mapSettingRoadQuality ? @"YES" : @"NO", @"type": @"OASwitchCell"},
                          @{@"key": mapSettingAccessRestrictionsKey, @"name": @"Show access restrictions", @"value": settings.mapSettingAccessRestrictions ? @"YES" : @"NO", @"type": @"OASwitchCell"},
                          @{@"key": mapSettingContourLinesKey, @"name": @"Show contour lines", @"value": settings.mapSettingContourLines, @"type": @"OASettingsCell"},
                          @{@"key": mapSettingColoredBuildingsKey, @"name": @"Colored buildings", @"value": settings.mapSettingColoredBuildings ? @"YES" : @"NO", @"type": @"OASwitchCell"},
                          @{@"key": mapSettingStreetLightingKey, @"name": @"Street lighting", @"value": settings.mapSettingStreetLighting ? @"YES" : @"NO", @"type": @"OASwitchCell"}
                          ];
            break;
        case kMapSettingsScreenRoutes:
            self.titleView.text = @"Routes";
            self.data = @[@{@"key": mapSettingShowCycleRoutesKey, @"name": @"Show cycle routes", @"value": settings.mapSettingShowCycleRoutes ? @"YES" : @"NO", @"type": @"OASwitchCell"},
                          @{@"key": mapSettingOsmcTracesKey, @"name": @"Hiking symbol overlay", @"value": settings.mapSettingOsmcTraces ? @"YES" : @"NO", @"type": @"OASwitchCell"},
                          @{@"key": mapSettingAlpineHikingKey, @"name": @"Alpine hiking view", @"value": settings.mapSettingAlpineHiking ? @"YES" : @"NO", @"type": @"OASwitchCell"},
                          @{@"key": mapSettingRoadStyleKey, @"name": @"Road style", @"value": settings.mapSettingRoadStyle, @"type": @"OASettingsCell"}
                          ];
            break;
        case kMapSettingsScreenHide:
            self.titleView.text = @"Hide";
            self.data = @[@{@"key": mapSettingNoAdminboundariesKey, @"name": @"Hide boundaries", @"value": settings.mapSettingNoAdminboundaries ? @"YES" : @"NO", @"type": @"OASwitchCell"},
                          @{@"key": mapSettingNoPolygonsKey, @"name": @"Hide polygons", @"value": settings.mapSettingNoPolygons ? @"YES" : @"NO", @"type": @"OASwitchCell"},
                          @{@"key": mapSettingHideBuildingsKey, @"name": @"Hide buildings", @"value": settings.mapSettingHideBuildings ? @"YES" : @"NO", @"type": @"OASwitchCell"}
                          ];
            break;
        case kMapSettingsContourLines:
            self.titleView.text = @"Show contour lines"; //--,16,15,14,13,12,11
            self.data = @[@{@"name": @"--", @"value": @"--", @"type": @"OASettingsCell"},
                          @{@"name": @"16", @"value": @"16", @"type": @"OASettingsCell"},
                          @{@"name": @"15", @"value": @"15", @"type": @"OASettingsCell"},
                          @{@"name": @"14", @"value": @"14", @"type": @"OASettingsCell"},
                          @{@"name": @"13", @"value": @"13", @"type": @"OASettingsCell"},
                          @{@"name": @"12", @"value": @"12", @"type": @"OASettingsCell"},
                          @{@"name": @"11", @"value": @"11", @"type": @"OASettingsCell"}
                          ];
            break;
        case kMapSettingsRoadStyle:
            self.titleView.text = @"Road style"; //,orange,germanRoadAtlas,americanRoadAtlas
            self.data = @[@{@"name": @"", @"value": @"", @"type": @"OASettingsCell"},
                          @{@"name": @"orange", @"value": @"orange", @"type": @"OASettingsCell"},
                          @{@"name": @"germanRoadAtlas", @"value": @"germanRoadAtlas", @"type": @"OASettingsCell"},
                          @{@"name": @"americanRoadAtlas", @"value": @"americanRoadAtlas", @"type": @"OASettingsCell"}
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
    
    NSString *cellType = [[self.data objectAtIndex:indexPath.row] objectForKey:@"type"];
    
    if ([cellType isEqualToString:@"OASettingsCell"]) {
        
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
            [cell.descriptionView setText: @""];
            
            NSString *key = [[self.data objectAtIndex:indexPath.row] objectForKey:@"key"];
            NSString *value = [[self.data objectAtIndex:indexPath.row] objectForKey:@"value"];
            
            OAAppSettings* settings = [OAAppSettings sharedManager];
            if (self.settingsType == kMapSettingsContourLines) {
                if ([settings.mapSettingContourLines isEqualToString:value])
                    [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
                else
                    [cell.iconView setImage:nil];
                
            } else if (self.settingsType == kMapSettingsRoadStyle) {
                if ([settings.mapSettingRoadStyle isEqualToString:value])
                    [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
                else
                    [cell.iconView setImage:nil];
                
            } else if ([key isEqualToString:mapSettingContourLinesKey]) {
                [cell.descriptionView setText: settings.mapSettingContourLines];
                
            } else if ([key isEqualToString:mapSettingRoadStyleKey]) {
                [cell.descriptionView setText: settings.mapSettingRoadStyle];
                
            }
            
        }
        
        return cell;

    } else if ([cellType isEqualToString:@"OASwitchCell"]) {
        
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            [cell.textView setText: [[self.data objectAtIndex:indexPath.row] objectForKey:@"name"]];
            [cell.switchView setOn:[[[self.data objectAtIndex:indexPath.row] objectForKey:@"value"] isEqualToString:@"YES"]];
            [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            cell.switchView.tag = indexPath.row;
        }
        
        return cell;
    }
    
    return nil;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [UIView new];
}

- (void) mapSettingSwitchChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView) {
        OAAppSettings* settings = [OAAppSettings sharedManager];
        NSString *key = [[self.data objectAtIndex:switchView.tag] objectForKey:@"key"];
        
        // --- Details
        if ([key isEqualToString:mapSettingMoreDetailsKey])
            [settings setMapSettingMoreDetails:switchView.isOn];
        if ([key isEqualToString:mapSettingRoadSurfaceKey])
            [settings setMapSettingRoadSurface:switchView.isOn];
        if ([key isEqualToString:mapSettingRoadQualityKey])
            [settings setMapSettingRoadQuality:switchView.isOn];
        if ([key isEqualToString:mapSettingAccessRestrictionsKey])
            [settings setMapSettingAccessRestrictions:switchView.isOn];
        if ([key isEqualToString:mapSettingColoredBuildingsKey])
            [settings setMapSettingColoredBuildings:switchView.isOn];
        if ([key isEqualToString:mapSettingStreetLightingKey])
            [settings setMapSettingStreetLighting:switchView.isOn];

        // --- Routes
        if ([key isEqualToString:mapSettingShowCycleRoutesKey])
            [settings setMapSettingShowCycleRoutes:switchView.isOn];
        if ([key isEqualToString:mapSettingOsmcTracesKey])
            [settings setMapSettingOsmcTraces:switchView.isOn];
        if ([key isEqualToString:mapSettingAlpineHikingKey])
            [settings setMapSettingAlpineHiking:switchView.isOn];

        // --- Hide
        if ([key isEqualToString:mapSettingNoAdminboundariesKey])
            [settings setMapSettingNoAdminboundaries:switchView.isOn];
        if ([key isEqualToString:mapSettingNoPolygonsKey])
            [settings setMapSettingNoPolygons:switchView.isOn];
        if ([key isEqualToString:mapSettingHideBuildingsKey])
            [settings setMapSettingHideBuildings:switchView.isOn];

    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.settingsType == kMapSettingsContourLines) {
        
        OAAppSettings* settings = [OAAppSettings sharedManager];
        NSString *value = [[self.data objectAtIndex:indexPath.row] objectForKey:@"value"];
        [settings setMapSettingContourLines:value];
        [self backButtonClicked:nil];
        return;
        
    } else if (self.settingsType == kMapSettingsRoadStyle) {
        
        OAAppSettings* settings = [OAAppSettings sharedManager];
        NSString *value = [[self.data objectAtIndex:indexPath.row] objectForKey:@"value"];
        [settings setMapSettingRoadStyle:value];
        [self backButtonClicked:nil];
        return;
        
    }
    
    NSString *key = [[self.data objectAtIndex:indexPath.row] objectForKey:@"key"];
    
    // --- Details
    if ([key isEqualToString:mapSettingContourLinesKey]) {
        OAMapSettingsSubviewController* settingsViewController = [[OAMapSettingsSubviewController alloc] initWithSettingsType:kMapSettingsContourLines];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    
    // --- Routes
    if ([key isEqualToString:mapSettingRoadStyleKey]) {
        OAMapSettingsSubviewController* settingsViewController = [[OAMapSettingsSubviewController alloc] initWithSettingsType:kMapSettingsRoadStyle];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end


