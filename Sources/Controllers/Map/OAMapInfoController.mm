//
//  OAMapInfoController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapInfoController.h"
#import "OAMapHudViewController.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OARoutingHelper.h"
#import "OAUtilities.h"
#import "Localization.h"
#import "OAAutoObserverProxy.h"

#import "OATextInfoWidget.h"
#import "OAApplicationMode.h"
#import "OAMapWidgetRegistry.h"
#import "OAMapWidgetRegInfo.h"
#import "OARouteInfoWidgetsFactory.h"
#import "OAMapInfoWidgetsFactory.h"

@interface OATextState : NSObject

@property (nonatomic) BOOL textBold;
@property (nonatomic) BOOL night;
@property (nonatomic) UIColor *textColor ;
@property (nonatomic) UIColor *textShadowColor ;
@property (nonatomic) int boxTop;
@property (nonatomic) int rightRes;
@property (nonatomic) int leftRes;
@property (nonatomic) int expand;
@property (nonatomic) int boxFree;
@property (nonatomic) int textShadowRadius;

@end

@implementation OATextState
@end

@interface OAMapInfoController () <OAWidgetListener>

@end

@implementation OAMapInfoController
{
    OAMapHudViewController __weak *_mapHudViewController;
    UIView __weak *_widgetsView;
    UIView __weak *_leftWidgetsView;
    UIView __weak *_rightWidgetsView;
    UIButton __weak *_expandButton;

    OAMapWidgetRegistry *_mapWidgetRegistry;
    BOOL _expanded;

    OAAppSettings *_settings;
    OAAutoObserverProxy* _framePreparedObserver;
    OAAutoObserverProxy* _applicaionModeObserver;
    
    NSTimeInterval _lastUpdateTime;
}

- (instancetype) initWithHudViewController:(OAMapHudViewController *)mapHudViewController
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];

        _mapHudViewController = mapHudViewController;
        _widgetsView = mapHudViewController.widgetsView;
        _leftWidgetsView = mapHudViewController.leftWidgetsView;
        _rightWidgetsView = mapHudViewController.rightWidgetsView;
        _expandButton = mapHudViewController.expandButton;

        _mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
        _expanded = NO;
        
        [self registerAllControls];
        [self recreateControls];
        
        _framePreparedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onMapRendererFramePrepared)
                                                            andObserve:[OARootViewController instance].mapPanel.mapViewController.framePreparedObservable];
        
        _applicaionModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                            withHandler:@selector(onApplicationModeChanged:)
                                                             andObserve:[OsmAndApp instance].data.applicationModeChangedObservable];
    }
    return self;
}

- (void) onMapRendererFramePrepared
{
    NSTimeInterval currentTime = CACurrentMediaTime();
    if (currentTime - _lastUpdateTime > 1)
    {
        _lastUpdateTime = currentTime;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapWidgetRegistry updateInfo:_settings.applicationMode expanded:_expanded];
        });
    }
}

- (void) onApplicationModeChanged:(OAApplicationMode *)prevMode
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self recreateControls];
    });
}

- (void) layoutExpandButton
{
    CGRect f = _rightWidgetsView.frame;
    CGRect bf = _expandButton.frame;
    _expandButton.frame = CGRectMake(f.origin.x + f.size.width / 2 - bf.size.width / 2, f.size.height == 0 ? 0 : f.size.height + 4, bf.size.width, bf.size.height);
}

