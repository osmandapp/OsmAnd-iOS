//
//  OAWeatherLayerSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 02.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherLayerSettingsViewController.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapStyleSettings.h"
#import "OAWeatherHelper.h"
#import "OAWeatherBand.h"
#import "OAWeatherToolbar.h"
#import "OAWeatherBandSettingsViewController.h"
#import "OAMapLayers.h"
#import "GeneratedAssetSymbols.h"

#import "OASwitchTableViewCell.h"
#import "OATextLineViewCell.h"
#import "OATitleSliderTableViewCell.h"
#import "OADividerCell.h"
#import "OAValueTableViewCell.h"

#define kSwitchCell @"switchCell"
#define kTransparencyCell @"transparencyCell"
#define kUnitsCell @"unitsCell"
#define kEnableDescrCell @"enableDescrCell"
#define kContoursTypeCell @"contoursTypeCell"

#define kSliderViewHeight 6.
#define kBottomOffset 16.

#define kSwitchCellLabelHeight 38.
#define kSwitchCellLabelHorizontalOffset 126.
#define kSwitchCellFixedHeight 10.

#define kTextLineCellFixedHeight 24.

#define kSliderCellHeight 87.

#define kTitleValueLabelHorizontalOffset 58.
#define kTitleValueFixedHeight 26.
#define kTitleValueLabelLeftSpacing 46.

#define kEmptyHeaderHeight 35.
#define kNonEmptyHeaderHeight 38.

#define kContoursTypesSection 1

@interface OAWeatherLayerSettingsViewController () <UITableViewDelegate, UITableViewDataSource, OAWeatherBandSettingsDelegate>

@property (weak, nonatomic) IBOutlet UIView *backButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *doneButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIView *sliderView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *backButtonLeadingConstraint;

@end

@implementation OAWeatherLayerSettingsViewController
{
    EOAWeatherLayerType _layerType;
    OAWeatherBand *_weatherBand;
    BOOL _layerEnabled;
    NSString *_selectedContoursParam;
    
    NSArray<NSDictionary *> *_data;
    
    CGFloat _menuHeight;
    CGFloat _dividerHeight;
    NSInteger _unitsSection;
    
    OsmAndAppInstance _app;
    OAMapStyleSettings *_styleSettings;
    OAMapPanelViewController *_mapPanel;
    BOOL _backButtonPressed;

    OAAutoObserverProxy *_weatherSettingsChangeObserver;
}

- (instancetype)initWithLayerType:(EOAWeatherLayerType)layerType
{
    self = [super initWithNibName:@"OAWeatherLayerSettingsViewController" bundle:nil];
    if (self)
    {
        _app = OsmAndApp.instance;
        _styleSettings = OAMapStyleSettings.sharedInstance;
        _mapPanel = OARootViewController.instance.mapPanel;
        _layerType = layerType;
        _weatherBand = [self getWeatherBand];
        _layerEnabled = [self isLayerEnabled];

        _weatherSettingsChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                            withHandler:@selector(onWeatherSettingsChange:withKey:andValue:)
                                                             andObserve:[OsmAndApp instance].data.weatherSettingsChangeObservable];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self applyLocalization];
    [self generateData];
    
    UIImage *backImage = [UIImage templateImageNamed:@"ic_custom_arrow_back"];
    [self.backButton setImage:[self.backButton isDirectionRTL] ? backImage.imageFlippedForRightToLeftLayoutDirection : backImage
                     forState:UIControlStateNormal];
    [self.backButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:0];
    if (_mapPanel.hudViewController.weatherToolbar.needsSettingsForToolbar)
        self.doneButtonContainerView.hidden = YES;
    else
        [self.doneButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:5];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 44.;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_mapPanel targetUpdateControlsLayout:YES
                     customStatusBarStyle:[OAAppSettings sharedManager].nightMode ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (!_backButtonPressed && _mapPanel.hudViewController.weatherToolbar.needsSettingsForToolbar)
    {
        _mapPanel.mapViewController.mapLayers.weatherDate = [NSDate date];
        _mapPanel.hudViewController.weatherToolbar.needsSettingsForToolbar = NO;
        [_app.data.weatherSettingsChangeObservable notifyEventWithKey:kWeatherSettingsReseting];
    }
    else if (_weatherSettingsChangeObserver)
    {
        [_weatherSettingsChangeObserver detach];
        _weatherSettingsChangeObserver = nil;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.sliderView.hidden = [self isLandscape];
        if (![self isLandscape])
            [self goMinimized:NO];
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
    {
        [self.backButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:0];
        if (!_mapPanel.hudViewController.weatherToolbar.needsSettingsForToolbar)
            [self.doneButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:5];
    }
}

