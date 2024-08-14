//
//  OAWeatherToolbar.mm
//  OsmAnd
//
//  Created by Skalii on 03.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherToolbar.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapInfoController.h"
#import "OAMapRendererView.h"
#import "OAWeatherLayerSettingsViewController.h"
#import "OAWeatherTimeSegmentedSlider.h"
#import "OASizes.h"
#import "OAMapLayers.h"
#import "OAMapWidgetRegistry.h"
#import "OAMapWidgetRegInfo.h"
#import "OAWeatherToolbarHandlers.h"
#import "OAWeatherHelper.h"
#import "OAWeatherPlugin.h"
#import "OAPluginsHelper.h"
#import "OAWeatherWidget.h"
#import "OAAutoObserverProxy.h"
#import "OAAppData.h"
#import "OAObservable.h"
#import "OAWeatherWebClient.h"
#import "OsmAnd_Maps-Swift.h"

static int kDefaultZoom = 10;

static NSInteger kForecastMaxStepsCount = FORECAST_ANIMATION_DURATION_HOURS * [OAWeatherTimeSegmentedSlider getForecastStepsPerHour];

static NSTimeInterval kAnimationStartDelaySec = 0.1;
static NSTimeInterval kAnimationFrameDelaySec = 0.083;
static NSTimeInterval kDownloadingCompleteDelaySec = 0.25;

typedef NS_ENUM(NSInteger, EOAWeatherToolbarAnimationState) {
    EOAWeatherToolbarAnimationStateIdle = 0,
    EOAWeatherToolbarAnimationStateStarted,
    EOAWeatherToolbarAnimationStateInProgress,
    EOAWeatherToolbarAnimationStateSuspended,
};

@interface OAWeatherToolbar () <OAWeatherToolbarDelegate>

@property (weak, nonatomic) IBOutlet OAFoldersCollectionView *dateCollectionView;
@property (weak, nonatomic) IBOutlet OAWeatherTimeSegmentedSlider *timeSliderView;
@property (weak, nonatomic) IBOutlet UIStackView *weatherStackView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@end

@implementation OAWeatherToolbar
{
    OsmAndAppInstance _app;
    OAWeatherPlugin *_plugin;
    NSMutableArray<OAAutoObserverProxy *> *_layerChangeObservers;
    OAAutoObserverProxy *_contourNameChangeObserver;
    OAAutoObserverProxy *_mapSourceUpdatedObserver;

    OAWeatherToolbarLayersHandler *_layersHandler;
    OAWeatherToolbarDatesHandler *_datesHandler;
    NSInteger _previousSelectedDayIndex;
    float _prevZoom;
    OsmAnd::PointI _prevTarget31;
    NSArray<OAWeatherWidget *> *_weatherWidgetControlsArray;
    
    NSInteger _lastUpdatedIndex;
    NSDate *_currentDate;
    NSDate *_selectedDate;
    
    EOAWeatherToolbarAnimationState _animationState;
    NSInteger _animationStartStep;
    NSInteger _currentStep;
    NSInteger _animateStepCount;
    NSInteger _animationStartStepCount;
    BOOL _isDownloading;
    BOOL _wasDownloading;
    
    CFTimeInterval _currentLoopStart;
    CFTimeInterval _nextLoopStart;
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
                [OAUtilities isLandscape] ? [OAUtilities isIPad] ? DeviceScreenHeight - [OAUtilities getStatusBarHeight] : DeviceScreenHeight : 241. + [[self class] bottomOffset]
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
    _plugin = (OAWeatherPlugin *) [OAPluginsHelper getPlugin:OAWeatherPlugin.class];
    _previousSelectedDayIndex = 0;

    _layersHandler = [[OAWeatherToolbarLayersHandler alloc] init];
    _datesHandler = [[OAWeatherToolbarDatesHandler alloc] init];
    _datesHandler.delegate = self;

    self.dateCollectionView.foldersDelegate = _datesHandler;
    
    _currentDate = [NSDate now];
    _selectedDate = _currentDate;
    _animationState = EOAWeatherToolbarAnimationStateIdle;
    
    [self.timeSliderView commonInit];
    self.timeSliderView.datesHandler = _datesHandler;
    [self.timeSliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [self.timeSliderView addTarget:self action:@selector(timeChanged:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventValueChanged];

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDownloadStateChanged:)
                                                     name:kOAWeatherWebClientNotificationKey object:nil];
    
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
    _weatherWidgetControlsArray = [[_plugin createWidgetsControls] copy];
    
    if (_weatherWidgetControlsArray && _weatherWidgetControlsArray.count > 0) {
        [_weatherStackView removeAllArrangedSubviews];
        NSInteger itemCount = _weatherWidgetControlsArray.count;
        for (NSInteger idx = 0; idx < itemCount; idx++) {
            OAWeatherWidget *widget = _weatherWidgetControlsArray[idx];
            widget.shouldAlwaysSeparateValueAndUnitText = YES;
            widget.useDashSymbolWhenTextIsEmpty = YES;
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
        NSInteger selectedTimeIndex = [self.timeSliderView getSelectedTimeIndex:[OAUtilities getCurrentTimezoneDate:[NSDate date]]];
        self.timeSliderView.selectedMark = selectedTimeIndex;
        [self updateData:[_datesHandler getData] index:0];
        [self.dateCollectionView reloadData];
        [self configureWidgetControlsStackView];
    });
}