- (void) layoutWidgets:(OATextInfoWidget *)widget
{
    NSMutableArray<UIView *> *containers = [NSMutableArray array];
    if (widget)
    {
        for (UIView *w in _leftWidgetsView.subviews)
        {
            if (w == widget)
            {
                [containers addObject:_leftWidgetsView];
                break;
            }
        }
        for (UIView *w in _rightWidgetsView.subviews)
        {
            if (w == widget)
            {
                [containers addObject:_rightWidgetsView];
                break;
            }
        }
    }
    else
    {
        [containers addObject:_leftWidgetsView];
        [containers addObject:_rightWidgetsView];
    }
    
    CGFloat maxContainerHeight = 0;
    
    for (UIView *container in containers)
    {
        NSArray<UIView *> *allViews = container.subviews;
        NSMutableArray<UIView *> *views = [NSMutableArray array];
        for (UIView *v in allViews)
            if (!v.hidden)
                [views addObject:v];
        
        CGFloat maxWidth = 0;
        CGFloat widgetHeight = 0;
        for (UIView *v in views)
        {
            if (v.hidden)
                continue;
            
            if ([v isKindOfClass:[OATextInfoWidget class]])
                [((OATextInfoWidget *)v) adjustViewSize];
            else
                [v sizeToFit];
            
            if (maxWidth < v.frame.size.width)
                maxWidth = v.frame.size.width;
            if (widgetHeight == 0)
                widgetHeight = v.frame.size.height;
        }
        
        CGFloat containerHeight = widgetHeight * views.count;
        if (maxWidth == 0)
            maxWidth = _expandButton.frame.size.width + 8;
        
        container.frame = CGRectMake(_mapHudViewController.view.frame.size.width - maxWidth, 0, maxWidth, containerHeight);
        
        if (container == _rightWidgetsView)
            containerHeight += _expandButton.frame.size.height + 4;
        if (maxContainerHeight < containerHeight)
            maxContainerHeight = containerHeight;
        
        CGFloat y = 0;
        for (int i = 0; i < views.count; i++)
        {
            UIView *v = views[i];
            v.frame = CGRectMake(0, y, maxWidth, widgetHeight);
            y += widgetHeight + 2;
        }
        
        if (container == _rightWidgetsView)
            [self layoutExpandButton];
    }
    
    if (_rightWidgetsView.superview)
    {
        CGRect f = _rightWidgetsView.superview.frame;
        _rightWidgetsView.superview.frame = CGRectMake(f.origin.x, f.origin.y, f.size.width, maxContainerHeight);
    }
}

- (void) recreateControls
{
    OAApplicationMode *appMode = _settings.applicationMode;
    
    for (UIView *widget in _leftWidgetsView.subviews)
        [widget removeFromSuperview];
    
    for (UIView *widget in _rightWidgetsView.subviews)
        [widget removeFromSuperview];
    
    //[self.view insertSubview:self.widgetsView belowSubview:_toolbarViewController.view];
    [_mapWidgetRegistry populateStackControl:_leftWidgetsView mode:appMode left:YES expanded:_expanded];
    [_mapWidgetRegistry populateStackControl:_rightWidgetsView mode:appMode left:NO expanded:_expanded];
        
    for (UIView *v in _leftWidgetsView.subviews)
    {
        OATextInfoWidget *w = (OATextInfoWidget *)v;
        w.delegate = self;
    }
    for (UIView *v in _rightWidgetsView.subviews)
    {
        OATextInfoWidget *w = (OATextInfoWidget *)v;
        w.delegate = self;
    }
    
    [self layoutWidgets:nil];
    
    _expandButton.hidden = ![_mapWidgetRegistry hasCollapsibles:appMode];
    [_expandButton setImage:(_expanded ? [UIImage imageNamed:@"ic_collapse"] : [UIImage imageNamed:@"ic_expand"]) forState:UIControlStateNormal];
}

- (void) expandClicked:(id)sender
{
    _expanded = !_expanded;
    [self recreateControls];
}