- (void)applyLocalization
{
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (void)generateData
{
    _menuHeight = kSliderViewHeight;
    CGFloat horizontalMargin = OAUtilities.getBottomMargin == 0 ? 16. : 20.;
    CGFloat width = DeviceScreenWidth - horizontalMargin * 2;
    
    NSMutableArray<NSDictionary *> *data = [NSMutableArray array];
    
    NSMutableArray<NSDictionary *> *layerRowData = [NSMutableArray array];
    [data addObject:@{
        @"rows" : layerRowData
    }];
    
    NSString * layerTitle = _weatherBand ? _weatherBand.getMeasurementName : OALocalizedString(@"shared_string_contours");
    [layerRowData addObject:@{
        @"cellId" : OASwitchTableViewCell.getCellIdentifier,
        @"type" : kSwitchCell,
        @"title" : layerTitle,
        @"image" : _weatherBand ? _weatherBand.getIcon : @"ic_custom_contour_lines"
    }];
    CGFloat switchCellLabelWidth = width - kSwitchCellLabelHorizontalOffset;
    CGFloat labelHeight = [OAUtilities calculateTextBounds:layerTitle width:switchCellLabelWidth font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]].height;
    _menuHeight += fmax(labelHeight, kSwitchCellLabelHeight) + kSwitchCellFixedHeight;
    
    _dividerHeight = 1.0 / [UIScreen mainScreen].scale;
    NSNumber *dividerInset = @(0.);
    NSDictionary *dividerCell = @{
        @"cellId" : OADividerCell.getCellIdentifier,
        @"inset" : dividerInset
    };
    [layerRowData addObject:dividerCell];
    _menuHeight += [OADividerCell cellHeight:_dividerHeight dividerInsets:UIEdgeInsetsMake(0., [dividerInset floatValue], 0., 0.)];
    
    if (_layerEnabled)
    {
        NSDictionary *transparencyRow = @{
            @"cellId" : OATitleSliderTableViewCell.getCellIdentifier,
            @"type" : kTransparencyCell,
            @"title" : OALocalizedString(@"shared_string_transparency"),
            @"value" : @([self getLayerAlphaValue])
        };
        
        if (_layerType == EOAWeatherLayerTypeContours)
        {
            _unitsSection = 3;
            NSMutableArray<NSDictionary *> *contoursTypesRows = [NSMutableArray array];
            [contoursTypesRows addObject:dividerCell];
            _menuHeight += [OADividerCell cellHeight:_dividerHeight dividerInsets:UIEdgeInsetsMake(0., [dividerInset floatValue], 0., 0.)];
            NSArray<OAWeatherBand *> *contours = @[[OAWeatherBand withWeatherBand:WEATHER_BAND_TEMPERATURE],
                                                   [OAWeatherBand withWeatherBand:WEATHER_BAND_PRESSURE],
                                                   [OAWeatherBand withWeatherBand:WEATHER_BAND_CLOUD],
                                                   [OAWeatherBand withWeatherBand:WEATHER_BAND_WIND_SPEED],
                                                   [OAWeatherBand withWeatherBand:WEATHER_BAND_PRECIPITATION]];

            for (NSInteger i = 0; i < contours.count; i++) {
                OAWeatherBand *band = contours[i];
                NSString *contoursType = @"";
                switch (band.bandIndex)
                {
                    case WEATHER_BAND_TEMPERATURE:
                        contoursType = WEATHER_TEMP_CONTOUR_LINES_ATTR;
                        break;
                    case WEATHER_BAND_PRESSURE:
                        contoursType = WEATHER_PRESSURE_CONTOURS_LINES_ATTR;
                        break;
                    case WEATHER_BAND_CLOUD:
                        contoursType = WEATHER_CLOUD_CONTOURS_LINES_ATTR;
                        break;
                    case WEATHER_BAND_WIND_SPEED:
                        contoursType = WEATHER_WIND_CONTOURS_LINES_ATTR;
                        break;
                    case WEATHER_BAND_PRECIPITATION:
                        contoursType = WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR;
                        break;
                    case WEATHER_BAND_UNDEFINED:
                        break;
                }
                [contoursTypesRows addObject:@{
                    @"cellId" : OAValueTableViewCell.getCellIdentifier,
                    @"type" : kContoursTypeCell,
                    @"title" : band.getMeasurementName,
                    @"image" : band.getIcon,
                    @"contoursType" : contoursType
                }];
                CGFloat titleHeight = [OAUtilities calculateTextBounds:band.getMeasurementName width:width - kTitleValueLabelHorizontalOffset font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]].height;
                _menuHeight += titleHeight + kTitleValueFixedHeight;
                
                NSNumber *separatorInset = i < contours.count - 1 ? @(horizontalMargin + kTitleValueLabelLeftSpacing) : @(0.);
                NSMutableDictionary *dividerRow = [NSMutableDictionary dictionaryWithDictionary:dividerCell];
                dividerRow[@"inset"] = separatorInset;
                [contoursTypesRows addObject:dividerRow];
                _menuHeight += [OADividerCell cellHeight:_dividerHeight dividerInsets:UIEdgeInsetsMake(0., [separatorInset floatValue], 0., 0.)];
            }
                        
            _menuHeight += kNonEmptyHeaderHeight;
            [data addObject:@{
                @"sectionTitle" : OALocalizedString(@"shared_string_type"),
                @"rows" : contoursTypesRows
            }];
            
            _menuHeight += kEmptyHeaderHeight;
            [data addObject:@{
                @"rows" : @[dividerCell, transparencyRow, dividerCell]
            }];
            _menuHeight += [OADividerCell cellHeight:_dividerHeight dividerInsets:UIEdgeInsetsMake(0., [dividerInset floatValue], 0., 0.)] * 2;
            _menuHeight += kSliderCellHeight;
        }
        else
        {
            _unitsSection = 1;
            [layerRowData addObject:transparencyRow];
            _menuHeight += kSliderCellHeight;
            
            [layerRowData addObject:dividerCell];
            _menuHeight += [OADividerCell cellHeight:_dividerHeight dividerInsets:UIEdgeInsetsMake(0., [dividerInset floatValue], 0., 0.)];
        }
        
        _menuHeight += kEmptyHeaderHeight;
        
        NSMutableArray<NSDictionary *> *unitsRows = [NSMutableArray array];
        
        [unitsRows addObject:dividerCell];
        _menuHeight += [OADividerCell cellHeight:_dividerHeight dividerInsets:UIEdgeInsetsMake(0., [dividerInset floatValue], 0., 0.)];
        
        NSDictionary *unitsRow = @{
            @"cellId" : OAValueTableViewCell.getCellIdentifier,
            @"type" : kUnitsCell,
            @"title" : OALocalizedString(@"sett_units"),
        };
        [unitsRows addObject:unitsRow];
        CGFloat valueWidth = [OAUtilities calculateTextBounds:[self getUnitsValue] width:DeviceScreenWidth font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]].width;
        CGFloat titleWidth = width - kTitleValueLabelHorizontalOffset - valueWidth;
        CGFloat titleHeight = [OAUtilities calculateTextBounds:OALocalizedString(@"sett_units") width:titleWidth font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]].height;
        _menuHeight += kTitleValueFixedHeight + titleHeight;
        
        [unitsRows addObject:dividerCell];
        _menuHeight += [OADividerCell cellHeight:_dividerHeight dividerInsets:UIEdgeInsetsMake(0., [dividerInset floatValue], 0., 0.)];
        
        [data addObject:@{
            @"rows" : unitsRows
        }];
    }
    else
    {
        NSString *text = OALocalizedString([NSString stringWithFormat:@"%@_enable_descr", [self getLayerLocalizedKey]]);
        [layerRowData addObject:@{
            @"cellId" : OATextLineViewCell.getCellIdentifier,
            @"type" : kEnableDescrCell,
            @"title" : text
        }];
        NSLog([NSString stringWithFormat:@"%.1f", [OAUtilities calculateTextBounds:text width:width font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]].height]);
        _menuHeight += [OAUtilities calculateTextBounds:text width:width font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]].height + kTextLineCellFixedHeight;
    }
    
    _data = data;
    _menuHeight += OAUtilities.getBottomMargin + kBottomOffset;
}

