//
//  OAWeatherToolbar.mm
//  OsmAnd
//
//  Created by Skalii on 03.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherToolbar.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OAWeatherLayerSettingsViewController.h"
#import "OASegmentedSlider.h"
#import "OAMapStyleSettings.h"
#import "OAMapLayers.h"
#import "OAColors.h"
#import "Localization.h"

#define kTempIndex 0
#define kPressureIndex 1
#define kWindIndex 2
#define kCloudIndex 3
#define kPrecipitationIndex 4
#define kContoursIndex 5

@implementation OAWeatherToolbarLayersDelegate
{
    OAMapStyleSettings *_styleSettings;
    OsmAndAppInstance _app;

    NSMutableArray<NSMutableDictionary *> *_data;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _styleSettings = [OAMapStyleSettings sharedInstance];
        _app = [OsmAndApp instance];
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    [self updateData];
}

- (void)updateData
{
    NSMutableArray<NSMutableDictionary *> *layersData = [NSMutableArray array];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
            @"img": @"ic_custom_thermometer",
            @"selected": @(_app.data.weatherTemp)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
            @"img": @"ic_custom_air_pressure",
            @"selected": @(_app.data.weatherPressure)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
            @"img": @"ic_custom_wind",
            @"selected": @(_app.data.weatherWind)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
            @"img": @"ic_custom_clouds",
            @"selected": @(_app.data.weatherCloud)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
            @"img": @"ic_custom_precipitation",
            @"selected": @(_app.data.weatherPrecip)
    }]];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
            @"img": @"ic_custom_contour_lines",
            @"selected": @([[_styleSettings getParameter:WEATHER_TEMP_CONTOUR_LINES_ATTR].value isEqualToString:@"true"]
                    || [[_styleSettings getParameter:WEATHER_PRESSURE_CONTOURS_LINES_ATTR].value isEqualToString:@"true"])
    }]];

    _data = layersData;
}

- (NSArray *)getData
{
    return _data;
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index
{
    if (index == kTempIndex)
    {
        BOOL selected = !_app.data.weatherTemp;
        _data[kTempIndex][@"selected"] = @(selected);
        _app.data.weatherTemp = selected;
    }
    else if (index == kPressureIndex)
    {
        BOOL selected = !_app.data.weatherPressure;
        _data[kPressureIndex][@"selected"] = @(selected);
        _app.data.weatherPressure = selected;
    }
    else if (index == kWindIndex)
    {
        BOOL selected = !_app.data.weatherWind;
        _data[kWindIndex][@"selected"] = @(selected);
        _app.data.weatherWind = selected;
    }
    else if (index == kCloudIndex)
    {
        BOOL selected = !_app.data.weatherCloud;
        _data[kCloudIndex][@"selected"] = @(selected);
        _app.data.weatherCloud = selected;
    }
    else if (index == kPrecipitationIndex)
    {
        BOOL selected = !_app.data.weatherPrecip;
        _data[kPrecipitationIndex][@"selected"] = @(selected);
        _app.data.weatherPrecip = selected;
    }
    else if (index == kContoursIndex)
    {
        BOOL selected = !([[_styleSettings getParameter:WEATHER_TEMP_CONTOUR_LINES_ATTR].value isEqualToString:@"true"]
                || [[_styleSettings getParameter:WEATHER_PRESSURE_CONTOURS_LINES_ATTR].value isEqualToString:@"true"]);
        _data[kContoursIndex][@"selected"] = @(selected);
        [OAMapStyleSettings weatherContoursParamChangedToValue:selected ? WEATHER_TEMP_CONTOUR_LINES_ATTR : WEATHER_NONE_CONTOURS_LINES_VALUE
                                                 styleSettings:_styleSettings];
    }

    if (self.delegate)
        [self.delegate updateData:_data type:EOAWeatherToolbarLayers];
}

@end

@implementation OAWeatherToolbarDatesDelegate
{
    NSMutableArray<NSMutableDictionary *> *_data;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    [self updateData];
}

- (void)updateData
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd.MM"];

    NSMutableArray<NSMutableDictionary *> *layersData = [NSMutableArray array];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
            @"title": OALocalizedString(@"today"),
            @"value": [OARootViewController instance].mapPanel.mapViewController.mapLayers.weatherDate
    }]];
    NSDate *date = NSDate.date;
    for (NSInteger i = 1; i <= 6; i++)
    {
        date = [date dateByAddingTimeInterval:60L * 60L * 24L];
        [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
                @"title": [formatter stringFromDate:date],
                @"value": date
        }]];
    }

    _data = layersData;
}

- (NSArray *)getData
{
    return _data;
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index
{
    [[OARootViewController instance].mapPanel.mapViewController.mapLayers updateWeatherDate:_data[index][@"value"]];

    if (self.delegate)
        [self.delegate updateData:@[@(index)] type:EOAWeatherToolbarDates];
}

@end

@interface OAWeatherToolbar () <OAWeatherToolbarDelegate, OAWeatherLayerSettingsDelegate>

@property (weak, nonatomic) IBOutlet OAFoldersCollectionView *layersCollectionView;
@property (weak, nonatomic) IBOutlet OAFoldersCollectionView *dateCollectionView;
@property (weak, nonatomic) IBOutlet OASegmentedSlider *timeSliderView;

@end

@implementation OAWeatherToolbar
{
    OsmAndAppInstance _app;
    OAMapStyleSettings *_styleSettings;
    OAWeatherToolbarLayersDelegate *_layersDelegate;
    OAWeatherToolbarDatesDelegate *_datesDelegate;
}

- (instancetype)init
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAWeatherToolbar" owner:self options:nil];
    self = (OAWeatherToolbar *) nib[0];
    if (self)
        self.frame = CGRectMake(0, 0, DeviceScreenWidth, 150);

    [self commonInit];
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAWeatherToolbar" owner:self options:nil];
    self = (OAWeatherToolbar *) nib[0];
    if (self)
        self.frame = frame;

    [self commonInit];
    return self;
}

