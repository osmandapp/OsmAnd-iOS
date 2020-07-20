//
//  OARecalculateRouteViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARecalculateRouteViewController.h"
#import "OASwitchTableViewCell.h"
#import "OATimeTableViewCell.h"
#import "OACustomPickerTableViewCell.h"
#import "OAApplicationMode.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16
#define kDistanceSection 1
#define kCellTypeDistance @"time_cell"
#define kCellTypePicker @"pickerCell"

@interface OARecalculateRouteViewController () <UITableViewDelegate, UITableViewDataSource, OACustomPickerTableViewCellDelegate>

@end

@implementation OARecalculateRouteViewController
{
    NSArray<NSArray *> *_data;
    NSIndexPath *_pickerIndexPath;
    NSArray<NSString *> *_possibleDistanceValues;
    NSString *_distanceValue;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithAppMode:appMode];
    if (self)
    {
        [self generateData];
    }
    return self;
}

- (void) generateData
{
    _distanceValue = @"200 m"; // needs to be changed
    _possibleDistanceValues = @[@"30 m", @"50 m", @"100 m", @"200 m", @"500 m", @"1 km", @"1.5 km"]; // needs to be changed
}

-(void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"recalculate_route");
    self.subtitleLabel.text = self.appMode.name;
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
    NSMutableArray *statusArr = [NSMutableArray array];
    NSMutableArray *distanceArr = [NSMutableArray array];
    [statusArr addObject:@{
        @"type" : @"OASwitchCell",
        @"title" : OALocalizedString(@"shared_string_enabled"),
        @"isOn" : @NO,
    }];
    [distanceArr addObject:@{
        @"type" : kCellTypeDistance,
        @"title" : OALocalizedString(@"shared_string_distance"),
        @"value" : _distanceValue,
    }];
    [distanceArr addObject:@{
        @"type" : kCellTypePicker,
    }];
    [tableData addObject:statusArr];
    [tableData addObject:distanceArr];
    _data = [NSArray arrayWithArray:tableData];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"OASwitchCell"])
    {
        static NSString* const identifierCell = @"OASwitchCell";
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.switchView.on = [item[@"isOn"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeDistance])
    {
        static NSString* const identifierCell = @"OATimeTableViewCell";
        OATimeTableViewCell* cell;
        cell = (OATimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATimeCell" owner:self options:nil];
            cell = (OATimeTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.lbTitle.text = item[@"title"];
        cell.lbTime.text = item[@"value"];
        cell.lbTime.textColor = UIColorFromRGB(color_text_footer);

        return cell;
    }
    else if ([cellType isEqualToString:kCellTypePicker])
    {
        static NSString* const identifierCell = @"OACustomPickerTableViewCell";
        OACustomPickerTableViewCell* cell;
        cell = (OACustomPickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OACustomPickerCell" owner:self options:nil];
            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
        }
        cell.dataArray = _possibleDistanceValues;
        NSInteger valueRow = [_possibleDistanceValues indexOfObject:_distanceValue];
        [cell.picker selectRow:valueRow inComponent:0 animated:NO];
        cell.picker.tag = indexPath.row;
        cell.delegate = self;
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 17.0;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kDistanceSection)
    {
        if ([self pickerIsShown])
            return 2;
        return 1;
    }
    return 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath isEqual:_pickerIndexPath])
        return 162.0;
    
    return UITableViewAutomaticDimension;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:kCellTypeDistance])
    {
        [self.tableView beginUpdates];

        if ([self pickerIsShown] && (_pickerIndexPath.row - 1 == indexPath.row))
            [self hideExistingPicker];
        else
        {
            NSIndexPath *newPickerIndexPath = [self calculateIndexPathForNewPicker:indexPath];
            if ([self pickerIsShown])
                [self hideExistingPicker];

            [self showNewPickerAtIndex:newPickerIndexPath];
            _pickerIndexPath = [NSIndexPath indexPathForRow:newPickerIndexPath.row + 1 inSection:indexPath.section];
        }

        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.tableView endUpdates];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone && indexPath != [NSIndexPath indexPathForRow:0 inSection:1] ? nil : indexPath;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return section == 0 ? OALocalizedString(@"route_recalculation_descr") : OALocalizedString(@"select_distance_for_recalculation");
}

#pragma mark - Switch

- (void) applyParameter:(id)sender
{
}

#pragma mark - Picker

- (BOOL) pickerIsShown
{
    return _pickerIndexPath != nil;
}

- (void) hideExistingPicker
{
    
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row inSection:_pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
    _pickerIndexPath = nil;
}

- (void) hidePicker
{
    [self.tableView beginUpdates];
    if ([self pickerIsShown])
        [self hideExistingPicker];
    [self.tableView endUpdates];
}

- (NSIndexPath *) calculateIndexPathForNewPicker:(NSIndexPath *)selectedIndexPath
{
   return [NSIndexPath indexPathForRow:selectedIndexPath.row inSection:kDistanceSection];
}

- (void) showNewPickerAtIndex:(NSIndexPath *)indexPath
{
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:kDistanceSection]];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
}

- (void) zoomChanged:(NSString *)zoom tag:(NSInteger)pickerTag
{
    _distanceValue = zoom;
    [self setupView];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row - 1 inSection:_pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
}

@end