- (nullable OAWeatherBand *)getWeatherBand
{
    switch (_layerType) {
        case EOAWeatherLayerTypeTemperature:
            return [OAWeatherBand withWeatherBand:WEATHER_BAND_TEMPERATURE];
        case EOAWeatherLayerTypePresssure:
            return [OAWeatherBand withWeatherBand:WEATHER_BAND_PRESSURE];
        case EOAWeatherLayerTypeWind:
            return [OAWeatherBand withWeatherBand:WEATHER_BAND_WIND_SPEED];
        case EOAWeatherLayerTypeCloud:
            return [OAWeatherBand withWeatherBand:WEATHER_BAND_CLOUD];
        case EOAWeatherLayerTypePrecipitation:
            return [OAWeatherBand withWeatherBand:WEATHER_BAND_PRECIPITATION];
        default:
            return nil;
    }
}

- (BOOL)isLayerEnabled
{
    if (_layerType == EOAWeatherLayerTypeContours)
    {
        NSString *contourName = _app.data.contourName;
        BOOL isEnabled = [_styleSettings isAnyWeatherContourLinesEnabled] || contourName.length > 0;
        if (contourName.length == 0)
        {
            if (isEnabled)
            {
                if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_TEMP_CONTOUR_LINES_ATTR])
                    contourName = WEATHER_TEMP_CONTOUR_LINES_ATTR;
                else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_PRESSURE_CONTOURS_LINES_ATTR])
                    contourName = WEATHER_PRESSURE_CONTOURS_LINES_ATTR;
                else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_CLOUD_CONTOURS_LINES_ATTR])
                    contourName = WEATHER_CLOUD_CONTOURS_LINES_ATTR;
                else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_WIND_CONTOURS_LINES_ATTR])
                    contourName = WEATHER_WIND_CONTOURS_LINES_ATTR;
                else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR])
                    contourName = WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR;
            }
            else
            {
                contourName = WEATHER_NONE_CONTOURS_LINES_VALUE;
            }
        }
        _selectedContoursParam = contourName;
        return isEnabled && _selectedContoursParam != WEATHER_NONE_CONTOURS_LINES_VALUE;
    }
    return _weatherBand.isBandVisible;
}