- (void)updateLayersHandlerData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_layersHandler updateData];
        [self configureWidgetControlsStackView];
    });
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

+ (CGFloat)bottomOffset
{
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    return bottomMargin != 0.0 ? bottomMargin : 20.0;
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
            frame.size.height = 241. + [[self class] bottomOffset];
            frame.origin = CGPointMake(0., y);
        }
    }
    else
    {
        if ([OAUtilities isLandscape])
        {
            frame.size.width = DeviceScreenWidth * 0.45;
            frame.size.height = DeviceScreenHeight;
            frame.origin = CGPointMake(0., 44);;
        }
        else
        {
            frame.size.width = DeviceScreenWidth;
            frame.size.height = 241. + [[self class] bottomOffset];
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
            frame.size.height = 241. + [[self class] bottomOffset];
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
            frame.size.height = 241. + [[self class] bottomOffset];
            frame.origin = CGPointMake(0., y);
        }
    }
    self.frame = frame;
}

+ (CGFloat)calculateY
{
    if ([OAUtilities isLandscape])
        return [OAUtilities isIPad] ? [OAUtilities getStatusBarHeight] + 44.0 : 44.0;

    return DeviceScreenHeight - (241. + [[self class] bottomOffset]);
}

+ (CGFloat)calculateYOutScreen
{
    if ([OAUtilities isLandscape])
        return [OAUtilities isIPad] ? [OAUtilities getStatusBarHeight] + 44 - 1 : 44 - 1.;

    return DeviceScreenHeight + 241. + [[self class] bottomOffset];
}

- (void)updateWidgetsInfo
{
    for (OAWeatherWidget *itemView in _weatherWidgetControlsArray) {
        [itemView updateInfo];
    }
}

#pragma mark - Start/stop button

- (IBAction)onPlayForecastClicked:(id)sender
{
    EOAWeatherToolbarAnimationState animationState = _animationState == EOAWeatherToolbarAnimationStateIdle ? EOAWeatherToolbarAnimationStateStarted : EOAWeatherToolbarAnimationStateIdle;
    _animationState = animationState;
    if (animationState == EOAWeatherToolbarAnimationStateStarted)
    {
        _currentStep = [self.timeSliderView getIndexForOptionStepsAmountWithoutDrawMark];
        _animationStartStep = _currentStep;
        _selectedDate = [self.timeSliderView getSelectedDate];
        
        NSInteger remainingStepsForMidnight = [self.timeSliderView getTimeValuesCount] - _currentStep - 1;
        _animateStepCount = MIN(kForecastMaxStepsCount, remainingStepsForMidnight);
        _animationStartStepCount = _animateStepCount;
        
        [_plugin prepareForDayAnimation:_selectedDate];
        [self updateSelectedDate:_selectedDate forAnimation:YES resetPeriod:YES];
        [self scheduleAnimationStart];
    }
    else
    {
        [self stopAnimation];
    }
    [self updatePlayForecastButton];
}

- (void) updatePlayForecastButton
{
    NSString *iconName = _animationState == EOAWeatherToolbarAnimationStateIdle ? @"ic_custom_play" : @"ic_custom_pause";
    [_playButton setImage:[UIImage templateImageNamed:iconName] forState:UIControlStateNormal];
}

- (void) scheduleAnimationStart
{
    _currentLoopStart = CACurrentMediaTime();
    _nextLoopStart = _currentLoopStart + kAnimationFrameDelaySec;
}

- (void)onFrameAnimatorsUpdated
{
    if (_animationState != EOAWeatherToolbarAnimationStateIdle && _currentLoopStart > 0)
    {
        CFTimeInterval currentTime = CACurrentMediaTime();
        if (currentTime >= _nextLoopStart)
        {
            CFTimeInterval newCurrentLoopStart = _nextLoopStart;
            if (!_isDownloading)
            {
                if (!_wasDownloading)
                {
                    _nextLoopStart = currentTime + kAnimationFrameDelaySec;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self moveToNextForecastFrame];
                    });
                }
                else
                {
                    _wasDownloading = NO;
                    _nextLoopStart = currentTime + kDownloadingCompleteDelaySec;
                }
            }
            else
            {
                _wasDownloading = YES;
            }
            _currentLoopStart = newCurrentLoopStart;
        }
    }
    else
    {
        _currentLoopStart = 0;
    }
}

