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
#import "OAAppSettings.h"

#import "Localization.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAUtilities.h"

#define kHeaderId @"TableViewSectionHeader"
#define kSidePadding 16
#define kHeaderViewFont [UIFont systemFontOfSize:15.0]
#define kDescriptionStringSection 1

@interface OAVehicleParametersSettingsViewController() <OAHorizontalCollectionViewCellDelegate, UITextFieldDelegate>

@end

@implementation OAVehicleParametersSettingsViewController
{
    NSArray<NSArray *> *_data;
    OAApplicationMode *_applicationMode;
    NSDictionary *_vehicleParameter;
    OAAppSettings *_settings;
    
    NSArray<NSString *> *_measurementRangeStringArr;
    NSArray<NSNumber *> *_measurementRangeValuesArr;
    NSString *_measurementValue;
    NSNumber *_selectedParameter;
}

- (instancetype) initWithApplicationMode:(OAApplicationMode *)am vehicleParameter:(NSDictionary *)vp
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        _applicationMode = am;
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
    return _applicationMode == OAApplicationMode.BOAT || _applicationMode.parent == OAApplicationMode.BOAT;
}

- (void) generateData
{
    _measurementRangeValuesArr = [NSArray arrayWithArray:_vehicleParameter[@"possibleValues"]];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:_vehicleParameter[@"possibleValuesDescr"]];
    if ([arr[0] isEqualToString:@"-"])
        [arr replaceObjectAtIndex:0 withObject:OALocalizedString(@"sett_no_ext_input")];
    _measurementRangeStringArr = [NSArray arrayWithArray:arr];
    _selectedParameter = _vehicleParameter[@"selectedItem"];
    NSString *valueString = [_vehicleParameter[@"value"] stringValue];
    if ([_selectedParameter intValue] != -1)
        _measurementValue = [_measurementRangeValuesArr[[_selectedParameter intValue]] stringValue];
    else
        _measurementValue = [valueString substringToIndex:valueString.length - (valueString.length > 0)];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16., 0., 0.);
    [self setupView];
}

- (NSString *) getParameterImage:(NSString *)parameter
{
    if ([parameter isEqualToString:@"weight"])
        return @"img_help_weight_limit_day";
    else if ([parameter isEqualToString:@"height"])
        return [self isBoat] ? @"img_help_vessel_height_day" : @"img_help_height_limit_day";
    else if ([parameter isEqualToString:@"width"])
        return  [self isBoat] ? @"img_help_vessel_width_day" : @"img_help_width_limit_day";
    else if ([parameter isEqualToString:@"length"])
        return @"img_help_length_limit_day";
    return @"";
}

- (NSString *) getMeasurementUnit:(NSString *)parameter
{
    if ([parameter isEqualToString:@"weight"])
        return OALocalizedString(@"tones");
    else if ([parameter isEqualToString:@"height"] || [parameter isEqualToString:@"width"] || [parameter isEqualToString:@"length"])
        return OALocalizedString(@"meters");
    return @"";
}

- (NSString *) getParameterDescription:(NSString *)parameter
{
    if ([parameter isEqualToString:@"weight"])
        return OALocalizedString(@"weight_limit_description");
    else if ([parameter isEqualToString:@"height"])
        return [self isBoat] ? OALocalizedString(@"vessel_height_limit_description") : OALocalizedString(@"height_limit_description");
    else if ([parameter isEqualToString:@"width"])
        return  [self isBoat] ? OALocalizedString(@"vessel_width_limit_description") : OALocalizedString(@"width_limit_description");
    else if ([parameter isEqualToString:@"length"])
        return OALocalizedString(@"lenght_limit_description");
    return @"";
}

- (void) setupView
{
    NSString *parameter = _vehicleParameter[@"name"];
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *parametersArr = [NSMutableArray array];
    NSMutableArray *otherArr = [NSMutableArray array];
    [otherArr addObject:@{
        @"type" : @"OAOnlyImageViewCell",
        @"icon" : [self getParameterImage:parameter],
    }];
    [parametersArr addObject:@{
        @"type" : @"OAInputCellWithTitle",
        @"title" : [self getMeasurementUnit:parameter],
        @"value" : [_measurementValue isEqualToString:OALocalizedString(@"sett_no_ext_input")] ? @"0" : _measurementValue,
    }];
    [parametersArr addObject:@{
        @"type" : @"OAHorizontalCollectionViewCell",
        @"selectedValue" : _selectedParameter,
        @"values" : _measurementRangeStringArr,
    }];
    [tableData addObject:otherArr];
    [tableData addObject:parametersArr];
    _data = [NSArray arrayWithArray:tableData];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.tableView reloadData];
    } completion:nil];
}

