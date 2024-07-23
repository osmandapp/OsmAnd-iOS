//
//  OAVehicleParametersSettingsViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 30.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAVehicleParametersSettingsViewController.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAInputTableViewCell.h"
#import "OAHorizontalCollectionViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAUtilities.h"
#import "OAApplicationMode.h"

#define kDot @"."
#define kComma @","

@interface OAVehicleParametersSettingsViewController() <OAHorizontalCollectionViewCellDelegate, UITextFieldDelegate>

@end

@implementation OAVehicleParametersSettingsViewController
{
    NSArray<NSArray *> *_data;
    NSDictionary *_vehicleParameter;
    OAAppSettings *_settings;
    BOOL _isMotorType;
    
    NSArray<NSString *> *_measurementRangeStringArr;
    NSArray<NSNumber *> *_measurementRangeValuesArr;
    NSString *_measurementValue;
    NSNumber *_selectedParameter;
}

#pragma mark - Initialization

- (instancetype)initWithApplicationMode:(OAApplicationMode *)am vehicleParameter:(NSDictionary *)vp
{
    self = [super initWithAppMode:am];
    if (self)
    {
        _vehicleParameter = vp;
        [self postInit];
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)postInit
{
    if (_vehicleParameter)
    {
        _isMotorType = [_vehicleParameter[@"name"] isEqualToString:@"motor_type"];

        _measurementRangeValuesArr = [NSArray arrayWithArray:_vehicleParameter[@"possibleValues"]];
        NSMutableArray *arr = [NSMutableArray arrayWithArray:_vehicleParameter[@"possibleValuesDescr"]];
        if ([arr[0] isEqualToString:@"-"])
            [arr replaceObjectAtIndex:0 withObject:OALocalizedString(_isMotorType ? @"shared_string_not_selected" : @"shared_string_none")];
        _measurementRangeStringArr = [NSArray arrayWithArray:arr];
        _selectedParameter = _vehicleParameter[@"selectedItem"];
        NSString *valueString = _vehicleParameter[@"value"];
        if ([_selectedParameter intValue] != -1)
        {
            double vl = floorf(_measurementRangeValuesArr[_selectedParameter.intValue].doubleValue * 100 + 0.5) / 100;
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            formatter.minimumIntegerDigits = 1;
            formatter.minimumFractionDigits = 0;
            formatter.maximumFractionDigits = 1;
            formatter.decimalSeparator = kDot;
            _measurementValue = [formatter stringFromNumber:@(vl)];
        }
        else
        {
            _measurementValue = [valueString substringToIndex:valueString.length - (valueString.length > 0)];
        }
    }
}

- (void)registerNotifications
{
    if (!_isMotorType)
    {
        [self addNotification:UIKeyboardWillShowNotification selector:@selector(keyboardWillShow:)];
        [self addNotification:UIKeyboardWillHideNotification selector:@selector(keyboardWillHide:)];
    }
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _vehicleParameter[@"title"];
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return _isMotorType ? nil : @[[self createRightNavbarButton:OALocalizedString(@"shared_string_done")
                                                       iconName:nil
                                                         action:@selector(onRightNavbarButtonPressed)
                                                           menu:nil]];
}

- (NSString *)getTableHeaderDescription
{
    return [self getParameterDescription:_vehicleParameter[@"name"]];
}

- (void)setupTableHeaderView
{
    if (_isMotorType)
    {
        [super setupTableHeaderView];
    }
    else
    {
        NSString *text = [self getTableHeaderDescription];
        UIImage *image = [UIImage imageNamed:[self getParameterImage:_vehicleParameter[@"name"]]];
        if (!image && (!text || text.length == 0))
            return;
        
        CGFloat textWidth = DeviceScreenWidth - (kPaddingOnSideOfContent + [OAUtilities getLeftMargin]) * 2;
        CGFloat textHeight = [OAUtilities heightForHeaderViewText:text width:textWidth font:kHeaderDescriptionFontSmall lineSpacing:6.0];
        
        UIView *topImageDivider = [[UIView alloc] initWithFrame:CGRectMake(0., 0., DeviceScreenWidth, .5)];
        topImageDivider.backgroundColor = UIColorFromRGB(color_tint_gray);
        
        UIImageView *imageView = nil;
        UIView *imageBackgroundView = nil;
        if (image)
        {
            CGFloat aspectRatio = MIN(DeviceScreenWidth, DeviceScreenHeight) / image.size.width;
            imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0., 0., DeviceScreenWidth, image.size.height * aspectRatio)];
            imageView.image = image;
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            
            imageBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0., 0.5, DeviceScreenWidth, imageView.frame.size.height)];
            imageBackgroundView.backgroundColor = UIColor.whiteColor;
        }
        else
        {
            imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0., 0., DeviceScreenWidth, 0)];
            imageBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0., 0.5, DeviceScreenWidth, 0)];
        }
        
        UIView *bottomImageDivider = [[UIView alloc] initWithFrame:CGRectMake(0., imageView.frame.origin.y + imageView.frame.size.height, DeviceScreenWidth, .5)];
        bottomImageDivider.backgroundColor = UIColorFromRGB(color_tint_gray);
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kPaddingOnSideOfContent + [OAUtilities getLeftMargin], imageView.frame.size.height + 13., textWidth, textHeight)];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.minimumLineHeight = 17.;
        label.attributedText = [[NSAttributedString alloc] initWithString:text
                                                               attributes:@{ NSParagraphStyleAttributeName : style,
                                                                             NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer),
                                                                             NSFontAttributeName : kHeaderDescriptionFontSmall,
                                                                             NSBackgroundColorAttributeName : UIColor.clearColor }];
        label.numberOfLines = 0;
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        CGFloat headerHeight = label.frame.origin.y + label.frame.size.height + 26.;
        UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., DeviceScreenWidth, headerHeight)];
        if (image)
        {
            [tableHeaderView addSubview:imageBackgroundView];
            [tableHeaderView addSubview:imageView];
            [tableHeaderView addSubview:topImageDivider];
        }
        [tableHeaderView addSubview:bottomImageDivider];
        [tableHeaderView addSubview:label];
        tableHeaderView.backgroundColor = UIColor.clearColor;
        self.tableView.tableHeaderView = tableHeaderView;
    }
}
#pragma mark - UIViewContoller

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
}

