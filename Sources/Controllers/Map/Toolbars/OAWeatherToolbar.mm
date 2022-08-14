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
#import "OACollectionViewFlowLayout.h"
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

    [_layerChangeObservers removeAllObjects];
}

- (void)onUpdateWeatherLayerSettings
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_layersHandler updateData];
        [self updateData:[_layersHandler getData] type:EOAWeatherToolbarLayers];
        [self.layersCollectionView setValues:[_layersHandler getData] withSelectedIndex:-1];
        [self.layersCollectionView reloadData];
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
    BOOL visible = [[OARootViewController instance].mapPanel.hudViewController shouldShowWeatherToolbar];
    [self updateVisibility:visible];
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