- (void)commonInit
{
    [self updateInfo];

    _app = [OsmAndApp instance];
    _styleSettings = [OAMapStyleSettings sharedInstance];

    _layersDelegate = [[OAWeatherToolbarLayersDelegate alloc] init];
    _layersDelegate.delegate = self;
    self.layersCollectionView.foldersDelegate = _layersDelegate;
    [self updateData:[_layersDelegate getData] type:EOAWeatherToolbarLayers];

    UILongPressGestureRecognizer *longPressOnLayerRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                             action:@selector(handleLongPressOnLayer:)];
    [self.layersCollectionView addGestureRecognizer:longPressOnLayerRecognizer];

    _datesDelegate = [[OAWeatherToolbarDatesDelegate alloc] init];
    _datesDelegate.delegate = self;
    self.dateCollectionView.foldersDelegate = _datesDelegate;
    [self updateData:[_datesDelegate getData] type:EOAWeatherToolbarDates];

    NSInteger selectedIndex = 0;
    NSDate *selectedDate = [OARootViewController instance].mapPanel.mapViewController.mapLayers.weatherDate;
    if (![NSCalendar.currentCalendar isDateInToday:selectedDate])
    {
        NSCalendar *calendar = NSCalendar.currentCalendar;
        NSDate *date1 = [calendar startOfDayForDate:NSDate.date];
        NSDate *date2 = [calendar startOfDayForDate:selectedDate];
        NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:date1 toDate:date2 options:0];
        selectedIndex = components.day;
    }
    [self updateData:@[@(selectedIndex)] type:EOAWeatherToolbarDates];

    [self.timeSliderView makeCustom:UIColorFromRGB(color_slider_minimum)
        customMaximumTrackTintColor:UIColorFromRGB(color_tint_gray)
             customCurrentMarkColor:UIColorFromRGB(color_primary_purple)];
    [self.timeSliderView setCurrentMark:8];
    [self.timeSliderView setNumberOfMarks:9
                   additionalMarksBetween:2];
    self.timeSliderView.selectedMark = 0;
}

- (void)handleLongPressOnLayer:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint point = [gestureRecognizer locationInView:self.layersCollectionView];
        NSIndexPath *indexPath = [self.layersCollectionView indexPathForItemAtPoint:point];
        if (indexPath)
        {
            OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
            [mapPanel.hudViewController changeWeatherToolbarVisible];

            OAWeatherLayerSettingsViewController *weatherLayerSettingsViewController =
                    [[OAWeatherLayerSettingsViewController alloc] initWithLayerType:(EOAWeatherLayerType) indexPath.row];
            weatherLayerSettingsViewController.delegate = self;
            [mapPanel showScrollableHudViewController:weatherLayerSettingsViewController];
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self setupShadow];

    self.layer.cornerRadius = 9.;
    self.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
}

- (void)setupShadow
{
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = .2;
    self.layer.shadowRadius = 5.;
    self.layer.shadowOffset = CGSizeMake(0., -1.);
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:self.layer.bounds];
    self.layer.shadowPath = shadowPath.CGPath;
}

- (BOOL)updateInfo
{
    BOOL visible = [[OARootViewController instance].mapPanel.hudViewController shouldShowWeatherToolbar];
    [self updateVisibility:visible];
    return YES;
}

- (BOOL)updateVisibility:(BOOL)visible
{
    if (visible == self.hidden)
    {
        if (self.delegate)
            [self.delegate widgetVisibilityChanged:self visible:!visible];

        return YES;
    }
    return NO;
}

#pragma mark - OAWeatherToolbarDelegate

- (void)updateData:(NSArray *)data type:(EOAWeatherToolbarDelegateType)type
{
    if (type == EOAWeatherToolbarLayers)
    {
        [self.layersCollectionView setValues:data withSelectedIndex:-1];
        [self.layersCollectionView reloadData];
    }
    else if (type == EOAWeatherToolbarDates)
    {
        if (data.count == 1 && [data.firstObject isKindOfClass:NSNumber.class])
            [self.dateCollectionView setSelectedIndex:[data.firstObject integerValue]];
        else
            [self.dateCollectionView setValues:data withSelectedIndex:0];

        [self.dateCollectionView reloadData];
    }
}

#pragma mark - OAWeatherLayerSettingsDelegate

- (void)onHideWeatherLayerSettings
{
    [self onDoneWeatherLayerSettings];
    [[OARootViewController instance].mapPanel.hudViewController changeWeatherToolbarVisible];
}

- (void)onDoneWeatherLayerSettings
{
    [_layersDelegate updateData];
    [self.layersCollectionView setValues:[_layersDelegate getData] withSelectedIndex:-1];
    [self.layersCollectionView reloadData];
}

@end
