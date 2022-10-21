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
#import "OASizes.h"
#import "OAMapLayers.h"
#import "OAWeatherToolbarHandlers.h"
#import "OAWeatherHelper.h"

@interface OAWeatherToolbar () <OAWeatherToolbarDelegate, OAWeatherLayerSettingsDelegate>

@property (weak, nonatomic) IBOutlet OAFoldersCollectionView *layersCollectionView;
@property (weak, nonatomic) IBOutlet OAFoldersCollectionView *dateCollectionView;
@property (weak, nonatomic) IBOutlet OASegmentedSlider *timeSliderView;

@end

@implementation OAWeatherToolbar
{
    OsmAndAppInstance _app;
    NSMutableArray<OAAutoObserverProxy *> *_layerChangeObservers;
    OAAutoObserverProxy* _weatherChangeObserver;

    NSCalendar *_currentTimezoneCalendar;
    OAWeatherToolbarLayersHandler *_layersHandler;
    OAWeatherToolbarDatesHandler *_datesHandler;
    NSArray<NSDate *> *_timeInGMTTimezoneValues;

    BOOL _available;
    NSInteger _selectedDayIndex;
    NSInteger _previousSelectedDayIndex;
    NSInteger _previousSelectedMarkIndex;
}

- (instancetype)init
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAWeatherToolbar" owner:self options:nil];
    self = (OAWeatherToolbar *) nib[0];
    if (self)
        self.frame = CGRectMake(
                [OAUtilities isLandscape] ? [OAUtilities isIPad] ? -kInfoViewLandscapeWidthPad : -(DeviceScreenWidth * .45) : 0.,
                [self.class calculateYOutScreen],
                [OAUtilities isLandscape] ? [OAUtilities isIPad] ? kInfoViewLandscapeWidthPad : DeviceScreenWidth * .45 : DeviceScreenWidth,
                [OAUtilities isLandscape] ? [OAUtilities isIPad] ? DeviceScreenHeight - [OAUtilities getStatusBarHeight] : DeviceScreenHeight : 205. + [OAUtilities getBottomMargin]
        );

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
    self.hidden = YES;
    _app = [OsmAndApp instance];
    _currentTimezoneCalendar = NSCalendar.autoupdatingCurrentCalendar;
    _currentTimezoneCalendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    _previousSelectedDayIndex = -1;
    _previousSelectedMarkIndex = -1;

    _layersHandler = [[OAWeatherToolbarLayersHandler alloc] init];
    _layersHandler.delegate = self;

    [self.layersCollectionView setOnlyIconCompact:YES];
    self.layersCollectionView.foldersDelegate = _layersHandler;
    [self updateData:[_layersHandler getData] type:EOAWeatherToolbarLayers];

    UILongPressGestureRecognizer *longPressOnLayerRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                             action:@selector(handleLongPressOnLayer:)];
    [self.layersCollectionView addGestureRecognizer:longPressOnLayerRecognizer];

    _datesHandler = [[OAWeatherToolbarDatesHandler alloc] initWithAvailable:_available date:[NSDate date]];
    _datesHandler.delegate = self;
    self.dateCollectionView.foldersDelegate = _datesHandler;
    [self updateData:[_datesHandler getData] type:EOAWeatherToolbarDates];
    [self setCurrentMark:[OAUtilities getCurrentTimezoneDate:[NSDate date]]];
    self.timeSliderView.userInteractionEnabled = _available;
    [self.timeSliderView setNumberOfMarks:9 additionalMarksBetween:2];
    NSDate *selectedDate = [OAUtilities getCurrentTimezoneDate:[self getSelectedGMTDate]];
    self.timeSliderView.selectedMark = [self getSelectedTimeIndex:selectedDate];

    [self updateTimeValues:[_datesHandler getData][_selectedDayIndex][@"value"]];

    [self.timeSliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.timeSliderView addTarget:self action:@selector(timeChanged:) forControlEvents:UIControlEventTouchUpInside];

    _weatherChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onUpdateWeatherLayerSettings)
                                                        andObserve:_app.data.weatherChangeObservable];
    _layerChangeObservers = [NSMutableArray array];
    for (OAWeatherBand *band in [[OAWeatherHelper sharedInstance] bands])
    {
        [_layerChangeObservers addObject:[band createSwitchObserver:self handler:@selector(onUpdateWeatherLayerSettings)]];
    }
    [self updateInfo];
}

- (void)dealloc
{
    for (OAAutoObserverProxy *observer in _layerChangeObservers)
        [observer detach];

    _layerChangeObservers = nil;
}

- (void)onUpdateWeatherLayerSettings
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_layersHandler updateData];
        [self updateData:[_layersHandler getData] type:EOAWeatherToolbarLayers];
        [self.layersCollectionView setValues:[_layersHandler getData] withSelectedIndex:-1];
        [self reloadLayersCollectionView];
    });
}