- (double)getLayerAlphaValue
{
    if (_layerType == EOAWeatherLayerTypeContours)
        return _app.data.contoursAlpha;
    return _weatherBand.getBandOpacity;
}

- (NSString *)getUnitsValue
{
    OAWeatherBand *band = _weatherBand;
    if (!band)
    {
        if ([_selectedContoursParam isEqualToString:WEATHER_TEMP_CONTOUR_LINES_ATTR])
            band = [OAWeatherBand withWeatherBand:WEATHER_BAND_TEMPERATURE];
        else if ([_selectedContoursParam isEqualToString:WEATHER_PRESSURE_CONTOURS_LINES_ATTR])
            band = [OAWeatherBand withWeatherBand:WEATHER_BAND_PRESSURE];
        else if ([_selectedContoursParam isEqualToString:WEATHER_CLOUD_CONTOURS_LINES_ATTR])
            band = [OAWeatherBand withWeatherBand:WEATHER_BAND_CLOUD];
        else if ([_selectedContoursParam isEqualToString:WEATHER_WIND_CONTOURS_LINES_ATTR])
            band = [OAWeatherBand withWeatherBand:WEATHER_BAND_WIND_SPEED];
        else if ([_selectedContoursParam isEqualToString:WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR])
            band = [OAWeatherBand withWeatherBand:WEATHER_BAND_PRECIPITATION];
    }
    NSMeasurementFormatter *formatter = [NSMeasurementFormatter new];
    formatter.locale = NSLocale.autoupdatingCurrentLocale;
    NSString *result = @"";
    if (band)
    {
        NSUnit *unit = [band getBandUnit];
        if (band.bandIndex == WEATHER_BAND_TEMPERATURE)
            result = unit.name != nil ? unit.name : [formatter displayStringFromUnit:unit];
        else
            result = [formatter displayStringFromUnit:unit];
    }

    return result;
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
        case EOAWeatherLayerTypeContours:
            return @"weather_contours";
    }
}

- (void)hide
{
    _backButtonPressed = YES;
    [self hide:YES duration:.2 onComplete:^{
        if (self.delegate)
            [self.delegate onDoneWeatherLayerSettings:YES];
    }];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [super hide:YES duration:duration onComplete:^{
        [_mapPanel hideScrollableHudViewController];
        if (onComplete)
            onComplete();
    }];
}

- (IBAction)backButtonPressed:(UIButton *)sender
{
    [self hide];
}

- (IBAction)doneButtonPressed:(UIButton *)sender
{
    [self hide:YES duration:.2 onComplete:^{
        if (self.delegate)
            [self.delegate onDoneWeatherLayerSettings:NO];
    }];
}

