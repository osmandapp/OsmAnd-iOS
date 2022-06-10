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
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _styleSettings = [OAMapStyleSettings sharedInstance];
    _app = [OsmAndApp instance];

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

- (void)askForPaidProduct:(NSString *)productIdentifier
{
}

@end

@implementation OAWeatherToolbarDatesDelegate
{
    NSMutableArray<NSMutableDictionary *> *_data;
}

- (instancetype)initWithAvailable:(BOOL)available date:(NSDate *)date
{
    self = [super init];
    if (self)
    {
        [self commonInit:available date:date];
    }
    return self;
}

- (void)commonInit:(BOOL)available date:(NSDate *)date
{
    [self updateData:available date:date];
}

- (void)updateData:(BOOL)available date:(NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd.MM"];

    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    date = [calendar dateBySettingHour:0 minute:0 second:0 ofDate:date options:0];

    NSMutableArray<NSMutableDictionary *> *layersData = [NSMutableArray array];
    [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
            @"title": OALocalizedString(@"today"),
            @"available": @(available),
            @"value": date
    }]];
    for (NSInteger i = 1; i <= 6; i++)
    {
        date = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0];
        [layersData addObject:[NSMutableDictionary dictionaryWithDictionary:@{
                @"title": [formatter stringFromDate:date],
                @"available": @(available),
                @"value": date
        }]];
    }

    _data = layersData;
}

- (NSArray<NSMutableDictionary *> *)getData
{
    return _data;
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index
{
    if (self.delegate)
        [self.delegate updateData:_data type:EOAWeatherToolbarDates];
}

- (void)askForPaidProduct:(NSString *)productIdentifier
{
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
    NSCalendar *_calendar;
    OAWeatherToolbarLayersDelegate *_layersDelegate;
    OAWeatherToolbarDatesDelegate *_datesDelegate;

    BOOL _available;
    NSInteger _selectedDateIndex;
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
    _calendar = NSCalendar.autoupdatingCurrentCalendar;
    _calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];

    _layersDelegate = [[OAWeatherToolbarLayersDelegate alloc] init];
    _layersDelegate.delegate = self;
    self.layersCollectionView.foldersDelegate = _layersDelegate;
    [self updateData:[_layersDelegate getData] type:EOAWeatherToolbarLayers];

    UILongPressGestureRecognizer *longPressOnLayerRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                             action:@selector(handleLongPressOnLayer:)];
    [self.layersCollectionView addGestureRecognizer:longPressOnLayerRecognizer];

    NSDate *currentDate = [OAUtilities getCurrentDate];
    _datesDelegate = [[OAWeatherToolbarDatesDelegate alloc] initWithAvailable:_available date:currentDate];
    _datesDelegate.delegate = self;
    self.dateCollectionView.foldersDelegate = _datesDelegate;
    [self updateData:[_datesDelegate getData] type:EOAWeatherToolbarDates];
    [self setCurrentMark:currentDate];
    self.timeSliderView.userInteractionEnabled = _available;
    [self.timeSliderView setNumberOfMarks:9 additionalMarksBetween:2];
    self.timeSliderView.selectedMark = [self getSelectedTimeIndex:[self getSelectedDate]];

    [self.timeSliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.timeSliderView addTarget:self action:@selector(timeChanged:) forControlEvents:UIControlEventTouchUpInside];
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

- (void) awakeFromNib
{
    [super awakeFromNib];

    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = .2;
    self.layer.shadowRadius = 5.;
    self.layer.shadowOffset = CGSizeMake(0., -1.);
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.frame cornerRadius:9];
    self.layer.shadowPath = shadowPath.CGPath;

    self.layer.cornerRadius = 9.;
    self.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
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

- (NSInteger)getSelectedTimeIndex:(NSDate *)date
{
    NSInteger selectedIndex = 0;
    if (_available)
        selectedIndex = [_calendar components:NSCalendarUnitHour fromDate:date].hour;
    return selectedIndex;
}

- (NSDate *)getSelectedDate
{
    return [OARootViewController instance].mapPanel.mapViewController.mapLayers.weatherDate;
}

