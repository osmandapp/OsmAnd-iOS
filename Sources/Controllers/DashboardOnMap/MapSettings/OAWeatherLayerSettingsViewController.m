//
//  OAWeatherLayerSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 02.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherLayerSettingsViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapStyleSettings.h"

#import "OASettingSwitchCell.h"
#import "OATextLineViewCell.h"
#import "OATitleSliderTableViewCell.h"
#import "OADividerCell.h"

#define kTempContourLines @"weatherTempContours"
#define kPressureContourLines @"weatherPressureContours"
#define kNoneContourLines @"none"

#define kSliderViewHeight 6.
#define kBottomOffset 16.

#define kSwitchCellLabelHeight 38.
#define kSwitchCellLabelHorizontalOffset 126.
#define kSwitchCellFixedHeight 10.

#define kTextLineCellFixedHeight 24.

#define kSliderCellHeight 87.

@interface OAWeatherLayerSettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *backButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *doneButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation OAWeatherLayerSettingsViewController
{
    EOAWeatherLayerType _layerType;
    BOOL _layerEnabled;
    NSString *_selectedContoursParam;
    
    NSArray<NSDictionary *> *_data;
    
    CGFloat _menuHeight;
    
    OsmAndAppInstance _app;
    OAMapStyleSettings *_styleSettings;
    OAMapPanelViewController *_mapPanel;
}

- (instancetype)initWithLayerType:(EOAWeatherLayerType)layerType
{
    self = [super initWithNibName:@"OAWeatherLayerSettingsViewController" bundle:nil];
    if (self)
    {
        _layerType = layerType;
        _layerEnabled = [self isLayerEnabled];
        _app = OsmAndApp.instance;
        _styleSettings = OAMapStyleSettings.sharedInstance;
        _mapPanel = OARootViewController.instance.mapPanel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self generateData];
    
    [self.backButton setImage:[UIImage templateImageNamed:@"ic_custom_arrow_back"] forState:UIControlStateNormal];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 44.;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_mapPanel setTopControlsVisible:NO
            onlyMapSettingsAndSearch:NO
                customStatusBarStyle:[OAAppSettings sharedManager].nightMode
                                        ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
    [_mapPanel.hudViewController hideBottomControls:_menuHeight animated:YES];
}

- (void)generateData
{
    _menuHeight = kSliderViewHeight;
    CGFloat horizontalMargin = OAUtilities.getTopMargin == 0 ? 16. : 20.;
    CGFloat width = DeviceScreenWidth - horizontalMargin * 2;

    NSString *localizedKey = [self getLayerLocalizedKey];
    NSMutableArray<NSDictionary *> *data = [NSMutableArray array];
    
    NSMutableArray<NSDictionary *> *layerRowData = [NSMutableArray array];
    [layerRowData addObject:@{
        @"cellId" : OASettingSwitchCell.getCellIdentifier,
        @"title" : OALocalizedString([NSString stringWithFormat:@"map_settings_%@", localizedKey]),
        @"image" : [self getLayerImageTitle]
    }];
    CGFloat switchCellLabelWidth = width - kSwitchCellLabelHorizontalOffset;
    _menuHeight += [OAUtilities calculateTextBounds:OALocalizedString([NSString stringWithFormat:@"map_settings_%@", localizedKey]) width:switchCellLabelWidth height:kSwitchCellLabelHeight font:[UIFont systemFontOfSize:17.]].height + kSwitchCellFixedHeight;
    
    if (_layerEnabled)
    {
        [layerRowData addObject:@{
            @"cellId" : OATitleSliderTableViewCell.getCellIdentifier,
            @"title" : OALocalizedString(@"map_settings_transp"),
            @"value" : @([self getLayerAlphaValue])
        }];
        _menuHeight += kSliderCellHeight;
    }
    else
    {
        [layerRowData addObject:@{
            @"cellId" : OATextLineViewCell.getCellIdentifier,
            @"title" : OALocalizedString([NSString stringWithFormat:@"%@_enable_descr", localizedKey])
        }];
        _menuHeight += [OAUtilities calculateTextBounds:OALocalizedString([NSString stringWithFormat:@"%@_enable_descr", localizedKey]) width:width font:[UIFont systemFontOfSize:17.]].height + kTextLineCellFixedHeight;
    }
    [data addObject:@{
        @"rows" : layerRowData
    }];
    
    _data = data;
    _menuHeight += OAUtilities.getBottomMargin + kBottomOffset;
}

