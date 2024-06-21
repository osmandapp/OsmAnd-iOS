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
#import "OAMapInfoController.h"
#import "OAMapRendererView.h"
#import "OAWeatherLayerSettingsViewController.h"
#import "OASegmentedSlider.h"
#import "OASizes.h"
#import "OAMapLayers.h"
#import "OAMapWidgetRegistry.h"
#import "OAMapWidgetRegInfo.h"
#import "OAWeatherToolbarHandlers.h"
#import "OAWeatherHelper.h"
#import "OAWeatherPlugin.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAPluginsHelper.h"
#import "OAWeatherWidget.h"

#define kDefaultZoom 10

@interface OAWeatherToolbar () <OAWeatherToolbarDelegate>

@property (weak, nonatomic) IBOutlet OAFoldersCollectionView *layersCollectionView;
@property (weak, nonatomic) IBOutlet OAFoldersCollectionView *dateCollectionView;
@property (weak, nonatomic) IBOutlet OASegmentedSlider *timeSliderView;
@property (weak, nonatomic) IBOutlet UIStackView *weatherStackView;

@end

@implementation OAWeatherToolbar
{
    OsmAndAppInstance _app;
    NSMutableArray<OAAutoObserverProxy *> *_layerChangeObservers;
    OAAutoObserverProxy *_contourNameChangeObserver;
    OAAutoObserverProxy *_mapSourceUpdatedObserver;

    NSCalendar *_currentTimezoneCalendar;
    OAWeatherToolbarLayersHandler *_layersHandler;
    OAWeatherToolbarDatesHandler *_datesHandler;
    NSArray<NSDate *> *_timeValues;
    NSInteger _previousSelectedDayIndex;
    float _prevZoom;
    OsmAnd::PointI _prevTarget31;
    NSArray<OAWeatherWidget *> *_weatherWidgetControlsArray;
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
                [OAUtilities isLandscape] ? [OAUtilities isIPad] ? DeviceScreenHeight - [OAUtilities getStatusBarHeight] : DeviceScreenHeight : 241. + [OAUtilities getBottomMargin]
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
    _previousSelectedDayIndex = 0;

    _layersHandler = [[OAWeatherToolbarLayersHandler alloc] init];
    _layersHandler.delegate = self;
    _datesHandler = [[OAWeatherToolbarDatesHandler alloc] init];
    _datesHandler.delegate = self;

    self.dateCollectionView.foldersDelegate = _datesHandler;
    self.layersCollectionView.foldersDelegate = _layersHandler;
    [self.layersCollectionView setOnlyIconCompact:YES];
    [self.layersCollectionView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                  action:@selector(handleLongPressOnLayer:)]];

    [self.timeSliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [self.timeSliderView addTarget:self action:@selector(timeChanged:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];

    _layerChangeObservers = [NSMutableArray array];
    for (OAWeatherBand *band in [OAWeatherHelper sharedInstance].bands)
    {
        [_layerChangeObservers addObject:[band createSwitchObserver:self handler:@selector(updateLayersHandlerData)]];
    }
    _contourNameChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(updateLayersHandlerData)
                                                        andObserve:_app.data.contourNameChangeObservable];
    _mapSourceUpdatedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(updateLayersHandlerData)
                                                  andObserve:[OARootViewController instance].mapPanel.mapViewController.mapSourceUpdatedObservable];
    [self updateInfo];
}

- (void)dealloc
{
    for (OAAutoObserverProxy *observer in _layerChangeObservers)
        [observer detach];
    _layerChangeObservers = nil;

    if (_contourNameChangeObserver)
    {
        [_contourNameChangeObserver detach];
        _contourNameChangeObserver = nil;
    }
    if (_mapSourceUpdatedObserver)
    {
        [_mapSourceUpdatedObserver detach];
        _mapSourceUpdatedObserver = nil;
    }
}

- (void)configureWidgetControlsStackView
{
    _weatherWidgetControlsArray = [(OAWeatherPlugin *)[OAPluginsHelper getPlugin:OAWeatherPlugin.class] createWidgetsControls];
    
    if (_weatherWidgetControlsArray && _weatherWidgetControlsArray.count > 0) {
        [_weatherStackView removeAllArrangedSubviews];
        NSInteger itemCount = _weatherWidgetControlsArray.count;
        for (NSInteger idx = 0; idx < itemCount; idx++) {
            OAWeatherWidget *widget = _weatherWidgetControlsArray[idx];
            widget.shouldAlwaysSeparateValueAndUnitText = YES;
            widget.isVerticalStackImageTitleSubtitleLayout = YES;
            [widget updateVerticalStackImageTitleSubtitleLayout];
            BOOL showSeparator = (idx != itemCount - 1);
            [widget showRightSeparator:showSeparator];
            [_weatherStackView addArrangedSubview:widget];
        }
    }
}