#pragma mark - Table data

- (void)generateData
{
    NSString *parameter = _vehicleParameter[@"name"];
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *parametersArr = [NSMutableArray array];
    if (_isMotorType)
    {
        for (NSInteger i = 0; i < _measurementRangeStringArr.count; i++)
        {
            [parametersArr addObject:@{ @"type": [OARightIconTableViewCell getCellIdentifier] }];
        }
    }
    else
    {
        [parametersArr addObject:@{
            @"type" : [OAInputTableViewCell getCellIdentifier],
            @"title" : [self getMeasurementUnit:parameter],
            @"value" : [_measurementValue isEqualToString:OALocalizedString(@"shared_string_none")] ? @"0" : _measurementValue,
        }];
        [parametersArr addObject:@{
            @"type" : [OAHorizontalCollectionViewCell getCellIdentifier],
            @"selectedValue" : _selectedParameter,
            @"values" : _measurementRangeStringArr,
        }];
    }
    [tableData addObject:parametersArr];

    _data = tableData;
}

- (NSString *) getMeasurementUnit:(NSString *)parameter
{
    if ([parameter isEqualToString:@"weight"])
        return OALocalizedString(@"shared_string_tones");
    else if ([parameter isEqualToString:@"height"] || [parameter isEqualToString:@"width"] || [parameter isEqualToString:@"length"])
        return OALocalizedString(@"shared_string_meters");
    return @"";
}

