//
//  OAVehicleParametersSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 30.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAVehicleParametersSettingsViewController.h"

#import "OAInputCellWithTitle.h"
#import "OAOnlyImageViewCell.h"
#import "OAHorizontalCollectionViewCell.h"

#import "Localization.h"

@interface OAVehicleParametersSettingsViewController() <OAHorizontalCollectionViewCellDelegate>

@end

@implementation OAVehicleParametersSettingsViewController
{
    NSArray<NSArray *> *_data;
    OAApplicationMode *_applicationMode;
    NSString *_vehicleParameter;
    NSString *_propertyImageName;
    NSString *_measurementUnit;
    NSArray<NSString *> *_measurementRangeArr;
    NSString *_description;
}

- (instancetype)initWithApplicationMode:(OAApplicationMode *)ap vehicleParameter:(NSString *)vp
{
    self = [super init];
    if (self)
    {
        _applicationMode = ap;
        _vehicleParameter = vp;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
}

- (void) applyLocalization
{
    self.titleLabel.text = _vehicleParameter;
    self.subtitleLabel.text = _applicationMode.name;
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (void) generateData
{
    if ([_vehicleParameter isEqualToString:OALocalizedString(@"routing_attr_weight_name")])
    {
        _propertyImageName = @"img_help_weight_limit_day";
        _measurementUnit = OALocalizedString(@"tones");
        _measurementRangeArr = @[@"None", @"1.5 t", @"3 t", @"3.5 t", @"7.5 t", @"10 t", @"12 t"]; // has to be changed
        _description = OALocalizedString(@"vehicle_height_descr"); // has to be changed
    }
    else if ([_vehicleParameter isEqualToString:OALocalizedString(@"routing_attr_height_name")])
    {
        _propertyImageName = @"img_help_height_limit_day";
        _measurementUnit = OALocalizedString(@"meters");
        _measurementRangeArr = @[];
        _description = OALocalizedString(@"vehicle_height_descr"); // has to be changed
    }
    else if ([_vehicleParameter isEqualToString:OALocalizedString(@"routing_attr_width_name")])
    {
        _propertyImageName = @"img_help_width_limit_day";
        _measurementUnit = OALocalizedString(@"meters");
        _measurementRangeArr = @[];
        _description = OALocalizedString(@"vehicle_height_descr"); // has to be changed
    }
    else if ([_vehicleParameter isEqualToString:OALocalizedString(@"routing_attr_length_name")])
    {
        _propertyImageName = @"";
        _measurementUnit = OALocalizedString(@"meters");
        _measurementRangeArr = @[];
        _description = OALocalizedString(@"vehicle_height_descr"); // has to be changed
    }
    else
    {
        _propertyImageName = @"";
        _measurementUnit = @"";
        _measurementRangeArr = @[];
        _description = @"";
    }
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setupView];
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *parametersArr = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
    [otherArr addObject:@{
        @"type" : @"OAOnlyImageViewCell",
        @"icon" : _propertyImageName,
    }];
    [parametersArr addObject:@{
        @"type" : @"OAInputCellWithTitle",
        @"title" : _measurementUnit,
        @"icon" : @"list_warnings_traffic_calming",
        @"isOn" : @YES,
    }];
    [parametersArr addObject:@{
        @"type" : @"OAHorizontalCollectionViewCell",
        @"title" : OALocalizedString(@"show_pedestrian_warnings"),
        @"icon" : @"list_warnings_pedestrian",
        @"isOn" : @YES,
    }];
    [tableData addObject:otherArr];
    [tableData addObject:parametersArr];
    _data = [NSArray arrayWithArray:tableData];
}

- (IBAction)doneButtonPressed:(id)sender {
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"OAOnlyImageViewCell"])
    {
        static NSString* const identifierCell = @"OAOnlyImageViewCell";
        OAOnlyImageViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAOnlyImageViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.imageView.image = [UIImage imageNamed:item[@"icon"]];
        }
        return cell;
    }
    else if([cellType isEqualToString:@"OAInputCellWithTitle"])
    {
        static NSString* const identifierCell = @"OAInputCellWithTitle";
        OAInputCellWithTitle* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAInputCellWithTitle *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
        }
        return cell;
    }
    else if([cellType isEqualToString:@"OAHorizontalCollectionViewCell"])
    {
        static NSString* const identifierCell = @"OAHorizontalCollectionViewCell";
        OAHorizontalCollectionViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAHorizontalCollectionViewCell *)[nib objectAtIndex:0];
            cell.dataArray = _measurementRangeArr;
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 0 ? _description : @"";
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

#pragma mark - OAHorizontalCollectionViewCellDelegate

- (void) iconChanged:(NSInteger)newValue
{
    
}

@end