- (void)resetHandlersData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _previousSelectedDayIndex = 0;
        [self.dateCollectionView setSelectedIndex:0];
        [_layersHandler updateData];
        [_datesHandler updateData];
        NSInteger selectedTimeIndex = [self getSelectedTimeIndex:[OAUtilities getCurrentTimezoneDate:[NSDate date]]];
        self.timeSliderView.selectedMark = selectedTimeIndex;
        [self updateData:[_layersHandler getData] type:EOAWeatherToolbarLayers index:-1];
        [self updateData:[_datesHandler getData] type:EOAWeatherToolbarDates index:0];
        [self.layersCollectionView reloadData];
        [self.dateCollectionView reloadData];
        [self configureWidgetControlsStackView];
    });
}

- (void)updateLayersHandlerData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_layersHandler updateData];
        [self updateData:[_layersHandler getData] type:EOAWeatherToolbarLayers index:-1];
        [self.layersCollectionView reloadData];
        [self configureWidgetControlsStackView];
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
            [self.layersCollectionView reloadData];
            _selectedLayerIndex = indexPath.row;
            _needsSettingsForToolbar = YES;
            OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
            [mapPanel.hudViewController changeWeatherToolbarVisible];
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
}

- (BOOL)updateInfo
{
    OAMapInfoController *mapInfoController = [OARootViewController instance].mapPanel.hudViewController.mapInfoController;
    BOOL visible = mapInfoController.weatherToolbarVisible;
    [self updateVisibility:visible];
    if (visible)
    {
        [self updateWidgetsInfo];
    }

    return YES;
}

- (BOOL)updateVisibility:(BOOL)visible
{
    if (visible == self.hidden)
    {
        OAMapRendererView *mapRenderer = (OAMapRendererView *) [OARootViewController instance].mapPanel.mapViewController.view;
        float zoom = mapRenderer.zoom;
        OsmAnd::PointI target31 = mapRenderer.target31;

        if (visible)
        {
            if (!self.needsSettingsForToolbar)
            {
                _prevZoom = zoom;
                _prevTarget31 = target31;
                if (zoom > kDefaultZoom)
                    [mapRenderer setZoom:kDefaultZoom];
            }

            _selectedLayerIndex = -1;
            if ([OAUtilities isLandscape])
                self.topControlsVisibleInLandscape = [[OARootViewController instance].mapPanel isTopControlsVisible];
        }
        else
        {
            if (!self.needsSettingsForToolbar && target31 == _prevTarget31 && zoom != _prevZoom && zoom == kDefaultZoom)
                [mapRenderer setZoom:_prevZoom];
        }

        if (self.delegate)
            [self.delegate widgetVisibilityChanged:self visible:!visible];

        return YES;
    }
    return NO;
}

- (NSInteger)getSelectedTimeIndex:(NSDate *)date
{
    NSDate *roundedDate = [OAWeatherHelper roundForecastTimeToHour:date];
    return [_currentTimezoneCalendar components:NSCalendarUnitHour fromDate:roundedDate].hour;
}

- (NSDate *)getSelectedGMTDate
{
    return [OARootViewController instance].mapPanel.mapViewController.mapLayers.weatherDate;
}

- (NSInteger)getSelectedDateIndex
{
    NSInteger day = [_currentTimezoneCalendar components:NSCalendarUnitDay fromDate:[self getSelectedGMTDate]].day;
    NSArray<NSDictionary *> *datesData = [_datesHandler getData];
    for (NSInteger i = 0; i < datesData.count; i++)
    {
        NSDate *itemDate = datesData[i][@"value"];
        NSInteger itemDay = [_currentTimezoneCalendar components:NSCalendarUnitDay fromDate:itemDate].day;
        if (day == itemDay)
            return i;
    }

    return 0;
}