- (void) stopAnimation
{
    _animationState = EOAWeatherToolbarAnimationStateIdle;
    _currentLoopStart = 0;
    [self updateProgressBar];
    [self updatePlayForecastButton];
}

- (void) moveToNextForecastFrame
{
    if (_animationState == EOAWeatherToolbarAnimationStateIdle)
        return;
    
    if (_isDownloading)
    {
        _animationState = EOAWeatherToolbarAnimationStateSuspended;
        return;
    }
    
    if ([OAWeatherHelper.sharedInstance isProcessingTiles])
    {
        _animationState = EOAWeatherToolbarAnimationStateSuspended;
        [self updateProgressBar];
        return;
    }
    
    if (_currentStep + 1 > [self.timeSliderView getTimeValuesCount] || _animateStepCount == 0)
    {
        _currentStep = _animationStartStep;
        _animateStepCount = _animationStartStepCount;
    }
    else
    {
        _currentStep++;
        _animateStepCount--;
    }
    
    [self updateProgressBar];
    [self updateSliderValue];
    [self updateSelectedDate:[self.timeSliderView getTimeValues][_currentStep] forAnimation:YES resetPeriod:NO];
    
    if (_animationState == EOAWeatherToolbarAnimationStateStarted || _animationState == EOAWeatherToolbarAnimationStateSuspended)
    {
        _animationState = EOAWeatherToolbarAnimationStateInProgress;
        [self updateProgressBar];
    }
}

#pragma mark - Downloading methods

- (void) onDownloadStateChanged:(NSNotification *)notification
{
    NSNumber *requestsCount = notification.object;

    if (requestsCount)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            _isDownloading = requestsCount.intValue > 0;
            [self updateProgressBar];
        });
    }
}

- (void) updateProgressBar
{
    if (_isDownloading || (_animationState != EOAWeatherToolbarAnimationStateIdle && [OAWeatherHelper.sharedInstance isProcessingTiles]))
    {
        [[OARootViewController instance].view addSpinnerInCenterOfCurrentView:YES];
    }
    else
    {
        [[OARootViewController instance].view removeSpinner];
    }
}

#pragma mark - UISlider

- (void)timeChanged:(UISlider *)sender
{
    BOOL fromUser = sender != nil;
    if (fromUser)
        [self stopAnimation];
        
    _selectedDate = [self.timeSliderView getSelectedDate];
    [self updateSelectedDate:_selectedDate forAnimation:!fromUser resetPeriod:NO];
}

- (void) updateSliderValue
{
    float value = ((float)_currentStep) / ((float)[self.timeSliderView getTimeValuesCount]);
    [self.timeSliderView setValue:value animated:YES];
}

- (void) updateSelectedDate:(NSDate *)date forAnimation:(BOOL)forAnimation resetPeriod:(BOOL)resetPeriod
{
    [_plugin setForecastDate:date forAnimation:forAnimation resetPeriod:resetPeriod];
    if (date)
        date = [OAWeatherHelper roundForecastTimeToHour:date];
    
    [self checkDateOffset:date];
    
    // TODO: replace to widgetsPanel.setSelectedDate(date);
    [_plugin updateWidgetsInfo];
    [self updateWidgetsInfo];
    
    // TODO: replace to [[OARootViewController instance].mapPanel refreshMap];
    [[OARootViewController instance].mapPanel.mapViewController.mapLayers updateWeatherLayers];
}

- (void) checkDateOffset:(NSDate *)date
{
    NSInteger MIN_UTC_HOURS_OFFSET = 24 * 60 * 60;
    if (date && (([date timeIntervalSince1970] - [_currentDate timeIntervalSince1970])  >= MIN_UTC_HOURS_OFFSET))
    {
        NSCalendar *utcCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        utcCalendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        NSDateComponents *dateComponents = [utcCalendar components:NSCalendarUnitHour fromDate:date];
        NSInteger hours = dateComponents.hour;
        NSInteger offset = hours % 3;
        if (offset == 2)
            [dateComponents setHour:hours + 1];
        else if (offset == 1)
            [dateComponents setHour:hours - 1];
        date = [utcCalendar dateFromComponents:dateComponents];
    }
}

#pragma mark - OAWeatherToolbarDelegate

- (void)updateData:(NSArray *)data index:(NSInteger)index
{
    [self.timeSliderView updateTimeValues:data[index][@"value"]];
    [self.timeSliderView setCurrentMark:index];
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

@end