- (BOOL)isLayerEnabled
{
    switch (_layerType) {
        case EOAWeatherLayerTypeTemperature:
            return _app.data.weatherTemp;
        case EOAWeatherLayerTypePresssure:
            return _app.data.weatherPressure;
        case EOAWeatherLayerTypeWind:
            return _app.data.weatherWind;
        case EOAWeatherLayerTypeCloud:
            return _app.data.weatherCloud;
        case EOAWeatherLayerTypePrecipitation:
            return _app.data.weatherPrecip;
        case EOAWeatherLayerTypeIsolines:
        {
            OAMapStyleParameter *tempContourLinesParam = [_styleSettings getParameter:kTempContourLines];
            OAMapStyleParameter *pressureContourLinesParam = [_styleSettings getParameter:kPressureContourLines];
            if ([tempContourLinesParam.value isEqualToString:@"true"])
                _selectedContoursParam = kTempContourLines;
            else if ([pressureContourLinesParam.value isEqualToString:@"true"])
                _selectedContoursParam = kPressureContourLines;
            else
                _selectedContoursParam = kNoneContourLines;
            return [tempContourLinesParam.value isEqualToString:@"true"] || [pressureContourLinesParam.value isEqualToString:@"true"];
        }
    }
}

- (double)getLayerAlphaValue
{
    switch (_layerType) {
        case EOAWeatherLayerTypeTemperature:
            return _app.data.weatherTempAlpha;
        case EOAWeatherLayerTypePresssure:
            return _app.data.weatherPressureAlpha;
        case EOAWeatherLayerTypeWind:
            return _app.data.weatherWindAlpha;
        case EOAWeatherLayerTypeCloud:
            return _app.data.weatherCloudAlpha;
        case EOAWeatherLayerTypePrecipitation:
            return _app.data.weatherPrecipAlpha;
        case EOAWeatherLayerTypeIsolines:
            // TODO: check if there is alpha
            return 1.;
    }
}

- (NSString *)getLayerLocalizedKey
{
    switch (_layerType) {
        case EOAWeatherLayerTypeTemperature:
            return @"weather_temp";
        case EOAWeatherLayerTypePresssure:
            return @"weather_pressure";
        case EOAWeatherLayerTypeWind:
            return @"weather_wind";
        case EOAWeatherLayerTypeCloud:
            return @"weather_cloud";
        case EOAWeatherLayerTypePrecipitation:
            return @"weather_precip";
        case EOAWeatherLayerTypeIsolines:
            return @"weather_isolines";
    }
}

- (NSString *)getLayerImageTitle
{
    switch (_layerType) {
        case EOAWeatherLayerTypeTemperature:
            return @"ic_custom_thermometer";
        case EOAWeatherLayerTypePresssure:
            return @"ic_custom_air_pressure";
        case EOAWeatherLayerTypeWind:
            return @"ic_custom_wind";
        case EOAWeatherLayerTypeCloud:
            return @"ic_custom_clouds";
        case EOAWeatherLayerTypePrecipitation:
            return @"ic_custom_precipitation";
        case EOAWeatherLayerTypeIsolines:
            return @"ic_custom_contour_lines";
    }
}

- (void)hideAndShowWeatherScreen:(BOOL)showWeatherScreen
{
    [_mapPanel setTopControlsVisible:YES];
    [_mapPanel.hudViewController showBottomControls:0. animated:YES];
    [_mapPanel hideScrollableHudViewController];
    if (showWeatherScreen)
        [_mapPanel showWeatherLayersScreen];
}

- (IBAction)backButtonPressed:(UIButton *)sender
{
    [self hideAndShowWeatherScreen:YES];
}

- (IBAction)doneButtonPressed:(UIButton *)sender
{
    [self hideAndShowWeatherScreen:NO];
}