- (OATextState *) calculateTextState
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];

    BOOL transparent = [_settings.transparentMapTheme get];
    BOOL nightMode = _settings.settingAppMode == APPEARANCE_MODE_NIGHT;
    BOOL following = [routingHelper isFollowingMode];
    OATextState *ts = [[OATextState alloc] init];
    ts.textBold = following;
    ts.night = nightMode;
    ts.textColor = nightMode ? UIColorFromRGB(0xC8C8C8) : [UIColor blackColor];
    // Night shadowColor always use widgettext_shadow_night, same as widget background color for non-transparent
    /*
    ts.textShadowColor = nightMode ? ContextCompat.getColor(view.getContext(), R.color.widgettext_shadow_night) : Color.WHITE;
    if (!transparent && !nightMode) {
        ts.textShadowRadius = 0;
    } else {
        ts.textShadowRadius = (int) (4 * view.getDensity());
    }
     
    if (transparent) {
        ts.boxTop = R.drawable.btn_flat_transparent;
        ts.rightRes = R.drawable.btn_left_round_transparent;
        ts.leftRes = R.drawable.btn_right_round_transparent;
        ts.expand = R.drawable.btn_inset_circle_transparent;
        ts.boxFree = R.drawable.btn_round_transparent;
    } else if (nightMode) {
        ts.boxTop = R.drawable.btn_flat_night;
        ts.rightRes = R.drawable.btn_left_round_night;
        ts.leftRes = R.drawable.btn_right_round_night;
        ts.expand = R.drawable.btn_inset_circle_night;
        ts.boxFree = R.drawable.btn_round_night;
    } else {
        ts.boxTop = R.drawable.btn_flat;
        ts.rightRes = R.drawable.btn_left_round;
        ts.leftRes = R.drawable.btn_right_round;
        ts.expand = R.drawable.btn_inset_circle;
        ts.boxFree = R.drawable.btn_round;
    }
     */
    return ts;
}

- (void) updateReg:(OATextState *)ts reg:(OAMapWidgetRegInfo *)reg
{
    //v.setBackgroundResource(reg.left ? ts.leftRes : ts.rightRes);
    [reg.widget updateTextColor:ts.textColor bold:ts.textBold];
    [reg.widget updateIconMode:ts.night];
}

- (OAMapWidgetRegInfo *) registerSideWidget:(OATextInfoWidget *)widget imageId:(NSString *)imageId message:(NSString *)message key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder
{
    OAMapWidgetRegInfo *reg = [_mapWidgetRegistry registerSideWidgetInternal:widget imageId:imageId message:message key:key left:left priorityOrder:priorityOrder];
    [self updateReg:[self calculateTextState] reg:reg];
    return reg;
}

- (void) registerSideWidget:(OATextInfoWidget *)widget widgetState:(OAWidgetState *)widgetState key:(NSString *)key left:(BOOL)left priorityOrder:(int)priorityOrder
{
    OAMapWidgetRegInfo *reg = [_mapWidgetRegistry registerSideWidgetInternal:widget widgetState:widgetState key:key left:left priorityOrder:priorityOrder];
    [self updateReg:[self calculateTextState] reg:reg];
}

- (void) removeSideWidget:(OATextInfoWidget *)widget
{
    [_mapWidgetRegistry removeSideWidgetInternal:widget];
}