- (void)handleLongPressOnLayer:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
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
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = .2;
    self.layer.shadowRadius = 5.;
    self.layer.shadowOffset = CGSizeMake(0., -1.);
    self.layer.masksToBounds = NO;
    
    self.layer.cornerRadius = 9.;
    self.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
}

- (BOOL)updateInfo
{
    OAMapHudViewController *hudViewController = [OARootViewController instance].mapPanel.hudViewController;
    BOOL visible =  [hudViewController shouldShowWeatherToolbar];
    [self updateVisibility:visible];
    [hudViewController.weatherButton setImage:[UIImage templateImageNamed:visible ? @"ic_custom_cancel" : @"ic_custom_umbrella"]
                                     forState:UIControlStateNormal];
    return YES;
}

- (BOOL)updateVisibility:(BOOL)visible
{
    if (visible == self.hidden)
    {
        if (visible && [OAUtilities isLandscape])
            self.topControlsVisibleInLandscape = [[OARootViewController instance].mapPanel isTopControlsVisible];

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
        selectedIndex = [_currentTimezoneCalendar components:NSCalendarUnitHour fromDate:date].hour;
    return selectedIndex;
}

- (NSDate *)getSelectedGMTDate
{
    return [OARootViewController instance].mapPanel.mapViewController.mapLayers.weatherDate;
}

- (void)setCurrentMark:(NSDate *)date
{
    NSInteger minimumForCurrentMark = [_currentTimezoneCalendar startOfDayForDate:date].timeIntervalSince1970;
    NSInteger currentValue = date.timeIntervalSince1970;
    self.timeSliderView.currentMarkX = _available && _selectedDayIndex == 0 ? (currentValue - minimumForCurrentMark) : -1;
    date = [_currentTimezoneCalendar startOfDayForDate:date];
    date = [_currentTimezoneCalendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0];
    self.timeSliderView.maximumForCurrentMark = [_currentTimezoneCalendar startOfDayForDate:date].timeIntervalSince1970 - minimumForCurrentMark;
}

- (void)updateTimeValues:(NSDate *)date
{
    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    calendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSDate *selectedNextDate = [calendar startOfDayForDate:date];
    NSMutableArray<NSDate *> *selectedTimeValues = [NSMutableArray array];
    [selectedTimeValues addObject:selectedNextDate];

    NSInteger count = _selectedDayIndex == 0 ? 9 + (9 - 1) * 2 : 9;
    for (NSInteger i = 0; i < count - 1; i++)
    {
        selectedNextDate = [calendar dateByAddingUnit:NSCalendarUnitHour
                                                value:_selectedDayIndex == 0 ? 1 : 3
                                               toDate:selectedNextDate
                                              options:0];
        [selectedTimeValues addObject:selectedNextDate];
    }

    _timeInGMTTimezoneValues = selectedTimeValues;
}

- (void)reloadLayersCollectionView
{
    [self.layersCollectionView reloadData];
}

- (void)moveToScreen
{
    CGRect frame = self.frame;
    CGFloat y = [self.class calculateY];
    if ([OAUtilities isIPad])
    {
        if ([OAUtilities isLandscape])
        {
            frame.size.width = kInfoViewLandscapeWidthPad;
            frame.size.height = DeviceScreenHeight - [OAUtilities getStatusBarHeight];
            frame.origin = CGPointMake(0., y);
        }
        else
        {
            frame.size.width = DeviceScreenWidth;
            frame.size.height = 205. + [OAUtilities getBottomMargin];
            frame.origin = CGPointMake(0., y);
        }
    }
    else
    {
        if ([OAUtilities isLandscape])
        {
            frame.size.width = DeviceScreenWidth * 0.45;
            frame.size.height = DeviceScreenHeight;
            frame.origin = CGPointZero;
        }
        else
        {
            frame.size.width = DeviceScreenWidth;
            frame.size.height = 205. + [OAUtilities getBottomMargin];
            frame.origin = CGPointMake(0., y);
        }
    }
    self.frame = frame;
}

- (void)moveOutOfScreen
{
    CGRect frame = self.frame;
    CGFloat y = [self.class calculateYOutScreen];
    if ([OAUtilities isIPad])
    {
        if ([OAUtilities isLandscape])
        {
            frame.size.width = kInfoViewLandscapeWidthPad;
            frame.size.height = DeviceScreenHeight - [OAUtilities getStatusBarHeight];
            frame.origin = CGPointMake(-frame.size.width, y);
        }
        else
        {
            frame.size.width = DeviceScreenWidth;
            frame.size.height = 205. + [OAUtilities getBottomMargin];
            frame.origin = CGPointMake(0., y);
        }
    }
    else
    {
        if ([OAUtilities isLandscape])
        {
            frame.size.width = DeviceScreenWidth * .45;
            frame.size.height = DeviceScreenHeight;
            frame.origin = CGPointMake(-frame.size.width, y);
        }
        else
        {
            frame.size.width = DeviceScreenWidth;
            frame.size.height = 205. + [OAUtilities getBottomMargin];
            frame.origin = CGPointMake(0., y);
        }
    }
    self.frame = frame;
}

+ (CGFloat)calculateY
{
    if ([OAUtilities isLandscape])
        return [OAUtilities isIPad] ? [OAUtilities getStatusBarHeight] : 0.;

    return DeviceScreenHeight - (205. + [OAUtilities getBottomMargin]);
}

+ (CGFloat)calculateYOutScreen
{
    if ([OAUtilities isLandscape])
        return [OAUtilities isIPad] ? [OAUtilities getStatusBarHeight] -1 : -1.;

    return DeviceScreenHeight + 205. + [OAUtilities getBottomMargin];
}

#pragma mark - UISlider

- (void)timeChanged:(UISlider *)sender
{
    NSInteger index = self.timeSliderView.selectedMark;
    [[OARootViewController instance].mapPanel.mapViewController.mapLayers updateWeatherDate:_timeInGMTTimezoneValues[index]];
}

#pragma mark - OAWeatherToolbarDelegate

- (void)updateData:(NSArray *)data type:(EOAWeatherToolbarDelegateType)type
{
    if (type == EOAWeatherToolbarLayers)
    {
        [self.layersCollectionView setValues:data withSelectedIndex:-1];
        [self reloadLayersCollectionView];

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
            NSDate *currentDate = [OAUtilities getCurrentTimezoneDate:[NSDate date]];
            [self setCurrentMark:currentDate];
            NSDate *selectedDate = [OAUtilities getCurrentTimezoneDate:[self getSelectedGMTDate]];
            
            if (!_available)
            {
                _previousSelectedDayIndex = _selectedDayIndex;
                _previousSelectedMarkIndex = self.timeSliderView.selectedMark;
            }

            self.timeSliderView.selectedMark = [self getSelectedTimeIndex:selectedDate];
            self.timeSliderView.userInteractionEnabled = _available;
            if (_datesHandler)
            {
                [_datesHandler updateData:_available date:currentDate];
                [self updateData:[_datesHandler getData] type:EOAWeatherToolbarDates];
            }
        }
    }
    else if (type == EOAWeatherToolbarDates)
    {
        BOOL needToUpdate = YES;
        NSInteger selectedDayIndex = _available ? [self.dateCollectionView getSelectedIndex] : 0;
        if (selectedDayIndex == -1)
        {
            selectedDayIndex = 0;
            needToUpdate = NO;
        }

        if (_available && (selectedDayIndex != _selectedDayIndex || _previousSelectedDayIndex != -1))
        {
            if (_previousSelectedDayIndex != -1)
                selectedDayIndex = _previousSelectedDayIndex;

            [self.timeSliderView setNumberOfMarks:9 additionalMarksBetween:selectedDayIndex > 0 ? 0 : 2];

            if (needToUpdate && ((_selectedDayIndex == 0 && selectedDayIndex > 0) || (selectedDayIndex == 0 && _selectedDayIndex > 0)))
            {
                NSInteger index = self.timeSliderView.selectedMark;
                index = _timeInGMTTimezoneValues.count > 9 ? (NSInteger) round(index / 3) : index * 3;
                self.timeSliderView.selectedMark = index;
            }
            else if (_previousSelectedMarkIndex != -1)
            {
                self.timeSliderView.selectedMark = _previousSelectedMarkIndex;
            }
            _previousSelectedDayIndex = -1;
            _previousSelectedMarkIndex = -1;

            _selectedDayIndex = selectedDayIndex;
            [self updateTimeValues:data[_selectedDayIndex][@"value"]];
            [self timeChanged:nil];
        }

        NSDate *currentDate = [OAUtilities getCurrentTimezoneDate:[NSDate date]];
        [self setCurrentMark:currentDate];
        [self.dateCollectionView setValues:data withSelectedIndex:_available ? _selectedDayIndex : -1];
        [self.dateCollectionView reloadData];
    }
}

#pragma mark - OAWeatherLayerSettingsDelegate

- (void)onDoneWeatherLayerSettings:(BOOL)show
{
    [self onUpdateWeatherLayerSettings];
    if (show)
        [[OARootViewController instance].mapPanel.hudViewController changeWeatherToolbarVisible];
    else
        [[OARootViewController instance].mapPanel.hudViewController updateWeatherButton];
}

@end