- (void)onSwitchValueChanged:(UISwitch *)sender
{
    _layerEnabled = sender.isOn;
    switch (_layerType) {
        case EOAWeatherLayerTypeTemperature:
            _app.data.weatherTemp = _layerEnabled;
            break;
        case EOAWeatherLayerTypePresssure:
            _app.data.weatherPressure = _layerEnabled;
            break;
        case EOAWeatherLayerTypeWind:
            _app.data.weatherWind = _layerEnabled;
            break;
        case EOAWeatherLayerTypeCloud:
            _app.data.weatherCloud = _layerEnabled;
            break;
        case EOAWeatherLayerTypePrecipitation:
            _app.data.weatherPrecip = _layerEnabled;
            break;
        case EOAWeatherLayerTypeIsolines:
        {
            [self onIsolinesParamChangedToValue:kTempContourLines];
            break;
        }
    }
    [self generateData];
    [UIView transitionWithView:self.tableView duration:.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [self.tableView reloadData];
        [self goMinimized:NO];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)onIsolinesParamChangedToValue:(NSString *)newValue
{
    OAMapStyleParameter *tempContourLinesParam = [_styleSettings getParameter:kTempContourLines];
    OAMapStyleParameter *pressureContourLinesParam = [_styleSettings getParameter:kPressureContourLines];
    if ([kTempContourLines isEqualToString:newValue])
    {
        tempContourLinesParam.value = @"true";
        [_styleSettings save:tempContourLinesParam];
        _selectedContoursParam = kTempContourLines;
        pressureContourLinesParam.value = @"false";
        [_styleSettings save:pressureContourLinesParam];
    }
    else if ([kPressureContourLines isEqualToString:newValue])
    {
        tempContourLinesParam.value = @"false";
        [_styleSettings save:tempContourLinesParam];
        pressureContourLinesParam.value = @"true";
        [_styleSettings save:pressureContourLinesParam];
        _selectedContoursParam = kPressureContourLines;
    }
    else
    {
        tempContourLinesParam.value = @"false";
        [_styleSettings save:tempContourLinesParam];
        pressureContourLinesParam.value = @"false";
        [_styleSettings save:pressureContourLinesParam];
        _selectedContoursParam = kNoneContourLines;
    }
}

// MARK: UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *)_data[section][@"rows"]).count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][@"rows"][indexPath.row];
    NSString *cellId = item[@"cellId"];
    if ([cellId isEqualToString:OASettingSwitchCell.getCellIdentifier])
    {
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionView.hidden = YES;
            cell.separatorInset = UIEdgeInsetsMake(0., 0., 0., 0.);
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.imgView.image = [UIImage templateImageNamed:item[@"image"]];
            cell.imgView.tintColor = _layerEnabled ? UIColorFromRGB(color_dialog_buttons_dark) : UIColorFromRGB(color_tint_gray);
            
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView setOn:_layerEnabled];
            [cell.switchView addTarget:self action:@selector(onSwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellId isEqualToString:OATextLineViewCell.getCellIdentifier])
    {
        OATextLineViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OATextLineViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextLineViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextLineViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textView.textAlignment = NSTextAlignmentCenter;
            cell.textView.textColor = UIColorFromRGB(color_text_footer);
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
        }
        return cell;
    }
    else if ([cellId isEqualToString:OATitleSliderTableViewCell.getCellIdentifier])
    {
        OATitleSliderTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OATitleSliderTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleSliderTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleSliderTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.valueLabel.textColor = UIColorFromRGB(color_text_footer);
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = [NSString stringWithFormat:@"%.0f%%", [item[@"value"] doubleValue] * 100];
            [cell.sliderView setValue:[item[@"value"] floatValue]];
        }
        return cell;
    }
    return nil;
}

// MARK: OABaseScrollableHud

- (CGFloat)initialMenuHeight
{
    return _menuHeight;
}

- (CGFloat) getToolbarHeight
{
    return 0.;
}

- (BOOL)supportsFullScreen
{
    return NO;
}

- (BOOL) useGestureRecognizer
{
    return NO;
}

@end