- (void) registerAllControls
{
    OARouteInfoWidgetsFactory *ric = [[OARouteInfoWidgetsFactory alloc] init];
    OAMapInfoWidgetsFactory *mic = [[OAMapInfoWidgetsFactory alloc] init];
    /*
    MapMarkersWidgetsFactory mwf = map.getMapLayers().getMapMarkersLayer().getWidgetsFactory();
    OsmandApplication app = view.getApplication();
    lanesControl = ric.createLanesControl(map, view);
    
    streetNameView = new TopTextView(map.getMyApplication(), map);
    updateStreetName(false, calculateTextState());
    
    topToolbarView = new TopToolbarView(map);
    updateTopToolbar(false);
    
    alarmControl = ric.createAlarmInfoControl(app, map);
    alarmControl.setVisibility(false);
    
    rulerControl = ric.createRulerControl(app, map);
    rulerControl.setVisibility(false);
    
    // register left stack
    registerSideWidget(null, R.drawable.ic_action_compass, R.string.map_widget_compass, "compass", true, 4);
    
    NextTurnInfoWidget bigInfoControl = ric.createNextInfoControl(map, app, false);
    registerSideWidget(bigInfoControl, R.drawable.ic_action_next_turn, R.string.map_widget_next_turn, "next_turn", true, 5);
    NextTurnInfoWidget smallInfoControl = ric.createNextInfoControl(map, app, true);
    registerSideWidget(smallInfoControl, R.drawable.ic_action_next_turn, R.string.map_widget_next_turn_small, "next_turn_small", true, 6);
    NextTurnInfoWidget nextNextInfoControl = ric.createNextNextInfoControl(map, app, true);
    registerSideWidget(nextNextInfoControl, R.drawable.ic_action_next_turn, R.string.map_widget_next_next_turn, "next_next_turn",true, 7);
    
     */

    // register right stack
    // priorityOrder: 10s navigation-related, 20s position-related, 30s recording- and other plugin-related, 40s general device information, 50s debugging-purpose
    OATextInfoWidget *intermediateDist = [ric createIntermediateDistanceControl];
    [self registerSideWidget:intermediateDist imageId:@"ic_action_intermediate" message:OALocalizedString(@"map_widget_intermediate_distance") key:@"intermediate_distance" left:NO priorityOrder:13];

    OATextInfoWidget *dist = [ric createDistanceControl];
    [self registerSideWidget:dist imageId:@"ic_action_target" message:OALocalizedString(@"map_widget_distance") key:@"distance" left:NO priorityOrder:14];

    OATextInfoWidget *time = [ric createTimeControl];
    [self registerSideWidget:time widgetState:[[OATimeControlWidgetState alloc] init] key:@"time" left:false priorityOrder:15];
    
    /*
    TextInfoWidget marker = mwf.createMapMarkerControl(map, true);
    registerSideWidget(marker, R.drawable.ic_action_flag_dark, R.string.map_marker_1st, "map_marker_1st", false, 16);
    TextInfoWidget bearing = ric.createBearingControl(map);
    registerSideWidget(bearing, new BearingWidgetState(app), "bearing", false, 17);
    TextInfoWidget marker2nd = mwf.createMapMarkerControl(map, false);
    registerSideWidget(marker2nd, R.drawable.ic_action_flag_dark, R.string.map_marker_2nd, "map_marker_2nd", false, 18);
    */
    
    OATextInfoWidget *speed = [ric createSpeedControl];
    [self registerSideWidget:speed imageId:@"ic_action_speed" message:OALocalizedString(@"gpx_speed") key:@"speed" left:false priorityOrder:20];
    OATextInfoWidget *maxspeed = [ric createMaxSpeedControl];
    [self registerSideWidget:maxspeed imageId:@"ic_action_speed_limit" message:OALocalizedString(@"map_widget_max_speed") key:@"max_speed" left:false priorityOrder:21];
    OATextInfoWidget *alt = [mic createAltitudeControl];
    [self registerSideWidget:alt imageId:@"ic_action_altitude" message:OALocalizedString(@"map_widget_altitude") key:@"altitude" left:false priorityOrder:23];

    OATextInfoWidget *plainTime = [ric createPlainTimeControl];
    [self registerSideWidget:plainTime imageId:@"ic_action_time" message:OALocalizedString(@"map_widget_plain_time") key:@"plain_time" left:false priorityOrder:41];
    OATextInfoWidget *battery = [ric createBatteryControl];
    [self registerSideWidget:battery imageId:@"ic_action_battery" message:OALocalizedString(@"map_widget_battery") key:@"battery" left:false priorityOrder:42];
    //TextInfoWidget ruler = mic.createRulerControl(map);
    //registerSideWidget(ruler, R.drawable.ic_action_ruler_circle, R.string.map_widget_ruler_control, "ruler", false, 43);
}

#pragma mark - OAWidgetListener

- (void) widgetChanged:(OATextInfoWidget *)widget
{
    [self layoutWidgets:widget];
}

- (void) widgetVisibilityChanged:(OATextInfoWidget *)widget visible:(BOOL)visible
{
    [self layoutWidgets:widget];
}

- (void) widgetClicked:(OATextInfoWidget *)widget
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_mapWidgetRegistry updateInfo:_settings.applicationMode expanded:_expanded];
    });
}

@end
