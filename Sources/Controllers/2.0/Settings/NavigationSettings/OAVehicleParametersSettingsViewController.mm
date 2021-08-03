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

#define kSidePadding 16
#define kHeaderViewFont [UIFont systemFontOfSize:15.0]
#define kDescriptionStringSection 1

@interface OAVehicleParametersSettingsViewController() <OAHorizontalCollectionViewCellDelegate, UITextFieldDelegate>

@end

@implementation OAVehicleParametersSettingsViewController
{
    NSArray<NSArray *> *_data;
    NSDictionary *_vehicleParameter;
    OAAppSettings *_settings;
    
    NSArray<NSString *> *_measurementRangeStringArr;
    NSArray<NSNumber *> *_measurementRangeValuesArr;
    NSString *_measurementValue;
    NSNumber *_selectedParameter;
}

- (instancetype) initWithApplicationMode:(OAApplicationMode *)am vehicleParameter:(NSDictionary *)vp
{
    self = [super initWithAppMode:am];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
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
    [super applyLocalization];
    self.titleLabel.text = _vehicleParameter[@"title"];
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (BOOL) isBoat
{
    return [self.appMode.getRoutingProfile isEqualToString:@"boat"];
}

- (void) generateData
{
    _measurementRangeValuesArr = [NSArray arrayWithArray:_vehicleParameter[@"possibleValues"]];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:_vehicleParameter[@"possibleValuesDescr"]];
    if ([arr[0] isEqualToString:@"-"])
        [arr replaceObjectAtIndex:0 withObject:OALocalizedString(@"sett_no_ext_input")];
    _measurementRangeStringArr = [NSArray arrayWithArray:arr];
    _selectedParameter = _vehicleParameter[@"selectedItem"];
    NSString *valueString = _vehicleParameter[@"value"];
    if ([_selectedParameter intValue] != -1)
    {
        double vl = floorf(_measurementRangeValuesArr[_selectedParameter.intValue].doubleValue * 100 + 0.5) / 100;
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        formatter.minimumIntegerDigits = 1;
        formatter.minimumFractionDigits = 0;
        formatter.maximumFractionDigits = 1;
        formatter.decimalSeparator = @".";
        _measurementValue = [formatter stringFromNumber:@(vl)];
    }
    else
        _measurementValue = [valueString substringToIndex:valueString.length - (valueString.length > 0)];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16., 0., 0.);
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 48.;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self applySafeAreaMargins];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
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
        return OALocalizedString(@"shared_string_meters");
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
        @"type" : [OAOnlyImageViewCell getCellIdentifier],
        @"icon" : [self getParameterImage:parameter],
    }];
    [parametersArr addObject:@{
        @"type" : [OAInputCellWithTitle getCellIdentifier],
        @"title" : [self getMeasurementUnit:parameter],
        @"value" : [_measurementValue isEqualToString:OALocalizedString(@"sett_no_ext_input")] ? @"0" : _measurementValue,
    }];
    [parametersArr addObject:@{
        @"type" : [OAHorizontalCollectionViewCell getCellIdentifier],
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
    if (_selectedParameter.intValue != -1)
        _measurementValue = [NSString stringWithFormat:@"%.2f", _measurementRangeValuesArr[_selectedParameter.intValue].doubleValue];
    OACommonString *property = [[OAAppSettings sharedManager] getCustomRoutingProperty:_vehicleParameter[@"name"] defaultValue:@"0"];
    [property set:_measurementValue mode:self.appMode];
    [self dismissViewController];
    if (self.delegate)
        [self.delegate onSettingsChanged];
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAOnlyImageViewCell getCellIdentifier]])
    {
        OAOnlyImageViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAOnlyImageViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAOnlyImageViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAOnlyImageViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.imageView.image = [UIImage imageNamed:item[@"icon"]];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAInputCellWithTitle getCellIdentifier]])
    {
        OAInputCellWithTitle* cell = [tableView dequeueReusableCellWithIdentifier:[OAInputCellWithTitle getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputCellWithTitle getCellIdentifier] owner:self options:nil];
            cell = (OAInputCellWithTitle *)[nib objectAtIndex:0];
            [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.keyboardType = UIKeyboardTypeDecimalPad;
            cell.inputField.tintColor = UIColorFromRGB(color_primary_purple);
            cell.inputField.delegate = self;
            cell.inputField.userInteractionEnabled = NO;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.inputField.text = item[@"value"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAHorizontalCollectionViewCell getCellIdentifier]])
    {
        OAHorizontalCollectionViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAHorizontalCollectionViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAHorizontalCollectionViewCell getCellIdentifier] owner:self options:nil];
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

- (NSString *) formattedSelectedValueStr:(NSInteger)index
{
    double vl = floorf(_measurementRangeValuesArr[index].doubleValue * 10 + 0.5) / 10;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    formatter.minimumIntegerDigits = 1;
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 1;
    formatter.decimalSeparator = @".";
    return [formatter stringFromNumber:@(vl)];
}

- (void) valueChanged:(NSInteger)newValueIndex
{
    _selectedParameter = [NSNumber numberWithInteger:newValueIndex];
    _measurementValue = [self formattedSelectedValueStr:newValueIndex];
    
    [self setupView];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1], [NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OAInputCellWithTitle getCellIdentifier]])
    {
        OAInputCellWithTitle *cell = (OAInputCellWithTitle *) [tableView cellForRowAtIndexPath:indexPath];
        if (cell.inputField.isFirstResponder)
        {
            [cell.inputField resignFirstResponder];
            cell.inputField.userInteractionEnabled = NO;
        }
        else
        {
            cell.inputField.userInteractionEnabled = YES;
            [cell.inputField becomeFirstResponder];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    sender.userInteractionEnabled = NO;
    return YES;
}

- (void) textViewDidChange:(UITextField *)textField
{
    _measurementValue = textField.text;
    _selectedParameter = [NSNumber numberWithInteger:-1];
    for (NSInteger i = 0; i < [_measurementRangeValuesArr count]; i++)
    {
        if ([[self formattedSelectedValueStr:i] isEqualToString:_measurementValue])
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
    textField.userInteractionEnabled = NO;
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

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardBounds;
    [[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        UIEdgeInsets insets = [self.tableView contentInset];
        [self.tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardBounds.size.height, insets.right)];
        [self.tableView setScrollIndicatorInsets:self.tableView.contentInset];
    } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        UIEdgeInsets insets = [self.tableView contentInset];
        [self.tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0.0, insets.right)];
        [self.tableView setScrollIndicatorInsets:self.tableView.contentInset];
    } completion:nil];
}

@end
