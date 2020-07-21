//
//  OAVehicleParametersSettingsViewController.mm
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
    NSDictionary *_vehicleParameter;
    NSString *_propertyImageName;
    NSString *_measurementUnit;
    NSArray<NSNumber *> *_measurementRangeValuesArr;
    NSArray<NSString *> *_measurementRangeStringArr;
    NSString *_description;
    NSNumber *_selectedWeight;
}

- (instancetype)initWithApplicationMode:(OAApplicationMode *)ap vehicleParameter:(NSDictionary *)vp
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
    self.titleLabel.text = _vehicleParameter[@"title"];
    self.subtitleLabel.text = _applicationMode.name;
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (BOOL) isBoat
{
    if ([_applicationMode.name isEqual: @"Boat"] || [_applicationMode.parent.name isEqual: @"Boat"])
        return YES;
    return NO;
}

- (void) generateData
{
    NSString *parameter = _vehicleParameter[@"name"];
    if ([parameter isEqualToString:@"weight"])
    {
        _propertyImageName = @"img_help_weight_limit_day";
        _measurementUnit = OALocalizedString(@"tones");
        _selectedWeight = [NSNumber numberWithFloat:0];
        _measurementRangeValuesArr = [NSArray arrayWithArray:_vehicleParameter[@"possibleValues"]];
        NSMutableArray *array = [NSMutableArray arrayWithArray:_vehicleParameter[@"possibleValuesDescr"]];
        if ([array[0] isEqualToString:@"-"])
            [array replaceObjectAtIndex:0 withObject:OALocalizedString(@"sett_no_ext_input")];
        _measurementRangeStringArr = [NSArray arrayWithArray:array];
        _description = OALocalizedString(@"routing_attr_weight_description");
    }
    else if ([parameter isEqualToString:@"height"])
    {
        _propertyImageName = [self isBoat] ? @"img_help_vessel_height_day" :  @"img_help_height_limit_day";
        _measurementUnit = OALocalizedString(@"meters");
        _selectedWeight = [NSNumber numberWithFloat:0];
        _measurementRangeValuesArr = [NSArray arrayWithArray:_vehicleParameter[@"possibleValues"]];
        NSMutableArray *array = [NSMutableArray arrayWithArray:_vehicleParameter[@"possibleValuesDescr"]];
        if ([array[0] isEqualToString:@"-"])
            [array replaceObjectAtIndex:0 withObject:OALocalizedString(@"sett_no_ext_input")];
        _measurementRangeStringArr = [NSArray arrayWithArray:array];
        _description = [_applicationMode.name isEqual: @"Car"] ? OALocalizedString(@"routing_attr_height_description") : OALocalizedString(@"vessel_height_limit_description");
    }
    else if ([parameter isEqualToString:@"width"])
    {
        _propertyImageName = [self isBoat] ? @"img_help_vessel_width_day" : @"img_help_width_limit_day";
        _measurementUnit = OALocalizedString(@"meters");
        _selectedWeight = [NSNumber numberWithFloat:0];
        _measurementRangeValuesArr = [NSArray arrayWithArray:_vehicleParameter[@"possibleValues"]];
        NSMutableArray *array = [NSMutableArray arrayWithArray:_vehicleParameter[@"possibleValuesDescr"]];
        if ([array[0] isEqualToString:@"-"])
            [array replaceObjectAtIndex:0 withObject:OALocalizedString(@"sett_no_ext_input")];
        _measurementRangeStringArr = [NSArray arrayWithArray:array];
        _description = [_applicationMode.name isEqual: @"Car"] ? OALocalizedString(@"routing_attr_width_description") : OALocalizedString(@"vessel_width_limit_description");
    }
    else if ([parameter isEqualToString:@"length"])
    {
        _propertyImageName = @"img_help_length_limit_day";
        _measurementUnit = OALocalizedString(@"meters");
        _selectedWeight = [NSNumber numberWithFloat:0];
        _measurementRangeValuesArr = [NSArray arrayWithArray:_vehicleParameter[@"possibleValues"]];
        NSMutableArray *array = [NSMutableArray arrayWithArray:_vehicleParameter[@"possibleValuesDescr"]];
        if ([array[0] isEqualToString:@"-"])
            [array replaceObjectAtIndex:0 withObject:OALocalizedString(@"sett_no_ext_input")];
        _measurementRangeStringArr = [NSArray arrayWithArray:array];
        _description = OALocalizedString(@"routing_attr_length_description");
    }
    else
    {
        _propertyImageName = @"";
        _measurementUnit = @"";
        _selectedWeight = [NSNumber numberWithFloat:0];
        _measurementRangeValuesArr = @[];
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
        @"value" : _selectedWeight,
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
            cell.inputField.text = [NSString stringWithFormat:@"%@", item[@"value"]];
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
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.dataArray = _measurementRangeStringArr;
            cell.selectedIndex = [self getIndexOfValue];
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

- (void) valueChanged:(NSInteger)newValueIndex
{
    _selectedWeight = _measurementRangeValuesArr[newValueIndex];
    [self setupView];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1], [NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSInteger) getIndexOfValue
{
    return [_measurementRangeValuesArr indexOfObject:_selectedWeight];
}

@end
