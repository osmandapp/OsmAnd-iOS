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

#import "OATextInfoWidget.h"
#import "OAApplicationMode.h"
#import "OAMapWidgetRegistry.h"
#import "OAMapWidgetRegInfo.h"
#import "OATextInfoWidget.h"

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
}

- (instancetype) initWithHudViewController:(OAMapHudViewController *)mapHudViewController
{
    self = [super init];
    if (self)
    {
        _mapHudViewController = mapHudViewController;
        _widgetsView = mapHudViewController.widgetsView;
        _leftWidgetsView = mapHudViewController.leftWidgetsView;
        _rightWidgetsView = mapHudViewController.rightWidgetsView;
        _expandButton = mapHudViewController.expandButton;

        _mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
        _expanded = NO;
        
        [self registerAllControls];
        [self recreateControls];
    }
    return self;
}

- (void) layoutExpandButton
{
    CGRect f = _rightWidgetsView.frame;
    CGRect bf = _expandButton.frame;
    _expandButton.frame = CGRectMake(f.size.width / 2 - bf.size.width / 2, f.size.height + 8, bf.size.width, bf.size.height);
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
    
    for (UIView *container in containers)
    {
        NSArray<__kindof UIView *> *views = container.subviews;
        CGFloat maxWidth = 0;
        CGFloat widgetHeight = 0;
        for (UIView *v in views)
        {
            [v sizeToFit];
            if (maxWidth < v.frame.size.width)
                maxWidth = v.frame.size.width;
            if (widgetHeight == 0)
                widgetHeight = v.frame.size.height;
        }
        
        container.frame = CGRectMake(_mapHudViewController.view.frame.size.width - maxWidth, 0, maxWidth, widgetHeight * views.count);
        for (int i = 0; i < views.count; i++)
        {
            UIView *v = views[i];
            v.frame = CGRectMake(0, i * widgetHeight, maxWidth, widgetHeight);
        }
        
        if (container == _rightWidgetsView)
            [self layoutExpandButton];
    }
}

- (void) recreateControls
{
    OAApplicationMode *appMode = [OAAppSettings sharedManager].applicationMode;
    
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

- (void) registerAllControls
{
    /*
    RouteInfoWidgetsFactory ric = new RouteInfoWidgetsFactory();
    MapInfoWidgetsFactory mic = new MapInfoWidgetsFactory();
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
    
    // register right stack
    // priorityOrder: 10s navigation-related, 20s position-related, 30s recording- and other plugin-related, 40s general device information, 50s debugging-purpose
    TextInfoWidget intermediateDist = ric.createIntermediateDistanceControl(map);
    registerSideWidget(intermediateDist, R.drawable.ic_action_intermediate, R.string.map_widget_intermediate_distance, "intermediate_distance", false, 13);
    TextInfoWidget dist = ric.createDistanceControl(map);
    registerSideWidget(dist, R.drawable.ic_action_target, R.string.map_widget_distance, "distance", false, 14);
    TextInfoWidget time = ric.createTimeControl(map);
    registerSideWidget(time, new TimeControlWidgetState(app), "time", false, 15);
    
    if (settings.USE_MAP_MARKERS.get()) {
        TextInfoWidget marker = mwf.createMapMarkerControl(map, true);
        registerSideWidget(marker, R.drawable.ic_action_flag_dark, R.string.map_marker_1st, "map_marker_1st", false, 16);
        TextInfoWidget bearing = ric.createBearingControl(map);
        registerSideWidget(bearing, new BearingWidgetState(app), "bearing", false, 17);
        TextInfoWidget marker2nd = mwf.createMapMarkerControl(map, false);
        registerSideWidget(marker2nd, R.drawable.ic_action_flag_dark, R.string.map_marker_2nd, "map_marker_2nd", false, 18);
    } else {
        TextInfoWidget bearing = ric.createBearingControl(map);
        registerSideWidget(bearing, new BearingWidgetState(app), "bearing", false, 17);
    }
    
    TextInfoWidget speed = ric.createSpeedControl(map);
    registerSideWidget(speed, R.drawable.ic_action_speed, R.string.map_widget_speed, "speed", false, 20);
    TextInfoWidget maxspeed = ric.createMaxSpeedControl(map);
    registerSideWidget(maxspeed, R.drawable.ic_action_speed_limit, R.string.map_widget_max_speed, "max_speed", false,  21);
    TextInfoWidget alt = mic.createAltitudeControl(map);
    registerSideWidget(alt, R.drawable.ic_action_altitude, R.string.map_widget_altitude, "altitude", false, 23);
    TextInfoWidget gpsInfo = mic.createGPSInfoControl(map);
    
    registerSideWidget(gpsInfo, R.drawable.ic_action_gps_info, R.string.map_widget_gps_info, "gps_info", false, 28);
    TextInfoWidget plainTime = ric.createPlainTimeControl(map);
    registerSideWidget(plainTime, R.drawable.ic_action_time, R.string.map_widget_plain_time, "plain_time", false, 41);
    TextInfoWidget battery = ric.createBatteryControl(map);
    registerSideWidget(battery, R.drawable.ic_action_battery, R.string.map_widget_battery, "battery", false, 42);
    TextInfoWidget ruler = mic.createRulerControl(map);
    registerSideWidget(ruler, R.drawable.ic_action_ruler_circle, R.string.map_widget_ruler_control, "ruler", false, 43);
     */
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
    
}

@end
