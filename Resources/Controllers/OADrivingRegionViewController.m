//
//  OADrivingRegionViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADrivingRegionViewController.h"
#import "OAAppSettings.h"
#import "OAIconTextTableViewCell.h"
#import "OAAppSettings.h"
#import "OAFileNameTranslationHelper.h"
#import "OrderedDictionary.h"

#import "Localization.h"
#import "OAColors.h"

#define kCellTypeCheck @"OAIconTextCell"

@interface OADrivingRegionViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OADrivingRegionViewController
{
    NSArray<NSArray *> *_data;
    OAAppSettings *_settings;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
}

- (void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"driving_region");
    self.subtitleLabel.text = OALocalizedString(@"app_mode_car");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    _settings = [OAAppSettings sharedManager];
    [self setupView];
}

- (void) setupView
{
    BOOL automatic = _settings.drivingRegionAutomatic;
    int drivingRegion = _settings.drivingRegion;
    if (automatic)
        drivingRegion = -1;
    NSMutableArray *dataArr = [NSMutableArray array];
    [dataArr addObject:@{
        @"name" : @"AUTOMATIC",
        @"title" : OALocalizedString(@"driving_region_automatic"),
        @"description" : @"",
        @"value" : @"",
        @"img" : @(automatic),
        @"type" : kCellTypeCheck,
    }];
    [dataArr addObject:@{
        @"name" : @"DR_EUROPE_ASIA",
        @"title" : [OADrivingRegion getName:DR_EUROPE_ASIA],
        @"description" : [OADrivingRegion getDescription:DR_EUROPE_ASIA],
        @"value" : @"",
        @"img" : @(drivingRegion == DR_EUROPE_ASIA),
        @"type" : kCellTypeCheck,
    }];
    [dataArr addObject:@{
        @"name" : @"DR_US",
        @"title" : [OADrivingRegion getName:DR_US],
        @"description" : [OADrivingRegion getDescription:DR_US],
        @"value" : @"",
        @"img" : @(drivingRegion == DR_US),
        @"type" : kCellTypeCheck,
    }];
    [dataArr addObject:@{
        @"name" : @"DR_CANADA",
        @"title" : [OADrivingRegion getName:DR_CANADA],
        @"description" : [OADrivingRegion getDescription:DR_CANADA],
        @"img" : @(drivingRegion == DR_CANADA),
        @"type" : kCellTypeCheck,
    }];
    [dataArr addObject:@{
        @"name" : @"DR_UK_AND_OTHERS",
        @"title" : [OADrivingRegion getName:DR_UK_AND_OTHERS],
        @"description" : [OADrivingRegion getDescription:DR_UK_AND_OTHERS],
        @"img" : @(drivingRegion == DR_UK_AND_OTHERS),
        @"type" : kCellTypeCheck,
    }];
    [dataArr addObject:@{
        @"name" : @"DR_JAPAN",
        @"title" : [OADrivingRegion getName:DR_JAPAN],
        @"description" : [OADrivingRegion getDescription:DR_JAPAN],
        @"img" : @(drivingRegion == DR_JAPAN),
        @"type" : kCellTypeCheck,
    }];
    [dataArr addObject:@{
        @"name" : @"DR_AUSTRALIA",
        @"title" : [OADrivingRegion getName:DR_AUSTRALIA],
        @"description" : [OADrivingRegion getDescription:DR_AUSTRALIA],
        @"selected" : @(drivingRegion == DR_AUSTRALIA),
        @"type" : kCellTypeCheck,
    }];
    _data = [NSArray arrayWithObject:dataArr];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kCellTypeCheck])
    {
        static NSString* const identifierCell = kCellTypeCheck;
        OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.arrowIconView.image = [[UIImage imageNamed:@"ic_checkmark_default"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.arrowIconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.arrowIconView.hidden = ![item[@"selected"] boolValue];
            cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = [item[@"selected"] boolValue] ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 17.0;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *name = item[@"name"];
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if ([name isEqualToString:@"bearing"])
        [settings.rotateMap set:ROTATE_MAP_BEARING];
    else if ([name isEqualToString:@"compass"])
        [settings.rotateMap set:ROTATE_MAP_COMPASS];
    else
        [settings.rotateMap set:ROTATE_MAP_NONE];
    [self setupView];
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