- (IBAction) doneButtonPressed:(id)sender
{
    if ([_measurementValue hasPrefix:@"."] || [_measurementValue hasSuffix:@"."] || (![_measurementValue hasPrefix:@"0."]))
    {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        formatter.minimumIntegerDigits = 1;
        formatter.minimumFractionDigits = 0;
        formatter.maximumFractionDigits = 3;
        _measurementValue = [[formatter numberFromString:_measurementValue] stringValue];
    }
    OAProfileString *property = [[OAAppSettings sharedManager] getCustomRoutingProperty:_vehicleParameter[@"name"] defaultValue:@"0"];
    [property set:_measurementValue mode:_applicationMode];
    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.delegate)
        [self.delegate onSettingsChanged];
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
    else if ([cellType isEqualToString:@"OAInputCellWithTitle"])
    {
        static NSString* const identifierCell = @"OAInputCellWithTitle";
        OAInputCellWithTitle* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAInputCellWithTitle *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.keyboardType = UIKeyboardTypeDecimalPad;
            cell.inputField.tintColor = UIColorFromRGB(color_primary_purple);
            cell.inputField.delegate = self;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.inputField.text = item[@"value"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:@"OAHorizontalCollectionViewCell"])
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
            cell.dataArray = item[@"values"];
            cell.selectedIndex = [item[@"selectedValue"] intValue];
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    return nil;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == kDescriptionStringSection)
    {
        NSString *parameter = _vehicleParameter[@"name"];
        NSString *descriptionString = [self getParameterDescription:parameter];
        CGFloat heightForHeader = [self heightForLabel:descriptionString];
        UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, tableView.bounds.size.width - OAUtilities.getLeftMargin * 2, heightForHeader)];
        CGFloat textWidth = self.tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
        UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, 0.0, textWidth, heightForHeader)];
        UIFont *labelFont = [UIFont systemFontOfSize:15.0];
        description.font = labelFont;
        [description setTextColor: UIColorFromRGB(color_text_footer)];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:6];
        description.attributedText = [[NSAttributedString alloc] initWithString:descriptionString attributes:@{NSParagraphStyleAttributeName : style}];
        description.numberOfLines = 0;
        [vw addSubview:description];
        return vw;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == kDescriptionStringSection)
    {
        NSString *parameter = _vehicleParameter[@"name"];
        NSString *descriptionString = [self getParameterDescription:parameter];
        CGFloat heightForHeader = [self heightForLabel:descriptionString];
        return heightForHeader + kSidePadding;
    }
    return 0.01;
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
    _selectedParameter = [NSNumber numberWithInteger:newValueIndex];
    _measurementValue = [NSString stringWithFormat:@"%@", _measurementRangeValuesArr[newValueIndex]];
    [self setupView];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

- (void) textViewDidChange:(UITextField *)textField
{
    _measurementValue = textField.text;
    _selectedParameter = [NSNumber numberWithInteger:-1];
    for (NSInteger i = 0; i < [_measurementRangeValuesArr count]; i++)
    {
        if ([[_measurementRangeValuesArr[i] stringValue] isEqualToString:_measurementValue])
        {
            _selectedParameter = [NSNumber numberWithInteger:i];
            break;
        }
    }
    if (_measurementValue.length == 0 || [_measurementValue isEqualToString:@"."])
    {
        _selectedParameter = [NSNumber numberWithInteger:0];
        _measurementValue = @"0";
    }
    [self setupView];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
}

- (BOOL) textFieldShouldClear:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    if ([textField.text isEqualToString:@"0"])
        textField.text = @"";
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField.text.length > 4 && ![string isEqualToString:@""])
        return NO;
    if ([string isEqualToString:@"."])
    {
        if ([[textField.text componentsSeparatedByString:@"."] count] > 1)
            return NO;
        return YES;
    }
    return YES;
}

@end