- (void)setCurrentMark:(NSInteger)index
{
    NSDate *date = [OAUtilities getCurrentTimezoneDate:[NSDate date]];
    NSInteger minimumForCurrentMark = [_currentTimezoneCalendar startOfDayForDate:date].timeIntervalSince1970;
    NSInteger currentValue = date.timeIntervalSince1970;
    self.timeSliderView.currentMarkX = index == 0 ? (currentValue - minimumForCurrentMark) : -1;
    date = [_currentTimezoneCalendar startOfDayForDate:date];
    date = [_currentTimezoneCalendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0];
    self.timeSliderView.maximumForCurrentMark = [_currentTimezoneCalendar startOfDayForDate:date].timeIntervalSince1970 - minimumForCurrentMark;
}

- (void)updateTimeValues:(NSDate *)date
{
    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    NSDate *selectedNextDate = [calendar startOfDayForDate:date];
    NSMutableArray<NSDate *> *selectedTimeValues = [NSMutableArray array];
    [selectedTimeValues addObject:selectedNextDate];

    NSInteger selectedDayIndex = [self.dateCollectionView getSelectedIndex];
    NSInteger count = selectedDayIndex == 0 ? 9 + (9 - 1) * 2 : 9;
    for (NSInteger i = 0; i < count - 1; i++)
    {
        selectedNextDate = [calendar dateByAddingUnit:NSCalendarUnitHour
                                                value:selectedDayIndex == 0 ? 1 : 3
                                               toDate:selectedNextDate
                                              options:0];
        [selectedTimeValues addObject:selectedNextDate];
    }

    _timeValues = selectedTimeValues;
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
            frame.size.height = 241. + [OAUtilities getBottomMargin];
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
            frame.size.height = 241. + [OAUtilities getBottomMargin];
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
            frame.size.height = 241. + [OAUtilities getBottomMargin];
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
            frame.size.height = 241. + [OAUtilities getBottomMargin];
            frame.origin = CGPointMake(0., y);
        }
    }
    self.frame = frame;
}

+ (CGFloat)calculateY
{
    if ([OAUtilities isLandscape])
        return [OAUtilities isIPad] ? [OAUtilities getStatusBarHeight] : 0.;

    return DeviceScreenHeight - (241. + [OAUtilities getBottomMargin]);
}

+ (CGFloat)calculateYOutScreen
{
    if ([OAUtilities isLandscape])
        return [OAUtilities isIPad] ? [OAUtilities getStatusBarHeight] -1 : -1.;

    return DeviceScreenHeight + 241. + [OAUtilities getBottomMargin];
}

- (void)updateWidgetsInfo
{
    for (OAWeatherWidget *itemView in _weatherWidgetControlsArray) {
        [itemView updateInfo];
    }
}

#pragma mark - UISlider

- (void)timeChanged:(UISlider *)sender
{
    NSInteger index = self.timeSliderView.selectedMark;
    NSDate *selectedDate = _timeValues[index];
    [[OARootViewController instance].mapPanel.mapViewController.mapLayers updateWeatherDate:selectedDate];

    if ([_layersHandler isAllLayersDisabled]) {
        [(OAWeatherPlugin *) [OAPluginsHelper getPlugin:OAWeatherPlugin.class] updateWidgetsInfo];
        [self updateWidgetsInfo];
    }
}

#pragma mark - OAWeatherToolbarDelegate

- (void)updateData:(NSArray *)data type:(EOAWeatherToolbarDelegateType)type index:(NSInteger)index
{
    if (type == EOAWeatherToolbarLayers)
    {
        [self.layersCollectionView setValues:data withSelectedIndex:index];
        [self.layersCollectionView reloadData];
    }
    else if (type == EOAWeatherToolbarDates)
    {
        [self updateTimeValues:data[index][@"value"]];
        [self setCurrentMark:index];
        [self.timeSliderView setNumberOfMarks:9 additionalMarksBetween:index > 0 ? 0 : 2];

        NSInteger selectedTimeIndex = self.timeSliderView.selectedMark;
        if (_previousSelectedDayIndex == 0 && index > 0)
            selectedTimeIndex = (NSInteger) round(selectedTimeIndex / 3);
        else if (_previousSelectedDayIndex > 0 && index == 0)
            selectedTimeIndex *= 3;

        self.timeSliderView.selectedMark = selectedTimeIndex;
        [self timeChanged:nil];

        [self.dateCollectionView setValues:data withSelectedIndex:index];
        [self.dateCollectionView reloadData];
        _previousSelectedDayIndex = index;
        [self updateWidgetsInfo];
    }
}

@end