- (void)setCurrentMark:(NSDate *)date
{
    NSInteger minimumForCurrentMark = [_calendar startOfDayForDate:date].timeIntervalSince1970;
    NSInteger currentValue = date.timeIntervalSince1970;
    self.timeSliderView.currentMarkX = _available && _selectedDateIndex == 0 ? (currentValue - minimumForCurrentMark) : -1;
    date = [_calendar dateBySettingHour:0 minute:0 second:0 ofDate:date options:0];
    date = [_calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0];
    self.timeSliderView.maximumForCurrentMark = [_calendar startOfDayForDate:date].timeIntervalSince1970 - minimumForCurrentMark;
}

#pragma mark - UISlider

- (void)timeChanged:(UISlider *)sender
{
    if (sender)
    {
        NSInteger index = self.timeSliderView.selectedMark;
        if (_selectedDateIndex > 0)
            index *= 3;

        NSDate *date = [OAUtilities getCurrentDate];
        NSDateComponents *components = [_calendar components:NSCalendarUnitDay fromDate:date];
        NSInteger currentDay = components.day;
        date = [_calendar dateBySettingUnit:NSCalendarUnitDay value:currentDay + _selectedDateIndex ofDate:date options:0];

        if (index >= 24)
        {
            date = [_calendar dateBySettingHour:0 minute:0 second:0 ofDate:date options:0];
            date = [_calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0];
        }
        else
        {
            date = [_calendar dateBySettingHour:index minute:0 second:0 ofDate:date options:0];
        }

        [[OARootViewController instance].mapPanel.mapViewController.mapLayers updateWeatherDate:date];
    }
}

#pragma mark - OAWeatherToolbarDelegate

- (void)updateData:(NSArray *)data type:(EOAWeatherToolbarDelegateType)type
{
    if (type == EOAWeatherToolbarLayers)
    {
        [self.layersCollectionView setValues:data withSelectedIndex:-1];
        [self.layersCollectionView reloadData];

        BOOL available = NO;
        for (NSDictionary *item in data)
        {
            if ([item[@"selected"] boolValue])
            {
                available = YES;
                break;
            }
        }
        if (available != _available)
        {
            _available = available;
            NSDate *currentDate = [OAUtilities getCurrentDate];
            [self setCurrentMark:currentDate];
            self.timeSliderView.selectedMark = [self getSelectedTimeIndex:[self getSelectedDate]];
            self.timeSliderView.userInteractionEnabled = _available;
            if (_datesDelegate)
            {
                [_datesDelegate updateData:_available date:[OAUtilities getCurrentDate]];
                [self updateData:[_datesDelegate getData] type:EOAWeatherToolbarDates];
            }
        }
    }
    else if (type == EOAWeatherToolbarDates)
    {
        NSInteger selectedDateIndex = _available ? [self.dateCollectionView getSelectedIndex] : 0;
        if (selectedDateIndex == -1)
            selectedDateIndex = 0;

        NSDate *date = data[selectedDateIndex][@"value"];
        NSDate *selectedDate = [self getSelectedDate];
        date = [_calendar dateBySettingHour:[_calendar components:NSCalendarUnitHour fromDate:selectedDate].hour
                                    minute:[_calendar components:NSCalendarUnitMinute fromDate:selectedDate].minute
                                    second:[_calendar components:NSCalendarUnitSecond fromDate:selectedDate].second
                                    ofDate:date
                                   options:0];
        [[OARootViewController instance].mapPanel.mapViewController.mapLayers updateWeatherDate:date];

        if (_available && selectedDateIndex != _selectedDateIndex)
            _selectedDateIndex = selectedDateIndex;

        NSDate *currentDate = [OAUtilities getCurrentDate];
        [self setCurrentMark:currentDate];
        [self.timeSliderView setNumberOfMarks:9 additionalMarksBetween:selectedDateIndex > 0 ? 0 : 2];
        [self.dateCollectionView setValues:data withSelectedIndex:_available ? _selectedDateIndex : -1];
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
    [self updateData:[_layersDelegate getData] type:EOAWeatherToolbarLayers];
    [self.layersCollectionView setValues:[_layersDelegate getData] withSelectedIndex:-1];
    [self.layersCollectionView reloadData];
}

@end