- (void)onWeatherSettingsChange:(id)observer withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *operation = (NSString *) key;
        if ([operation isEqualToString:kWeatherSettingsReset])
        {
            [_mapPanel.weatherToolbarStateChangeObservable notifyEvent];
            [_weatherSettingsChangeObserver detach];
            _weatherSettingsChangeObserver = nil;
        }
    });
}

- (void)onSwitchValueChanged:(UISwitch *)sender
{
    _layerEnabled = sender.isOn;
    if (_layerType == EOAWeatherLayerTypeTemperature)
        _app.data.weatherTemp = _layerEnabled;
    else if (_layerType == EOAWeatherLayerTypePresssure)
        _app.data.weatherPressure = _layerEnabled;
    else if (_layerType == EOAWeatherLayerTypeWind)
        _app.data.weatherWind = _layerEnabled;
    else if (_layerType == EOAWeatherLayerTypeCloud)
        _app.data.weatherCloud = _layerEnabled;
    else if (_layerType == EOAWeatherLayerTypePrecipitation)
        _app.data.weatherPrecip = _layerEnabled;
    else if (_layerType == EOAWeatherLayerTypeContours)
    {
        NSString *lastUsedParameterName;
        if (!_layerEnabled)
        {
            _selectedContoursParam = WEATHER_NONE_CONTOURS_LINES_VALUE;
            NSString *contourName = _app.data.contourName;

            if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_TEMP_CONTOUR_LINES_ATTR] || [contourName isEqualToString:WEATHER_TEMP_CONTOUR_LINES_ATTR])
                lastUsedParameterName = WEATHER_TEMP_CONTOUR_LINES_ATTR;
            else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_PRESSURE_CONTOURS_LINES_ATTR] || [contourName isEqualToString:WEATHER_PRESSURE_CONTOURS_LINES_ATTR])
                lastUsedParameterName = WEATHER_PRESSURE_CONTOURS_LINES_ATTR;
            else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_CLOUD_CONTOURS_LINES_ATTR] || [contourName isEqualToString:WEATHER_CLOUD_CONTOURS_LINES_ATTR])
                lastUsedParameterName = WEATHER_CLOUD_CONTOURS_LINES_ATTR;
            else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_WIND_CONTOURS_LINES_ATTR] || [contourName isEqualToString:WEATHER_WIND_CONTOURS_LINES_ATTR])
                lastUsedParameterName = WEATHER_WIND_CONTOURS_LINES_ATTR;
            else if ([_styleSettings isWeatherContourLinesEnabled:WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR] || [contourName isEqualToString:WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR])
                lastUsedParameterName = WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR;

            _app.data.contourName = @"";
            _app.data.contourNameLastUsed = lastUsedParameterName;
            [_styleSettings setWeatherContourLinesEnabled:NO
                                    weatherContourLinesAttr:lastUsedParameterName];
        }
        else
        {
            lastUsedParameterName = _app.data.contourNameLastUsed;
            if (lastUsedParameterName.length == 0)
                lastUsedParameterName = WEATHER_TEMP_CONTOUR_LINES_ATTR;
            _app.data.contourName = lastUsedParameterName;
            _selectedContoursParam = lastUsedParameterName;
            [_styleSettings setWeatherContourLinesEnabled:YES
                                  weatherContourLinesAttr:lastUsedParameterName];
        }
    }

    [self generateData];
    [UIView transitionWithView:self.tableView duration:.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [self.tableView reloadData];
        [self goMinimized:NO];
    } completion:nil];
}