- (BOOL)hideFirstHeader
{
    return YES;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OAInputTableViewCell getCellIdentifier]])
    {
        OAInputTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAInputTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAInputTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell clearButtonVisibility:NO];
            [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.keyboardType = UIKeyboardTypeDecimalPad;
            cell.inputField.tintColor = UIColorFromRGB(color_primary_purple);
            cell.inputField.delegate = self;
//            cell.inputField.userInteractionEnabled = NO;
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
        OAHorizontalCollectionViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAHorizontalCollectionViewCell getCellIdentifier]];
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
    else if ([cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            [cell.rightIconView setHidden:YES];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 20., 0., 0.);
            cell.titleLabel.text = _measurementRangeStringArr[indexPath.row];
            if ([_selectedParameter isEqualToNumber:_measurementRangeValuesArr[indexPath.row]])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OAInputTableViewCell getCellIdentifier]])
    {
        OAInputTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
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
    else if ([item[@"type"] isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        _selectedParameter = [NSNumber numberWithInteger:indexPath.row];
        _measurementValue = [self formattedSelectedValueStr:indexPath.row];
        [self onRightNavbarButtonPressed];
    }
}

#pragma mark - Additions

- (BOOL)isBoat
{
    return [self.appMode.getRoutingProfile isEqualToString:@"boat"];
}

- (NSString *)getParameterDescription:(NSString *)parameter
{
    if ([parameter isEqualToString:@"weight"])
        return OALocalizedString(@"weight_limit_description");
    else if ([parameter isEqualToString:@"height"])
        return [self isBoat] ? OALocalizedString(@"vessel_height_limit_description") : OALocalizedString(@"height_limit_description");
    else if ([parameter isEqualToString:@"width"])
        return  [self isBoat] ? OALocalizedString(@"vessel_width_limit_description") : OALocalizedString(@"width_limit_description");
    else if ([parameter isEqualToString:@"length"])
        return OALocalizedString(@"lenght_limit_description");
    else if ([parameter isEqualToString:@"motor_type"])
        return OALocalizedString(@"routing_attr_motor_type_description");
    return @"";
}

- (NSString *)getParameterImage:(NSString *)parameter
{
    if ([parameter isEqualToString:@"weight"])
        return @"img_help_weight_limit_day";
    else if ([parameter isEqualToString:@"height"])
        return [self isBoat] ? @"img_help_vessel_height_day" : @"img_help_height_limit_day";
    else if ([parameter isEqualToString:@"width"])
        return  [self isBoat] ? @"img_help_vessel_width_day" : @"img_help_width_limit_day";
    else if ([parameter isEqualToString:@"length"])
        return @"img_help_length_limit_day";
    else if ([parameter isEqualToString:@"motor_type"])
        return @"ic_custom_fuel";
    return @"";
}

- (NSString *) formattedSelectedValueStr:(NSInteger)index
{
    double vl = floorf(_measurementRangeValuesArr[index].doubleValue * 10 + 0.5) / 10;
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    formatter.minimumIntegerDigits = 1;
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 1;
    formatter.decimalSeparator = kDot;
    return [formatter stringFromNumber:@(vl)];
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    NSString *systemDecimalSeparator = NSLocale.autoupdatingCurrentLocale.decimalSeparator;
    _measurementValue = [_measurementValue stringByReplacingOccurrencesOfString:systemDecimalSeparator withString:kDot];
    _measurementValue = [_measurementValue stringByReplacingOccurrencesOfString:kComma withString:kDot];
    if ([_measurementValue hasPrefix:kDot] || [_measurementValue hasSuffix:kDot] || (![_measurementValue hasPrefix:@"0."]))
    {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        formatter.decimalSeparator = kDot;
        formatter.minimumIntegerDigits = 1;
        formatter.minimumFractionDigits = 0;
        formatter.maximumFractionDigits = 3;
        NSNumber *number = [formatter numberFromString:_measurementValue];
        _measurementValue = [formatter stringFromNumber:number];
    }
    if (_selectedParameter.intValue != -1)
        _measurementValue = [NSString stringWithFormat:@"%.2f", _measurementRangeValuesArr[_selectedParameter.intValue].doubleValue];
    OACommonString *property = [[OAAppSettings sharedManager] getCustomRoutingProperty:_vehicleParameter[@"name"] defaultValue:@"0"];
    [property set:_measurementValue mode:self.appMode];
    [self dismissViewController];
    if (self.delegate)
        [self.delegate onSettingsChanged];

    if (_isMotorType)
        [[OARootViewController instance].mapPanel updateRouteInfoData];
}

#pragma mark - OAHorizontalCollectionViewCellDelegate

- (void) valueChanged:(NSInteger)newValueIndex
{
    _selectedParameter = [NSNumber numberWithInteger:newValueIndex];
    _measurementValue = [self formattedSelectedValueStr:newValueIndex];
    
    [self generateData];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1], [NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
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
    if (_measurementValue.length == 0 || [_measurementValue isEqualToString:kDot])
    {
        _selectedParameter = [NSNumber numberWithInteger:0];
        _measurementValue = @"0";
    }
    [self generateData];
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
    if ([string isEqualToString:kDot])
    {
        if ([[textField.text componentsSeparatedByString:kDot] count] > 1)
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