- (void)onSliderValueChanged:(UISlider *)sender
{
    if (_layerType == EOAWeatherLayerTypeTemperature)
        _app.data.weatherTempAlpha = sender.value;
    else if (_layerType == EOAWeatherLayerTypePresssure)
        _app.data.weatherPressureAlpha = sender.value;
    else if (_layerType == EOAWeatherLayerTypeWind)
        _app.data.weatherWindAlpha = sender.value;
    else if (_layerType == EOAWeatherLayerTypeCloud)
        _app.data.weatherCloudAlpha = sender.value;
    else if (_layerType == EOAWeatherLayerTypePrecipitation)
        _app.data.weatherPrecipAlpha = sender.value;
    else if (_layerType == EOAWeatherLayerTypeContours)
        _app.data.contoursAlpha = sender.value;
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
    if (section == 0)
        return CGFLOAT_MIN;
    
    return _data[section][@"sectionTitle"] ? kNonEmptyHeaderHeight : kEmptyHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGFLOAT_MIN;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _data[section][@"sectionTitle"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][@"rows"][indexPath.row];
    if ([item[@"cellId"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        return _dividerHeight;
    }
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][@"rows"][indexPath.row];
    NSString *cellId = item[@"cellId"];
    if ([cellId isEqualToString:OASwitchTableViewCell.getCellIdentifier])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.separatorInset = UIEdgeInsetsMake(0., 0., 0., 0.);
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"image"]];
            cell.leftIconView.tintColor = _layerEnabled ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];

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
            cell.textView.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
        }
        return cell;
    }
    else if ([cellId isEqualToString:OAValueTableViewCell.getCellIdentifier])
    {
        OAValueTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        BOOL isUnitsCell = [item[@"type"] isEqualToString:kUnitsCell];
        BOOL isSelected = [_selectedContoursParam isEqualToString:item[@"contoursType"]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = isUnitsCell ? [self getUnitsValue] : nil;
            [cell valueVisibility:isUnitsCell];
            if (isUnitsCell)
            {
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else
            {
                if (isSelected)
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                else
                    cell.accessoryType = UITableViewCellAccessoryNone;
            }
            cell.accessoryView.tintColor = isUnitsCell ? [UIColor colorNamed:ACColorNameIconColorDefault]: [UIColor colorNamed:ACColorNameIconColorActive];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"image"]];
            cell.leftIconView.tintColor = isSelected ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];
            [cell leftIconVisibility:!isUnitsCell];
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
            cell.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = [NSString stringWithFormat:@"%.0f%%", [item[@"value"] doubleValue] * 100];
            [cell.sliderView setValue:[item[@"value"] floatValue]];
            [cell.sliderView addTarget:self action:@selector(onSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellId isEqualToString:OADividerCell.getCellIdentifier])
    {
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
        }
        cell.dividerColor = [UIColor colorNamed:ACColorNameCustomSeparator];
        CGFloat leftInset = [item[@"inset"] floatValue];
        cell.dividerInsets = UIEdgeInsetsMake(0., leftInset, 0., 0.);
        cell.dividerHight = _dividerHeight;
        return cell;
    }
    return nil;
}

// MARK: UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][@"rows"][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kUnitsCell])
    {
        OAWeatherBand *band = _weatherBand;
        if (!band)
        {
            EOAWeatherBand bandIndex;
            if ([_selectedContoursParam isEqualToString:WEATHER_TEMP_CONTOUR_LINES_ATTR])
                bandIndex = WEATHER_BAND_TEMPERATURE;
            else if ([_selectedContoursParam isEqualToString:WEATHER_PRESSURE_CONTOURS_LINES_ATTR])
                bandIndex = WEATHER_BAND_PRESSURE;
            else if ([_selectedContoursParam isEqualToString:WEATHER_CLOUD_CONTOURS_LINES_ATTR])
                bandIndex = WEATHER_BAND_CLOUD;
            else if ([_selectedContoursParam isEqualToString:WEATHER_WIND_CONTOURS_LINES_ATTR])
                bandIndex = WEATHER_BAND_WIND_SPEED;
            else if ([_selectedContoursParam isEqualToString:WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR])
                bandIndex = WEATHER_BAND_PRECIPITATION;
            else
                bandIndex = WEATHER_BAND_TEMPERATURE;

            band = [OAWeatherBand withWeatherBand:bandIndex];
        }
        OAWeatherBandSettingsViewController *controller =
        [[OAWeatherBandSettingsViewController alloc] initWithWeatherBand:band];
        controller.bandDelegate = self;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
        
    }
    else if ([cellType isEqualToString:kContoursTypeCell])
    {
        NSString *contoursType = item[@"contoursType"];
        _selectedContoursParam = contoursType;
        _app.data.contourName = contoursType;
        _app.data.contourNameLastUsed = contoursType;
        [_styleSettings setWeatherContourLinesEnabled:YES weatherContourLinesAttr:contoursType];

        [self generateData];
        NSIndexSet *sectionsToReload = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(kContoursTypesSection, tableView.numberOfSections - 1)];
        [tableView reloadSections:sectionsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// MARK: OAWeatherBandSettingsDelegate

- (void)onBandUnitChanged
{
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:_unitsSection] withRowAnimation:UITableViewRowAnimationNone];
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

- (void)doAdditionalLayout
{
    BOOL isRTL = [self.backButtonContainerView isDirectionRTL];
    self.backButtonLeadingConstraint.constant = [self isLandscape]
            ? (isRTL ? 0. : [self getLandscapeViewWidth] - [OAUtilities getLeftMargin] + 10.)
            : [OAUtilities getLeftMargin] + 10.;
}

@end
