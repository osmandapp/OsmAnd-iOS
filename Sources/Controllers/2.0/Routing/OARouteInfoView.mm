//
//  OARouteInfoView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 10/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARouteInfoView.h"
#import "OATargetPointsHelper.h"
#import "OARoutingHelper.h"
#import "OAAppModeCell.h"
#import "OARoutingTargetCell.h"
#import "OARoutingInfoCell.h"
#import "OARTargetPoint.h"
#import "OAPointDescription.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "PXAlertView.h"
#import "OsmAndApp.h"
#import "OAApplicationMode.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"
#import "OAFavoriteItem.h"
#import "OADestinationItem.h"
#import "OAMapActions.h"
#import "OAUtilities.h"
#import "OAWaypointUIHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAGPXDocument.h"
#import "OAGPXUIHelper.h"
#import "OAAppModeView.h"
#import "OAColors.h"
#import "OAAddDestinationBottomSheetViewController.h"
#import "OARoutingSettingsCell.h"
#import "OAHomeWorkCell.h"
#import "OAGPXDatabase.h"
#import "OAMultiIconTextDescCell.h"
#import "OATableViewCustomHeaderView.h"
#import "OAStateChangedListener.h"
#import "OADividerCell.h"
#import "OADescrTitleCell.h"
#import "OADescrTitleIconCell.h"
#import "OARouteProvider.h"
#import "OASelectedGPXHelper.h"

#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>

#define kInfoViewLanscapeWidth 320.0

#define kCellReuseIdentifier @"emptyCell"
#define kHeaderId @"TableViewSectionHeader"

static int directionInfo = -1;
static BOOL visible = false;

typedef NS_ENUM(NSInteger, EOARouteInfoMenuState)
{
    EOARouteInfoMenuStateInitial = 0,
    EOARouteInfoMenuStateExpanded,
    EOARouteInfoMenuStateFullScreen
};

@interface OARouteInfoView ()<OARouteInformationListener, OAAppModeCellDelegate, OAWaypointSelectionDialogDelegate, OAHomeWorkCellDelegate, OAStateChangedListener, UIGestureRecognizerDelegate>

@end

@implementation OARouteInfoView
{
    OATargetPointsHelper *_pointsHelper;
    OARoutingHelper *_routingHelper;
    OsmAndAppInstance _app;
    
    NSDictionary<NSNumber *, NSArray *> *_data;
    
    CALayer *_horizontalLine;
    CALayer *_verticalLine1;
    CALayer *_verticalLine2;
    
    BOOL _switched;
    
    OARouteStatisticsViewController *_routeStatsController;
    OAAppModeView *_appModeView;
    
    UIPanGestureRecognizer *_panGesture;
    EOARouteInfoMenuState _currentState;
    
    BOOL _isDragging;
    
    NSInteger _prevRouteSection;
    NSInteger _gpxTripSection;
    NSInteger _mapMarkerSection;
    NSInteger _historySection;
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OARouteInfoView class]])
            self = (OARouteInfoView *)v;
    }

    if (self)
    {
        [self commonInit];
    }
    
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OARouteInfoView class]])
            self = (OARouteInfoView *) v;
    }
    
    if (self)
    {
        [self commonInit];
        self.frame = frame;
    }
    
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    // drop shadow
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.layer setShadowOpacity:0.3];
    [self.layer setShadowRadius:3.0];
    [self.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    
    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _verticalLine1 = [CALayer layer];
    _verticalLine1.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _verticalLine2 = [CALayer layer];
    _verticalLine2.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    
    [_buttonsView.layer addSublayer:_horizontalLine];
    [_buttonsView.layer addSublayer:_verticalLine1];
    [_buttonsView.layer addSublayer:_verticalLine2];

    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [_tableView registerClass:UITableViewCell.class forCellReuseIdentifier:kCellReuseIdentifier];
    [_tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:kHeaderId];
    
    _routeStatsController = [[OARouteStatisticsViewController alloc] init];
//    [self addSubview:_routeStatsController.view];
//    _routeStatsController.view.hidden = YES;
    
    self.layer.cornerRadius = 9.;
    self.sliderView.layer.cornerRadius = 3.;
    self.contentContainer.layer.cornerRadius = 9.;
    
    _appModeView = [NSBundle.mainBundle loadNibNamed:@"OAAppModeView" owner:nil options:nil].firstObject;
    _appModeView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [_appModeViewContainer addSubview:_appModeView];
    _appModeView.showDefault = NO;
    _appModeView.delegate = self;
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDragged:)];
    _panGesture.maximumNumberOfTouches = 1;
    _panGesture.minimumNumberOfTouches = 1;
    [self addGestureRecognizer:_panGesture];
    _panGesture.delegate = self;
    _currentState = EOARouteInfoMenuStateInitial;
    
    [self setupButtonLayout:_swapButton];
    [self setupButtonLayout:_addDestinationButton];
    [self setupButtonLayout:_editButton];
}

- (void) commonInit
{
    _app = [OsmAndApp instance];
    _pointsHelper = [OATargetPointsHelper sharedInstance];
    _routingHelper = [OARoutingHelper sharedInstance];

    [_routingHelper addListener:self];
    [_pointsHelper addListener:self];
    
    _prevRouteSection = -1;
    _gpxTripSection = -1;
    _mapMarkerSection = -1;
    _historySection = -1;
}

+ (int) getDirectionInfo
{
    return directionInfo;
}

+ (BOOL) isVisible
{
    return visible;
}

- (void)generateGpxSection:(NSMutableDictionary *)dictionary fullScreenDividerInsets:(const UIEdgeInsets &)fullScreenDividerInsets section:(NSMutableArray *)section sectionIndex:(int &)sectionIndex {
    
    OASelectedGPXHelper *helper = [OASelectedGPXHelper instance];
    OAGPXDatabase *dbHelper = [OAGPXDatabase sharedDb];
    NSMutableArray<OAGPX *> *visibleGpx = [NSMutableArray array];
    
    auto activeGpx = helper.activeGpx;
    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
    {
        OAGPX *gpx = [dbHelper getGPXItem:[it.key().toNSString() lastPathComponent]];
        if (gpx)
        {
            auto doc = it.value();
            if (doc->hasRtePt() || doc->hasTrkPt())
            {
                [visibleGpx addObject:gpx];
            }
        }
    }
    
    if(visibleGpx.count == 0)
        return;
    
    [section addObject:@{
        @"cell" : @"OADividerCell",
        @"insets" : NSStringFromUIEdgeInsets(fullScreenDividerInsets)
    }];
    
    UIEdgeInsets tripsInsets = UIEdgeInsetsMake(0., 62., 0., 0.);
    for (NSInteger i = 0; i < visibleGpx.count; i++)
    {
        OAGPX *gpx = visibleGpx[i];
        [section addObject:@{
            @"cell" : @"OAMultiIconTextDescCell",
            @"title" : gpx.getNiceTitle,
            @"descr" : [OAGPXUIHelper getDescription:gpx],
            @"img" : @"ic_custom_trip",
            @"item" : gpx
        }];
        if (i != visibleGpx.count - 1)
        {
            [section addObject:@{
                @"cell" : @"OADividerCell",
                @"insets" : NSStringFromUIEdgeInsets(tripsInsets)
            }];
        }
    }
    [section addObject:@{
        @"cell" : @"OADividerCell",
        @"insets" : NSStringFromUIEdgeInsets(fullScreenDividerInsets)
    }];
    _gpxTripSection = sectionIndex;
    [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
}

- (void) updateData
{
    int sectionIndex = 0;
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    NSMutableArray *section = [[NSMutableArray alloc] init];
    [section addObject:@{
        @"cell" : @"OARoutingTargetCell",
        @"type" : @"start"
    }];
    
    if ([self hasIntermediatePoints])
    {
        [section addObject:@{
            @"cell" : @"OARoutingTargetCell",
            @"type" : @"intermediate"
        }];
    }
    
    [section addObject:@{
        @"cell" : @"OARoutingTargetCell",
        @"type" : @"finish"
    }];
    
    [section addObject:@{
        @"cell" : @"OARoutingSettingsCell"
    }];
    [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
    
    UIEdgeInsets fullScreenDividerInsets = UIEdgeInsetsZero;
    
    if ([_routingHelper isRouteCalculated])
    {
        [section removeAllObjects];
        [section addObject:@{
            @"cell" : @"OADividerCell",
            @"insets" : NSStringFromUIEdgeInsets(fullScreenDividerInsets)
        }];
        [section addObject:@{
            @"cell" : @"OARoutingInfoCell"
        }];
        [section addObject:@{
            @"cell" : kCellReuseIdentifier
        }];
        [section addObject:@{
            @"cell" : @"OADividerCell",
            @"insets" : NSStringFromUIEdgeInsets(fullScreenDividerInsets)
        }];
        [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
        
        [_routeStatsController refreshLineChartWithAnalysis:_routingHelper.getTrackAnalysis];
        _currentState = EOARouteInfoMenuStateExpanded;
    }
    else if (![_routingHelper isRouteBeingCalculated])
    {
        [section removeAllObjects];
        [section addObject:@{
            @"cell" : @"OADividerCell",
            @"insets" : NSStringFromUIEdgeInsets(fullScreenDividerInsets)
        }];
        [section addObject:@{
            @"cell" : @"OAHomeWorkCell"
        }];
        [section addObject:@{
            @"cell" : @"OADividerCell",
            @"insets" : NSStringFromUIEdgeInsets(fullScreenDividerInsets)
        }];
        [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
        
        [section removeAllObjects];
        
        OARTargetPoint *startBackup = _app.data.pointToStartBackup;
        OARTargetPoint *destinationBackup = _app.data.pointToNavigateBackup;
        if (destinationBackup != nil)
        {
            [section addObject:@{
                @"cell" : @"OADividerCell",
                @"insets" : NSStringFromUIEdgeInsets(fullScreenDividerInsets)
            }];
            
            [section addObject:@{
                @"cell" : @"OADescrTitleIconCell",
                @"title" : destinationBackup.pointDescription.name,
                @"descr" : startBackup ? startBackup.pointDescription.name : OALocalizedString(@"shared_string_my_location"),
                @"img" : @"ic_custom_point_to_point",
                @"key" : @"prev_route"
            }];
            
            [section addObject:@{
                @"cell" : @"OADividerCell",
                @"insets" : NSStringFromUIEdgeInsets(fullScreenDividerInsets)
            }];
            _prevRouteSection = sectionIndex;
            [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
            [section removeAllObjects];
        }
        
        [self generateGpxSection:dictionary fullScreenDividerInsets:fullScreenDividerInsets section:section sectionIndex:sectionIndex];
        
        
    }
    _data = [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[@(indexPath.section)][indexPath.row];
}

- (void) layoutSubviews
{
    if (_isDragging)
        return;
    [super layoutSubviews];
    
    [self adjustFrame];
    
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    if ([self isLandscape])
    {
        if (!self.tableView.tableHeaderView)
            self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 20)];
        
        if (mapPanel.mapViewController.mapPositionX != 1)
        {
            mapPanel.mapViewController.mapPositionX = 1;
            [mapPanel refreshMap];
        }
    }
    else
    {
        if (self.tableView.tableHeaderView)
            self.tableView.tableHeaderView = nil;

        if (mapPanel.mapViewController.mapPositionX != 0)
        {
            mapPanel.mapViewController.mapPositionX = 0;
            [mapPanel refreshMap];
        }
    }
    
    double lineBorder = 12.0;
    
    _horizontalLine.frame = CGRectMake(0.0, 0.0, _buttonsView.frame.size.width, 0.5);
    _verticalLine1.frame = CGRectMake(_waypointsButton.frame.origin.x - 0.5, lineBorder, 0.5, _waypointsButton.frame.size.height - lineBorder * 2);
    _verticalLine2.frame = CGRectMake(_settingsButton.frame.origin.x - 0.5, lineBorder, 0.5, _waypointsButton.frame.size.height - lineBorder * 2);
    
    NSString *goTitle = OALocalizedString(@"shared_string_go");
    
    CGFloat border = 6.0;
    CGFloat imgWidth = 30.0;
    CGFloat minTextWidth = 100.0;
    CGFloat maxTextWidth = self.frame.size.width - _settingsButton.frame.origin.x - border * 2 - imgWidth - 16.0;
    
    UIFont *font = _goButton.titleLabel.font;
    CGFloat w = MAX(MIN([OAUtilities calculateTextBounds:goTitle width:1000.0 font:font].width + 16.0, maxTextWidth), minTextWidth) + imgWidth;
    
    [_goButton setTitle:goTitle forState:UIControlStateNormal];
    _goButton.frame = CGRectMake(_buttonsView.frame.size.width - w - border, border, w, _buttonsView.frame.size.height - [OAUtilities getBottomMargin] - border * 2);
    
    CGRect sliderFrame = _sliderView.frame;
    sliderFrame.origin.x = self.bounds.size.width / 2 - sliderFrame.size.width / 2;
    _sliderView.frame = sliderFrame;
    
    CGRect buttonsFrame = _buttonsView.frame;
    buttonsFrame.size.width = self.bounds.size.width;
    _buttonsView.frame = buttonsFrame;
    
    CGRect contentFrame = _contentContainer.frame;
    contentFrame.size.width = self.bounds.size.width;
    _contentContainer.frame = contentFrame;
    
    if (![self hasIntermediatePoints])
    {
        if ([self isLandscape])
        {
            CGRect sf = _controlButtonsContainer.frame;
            sf.origin.y = 70;
            _controlButtonsContainer.frame = sf;
        }
        else
        {
            CGRect swapBtnFrame = _swapButton.frame;
            swapBtnFrame.origin = CGPointMake(1.0, 9.0);
            _swapButton.frame = swapBtnFrame;
            
            CGRect addDestFrame = _addDestinationButton.frame;
            addDestFrame.origin = CGPointMake(1.0, CGRectGetMaxY(swapBtnFrame) + 18.0);
            _addDestinationButton.frame = addDestFrame;
            
            CGRect sf = _controlButtonsContainer.frame;
            sf.origin.y = _tableView.frame.origin.y;
            sf.size.height = [self tableView:_tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] * 2;
            _controlButtonsContainer.frame = sf;
        }
        _editButton.hidden = YES;
    }
    else
    {
        CGRect swapBtnFrame = _swapButton.frame;
        swapBtnFrame.origin = CGPointMake(1.0, 9.0);
        _swapButton.frame = swapBtnFrame;
        
        CGRect editBtnFrame = _editButton.frame;
        editBtnFrame.origin = CGPointMake(1.0, CGRectGetMaxY(swapBtnFrame) + 18.0);
        _editButton.frame = editBtnFrame;
        
        CGRect addDestFrame = _addDestinationButton.frame;
        addDestFrame.origin = CGPointMake(1.0, CGRectGetMaxY(editBtnFrame) + 18.0);
        _addDestinationButton.frame = addDestFrame;
        
        CGRect sf = _controlButtonsContainer.frame;
        sf.origin.y = _tableView.frame.origin.y;
        sf.size.height = [self tableView:_tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] * 3;
        _controlButtonsContainer.frame = sf;
        
        _editButton.hidden = NO;
    }
}

- (void) adjustFrame
{
    CGRect f = self.frame;
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    if ([self isLandscape])
    {
        f.origin = CGPointZero;
        f.size.height = DeviceScreenHeight;
        f.size.width = kInfoViewLanscapeWidth;
        if (bottomMargin > 0)
        {
            CGRect buttonsFrame = _buttonsView.frame;
            buttonsFrame.origin.y = f.size.height - 50 - bottomMargin;
            buttonsFrame.size.height = 50 + bottomMargin;
            _buttonsView.frame = buttonsFrame;
        }
    }
    else
    {
        CGRect buttonsFrame = _buttonsView.frame;
        buttonsFrame.size.height = 50 + bottomMargin;
        f.size.height = [self getViewHeight];
        f.size.width = DeviceScreenWidth;
        f.origin = CGPointMake(0, DeviceScreenHeight - f.size.height);
        if (bottomMargin > 0)
        {
            buttonsFrame.origin.y = f.size.height - buttonsFrame.size.height;
            _buttonsView.frame = buttonsFrame;
        }
        CGRect contentFrame = _contentContainer.frame;
        contentFrame.size.height = f.size.height - buttonsFrame.size.height;
        contentFrame.origin = CGPointZero;
        _contentContainer.frame = contentFrame;
    }
    self.frame = f;
}

- (CGFloat) getViewHeight
{
    switch (_currentState) {
        case EOARouteInfoMenuStateInitial:
            return 170.0 + ([self hasIntermediatePoints] ? 60.0 : 0.0) + _buttonsView.frame.size.height + _tableView.frame.origin.y;
        case EOARouteInfoMenuStateExpanded:
            return DeviceScreenHeight - DeviceScreenHeight / 4;
        case EOARouteInfoMenuStateFullScreen:
            return DeviceScreenHeight - OAUtilities.getStatusBarHeight;
        default:
            return 0.0;
    }
}

- (void) setupButtonLayout:(UIButton *)button
{
    button.layer.cornerRadius = 42 / 2;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = UIColorFromRGB(color_bottom_sheet_secondary).CGColor;
}

- (CGPoint) calculateInitialPoint
{
    return CGPointMake(0., DeviceScreenHeight - [self getViewHeight]);
}

- (IBAction) closePressed:(id)sender
{
    [[OARootViewController instance].mapPanel stopNavigation];
}

- (IBAction) waypointsPressed:(id)sender
{
    [[OARootViewController instance].mapPanel showWaypoints];
}

- (IBAction) settingsPressed:(id)sender
{
    [[OARootViewController instance].mapPanel showRoutePreferences];
}

- (IBAction) goPressed:(id)sender
{
    if ([_pointsHelper getPointToNavigate])
        [[OARootViewController instance].mapPanel closeRouteInfo];
    
    [[OARootViewController instance].mapPanel startNavigation];
}

- (IBAction) swapPressed:(id)sender
{
    [self switchStartAndFinish];
}

- (IBAction)editDestinationsPressed:(id)sender
{
    [self waypointsPressed:nil];
}

- (IBAction)addDestinationPressed:(id)sender
{
    BOOL isIntermediate = [_pointsHelper getPointToNavigate] != nil;
    OAAddDestinationBottomSheetViewController *addDest = [[OAAddDestinationBottomSheetViewController alloc] initWithType:isIntermediate ? EOADestinationTypeIntermediate : EOADestinationTypeFinish];
    addDest.delegate = self;
    [addDest show];
}

- (void) switchStartAndFinish
{
    OARTargetPoint *start = [_pointsHelper getPointToStart];
    OARTargetPoint *finish = [_pointsHelper getPointToNavigate];

    if (finish)
    {
        [_pointsHelper setStartPoint:[[CLLocation alloc] initWithLatitude:[finish getLatitude] longitude:[finish getLongitude]] updateRoute:NO name:[finish getPointDescription]];
        
        if (!start)
        {
            CLLocation *loc = _app.locationServices.lastKnownLocation;
            if (loc)
                [_pointsHelper navigateToPoint:loc updateRoute:YES intermediate:-1];
        }
        else
        {
            [_pointsHelper navigateToPoint:[[CLLocation alloc] initWithLatitude:[start getLatitude] longitude:[start getLongitude]] updateRoute:YES intermediate:-1 historyName:[start getPointDescription]];
        }

        [self show:NO onComplete:nil];
    }
}

- (BOOL) hasIntermediatePoints
{
    return [_pointsHelper getIntermediatePoints]  && [_pointsHelper getIntermediatePoints].count > 0;
}

- (NSString *) getRoutePointDescription:(double)lat lon:(double)lon
{
    return [NSString stringWithFormat:@"%@ %.3f %@ %.3f", OALocalizedString(@"Lat"), lat, OALocalizedString(@"Lon"), lon];
}

- (BOOL) isLandscape
{
    return OAUtilities.isLandscape;
}

- (void) show:(BOOL)animated onComplete:(void (^)(void))onComplete
{
    visible = YES;
    _currentState = EOARouteInfoMenuStateFullScreen;
    
    [self updateData];
    [self setNeedsLayout];
    [self adjustFrame];
    [self.tableView reloadData];
    
    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    [mapPanel setTopControlsVisible:NO customStatusBarStyle:isNight ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
    [mapPanel setBottomControlsVisible:NO menuHeight:0 animated:YES];

    _switched = [mapPanel switchToRoutePlanningLayout];
    if (animated)
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
        {
            frame.origin.x = -self.bounds.size.width;
            frame.origin.y = 0.0;
            frame.size.width = kInfoViewLanscapeWidth;
            self.frame = frame;
            
            frame.origin.x = 0.0;
        }
        else
        {
            frame.origin.x = 0.0;
            frame.origin.y = DeviceScreenHeight + 10.0;
            frame.size.width = DeviceScreenWidth;
            self.frame = frame;
            
            frame.origin.y = DeviceScreenHeight - self.bounds.size.height;
        }
        
        [UIView animateWithDuration:0.3 animations:^{
            
            self.frame = frame;
            
        } completion:^(BOOL finished) {
            if (onComplete)
                onComplete();
        }];
    }
    else
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
            frame.origin.y = 0.0;
        else
            frame.origin.y = DeviceScreenHeight - self.bounds.size.height;
        
        self.frame = frame;
        
        if (onComplete)
            onComplete();
    }
    _appModeView.selectedMode = [_routingHelper getAppMode];
}

- (void) hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    visible = NO;
    
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    [mapPanel setTopControlsVisible:YES];
    [mapPanel setBottomControlsVisible:YES menuHeight:0 animated:YES];

    if (self.superview)
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
            frame.origin.x = -frame.size.width;
        else
            frame.origin.y = DeviceScreenHeight + 10.0;
        
        if (animated && duration > 0.0)
        {
            [UIView animateWithDuration:duration animations:^{
                
                self.frame = frame;
                
            } completion:^(BOOL finished) {
                
                [self removeFromSuperview];
                
                [self onDismiss];
                
                if (onComplete)
                    onComplete();
            }];
        }
        else
        {
            self.frame = frame;
            
            [self removeFromSuperview];
            
            [self onDismiss];

            if (onComplete)
                onComplete();
        }
    }
}

- (BOOL) isSelectingTargetOnMap
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    OATargetPointType activeTargetType = mapPanel.activeTargetType;
    return mapPanel.activeTargetActive && (activeTargetType == OATargetRouteStartSelection || activeTargetType == OATargetRouteFinishSelection || activeTargetType == OATargetRouteIntermediateSelection || activeTargetType == OATargetImpassableRoadSelection || activeTargetType == OATargetHomeSelection || activeTargetType == OATargetWorkSelection);
}

- (void) onDismiss
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    mapPanel.mapViewController.mapPositionX = 0;
    [mapPanel refreshMap];

    if (_switched)
        [mapPanel switchToRouteFollowingLayout];
    
    if (![_pointsHelper getPointToNavigate] && ![self isSelectingTargetOnMap])
        [mapPanel.mapActions stopNavigationWithoutConfirm];
}

- (void) addWaypoint
{
    // not implemented
}

- (void) update
{
    [self.tableView reloadData];
}

- (void) updateMenu
{
    if ([self superview])
        [self show:NO onComplete:nil];
}

#pragma mark - OAAppModeCellDelegate

- (void) appModeChanged:(OAApplicationMode *)next
{
    OAApplicationMode *am = [_routingHelper getAppMode];
    OAApplicationMode *appMode = [OAAppSettings sharedManager].applicationMode;
    if ([_routingHelper isFollowingMode] && appMode == am)
        [OAAppSettings sharedManager].applicationMode = next;

    [_routingHelper setAppMode:next];
    [_app initVoiceCommandPlayer:next warningNoneProvider:YES showDialog:NO force:NO];
    [_routingHelper recalculateRouteDueToSettingsChange];
}

#pragma mark - OARouteInformationListener

- (void) newRouteIsCalculated:(BOOL)newRoute
{
    dispatch_async(dispatch_get_main_queue(), ^{
        directionInfo = -1;
        [self updateMenu];
    });
}

- (void) routeWasUpdated
{
}

- (void) routeWasCancelled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        directionInfo = -1;
        // do not hide fragment (needed for use case entering Planning mode without destination)
    });
}

- (void) routeWasFinished
{
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"cell"] isEqualToString:@"OARoutingTargetCell"] && [item[@"type"] isEqualToString:@"start"])
    {
        static NSString* const reusableIdentifierPoint = item[@"cell"];
        
        OARoutingTargetCell* cell;
        cell = (OARoutingTargetCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:reusableIdentifierPoint owner:self options:nil];
            cell = (OARoutingTargetCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.finishPoint = NO;
            OARTargetPoint *point = [_pointsHelper getPointToStart];
            cell.titleLabel.text = OALocalizedString(@"route_from");
            if (point)
            {
                [cell.imgView setImage:[UIImage imageNamed:@"ic_list_startpoint"]];
                NSString *oname = [point getOnlyName].length > 0 ? [point getOnlyName] : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"map_settings_map"), [self getRoutePointDescription:[point getLatitude] lon:[point getLongitude]]];
                cell.addressLabel.text = oname;
            }
            else
            {
                [cell.imgView setImage:[UIImage imageNamed:@"ic_action_location_color"]];
                cell.addressLabel.text = OALocalizedString(@"shared_string_my_location");
            }
        }
        return cell;
    }
    if ([item[@"cell"] isEqualToString:@"OARoutingTargetCell"] && [item[@"type"] isEqualToString:@"finish"])
    {
        static NSString* const reusableIdentifierPoint = item[@"cell"];
        
        OARoutingTargetCell* cell;
        cell = (OARoutingTargetCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:reusableIdentifierPoint owner:self options:nil];
            cell = (OARoutingTargetCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.finishPoint = YES;
            OARTargetPoint *point = [_pointsHelper getPointToNavigate];
            [cell.imgView setImage:[UIImage imageNamed:@"ic_list_destination"]];
            cell.titleLabel.text = OALocalizedString(@"route_to");
            if (point)
            {
                NSString *oname = [point getOnlyName];
                cell.addressLabel.text = oname;
            }
            else
            {
                cell.addressLabel.text = OALocalizedString(@"route_descr_select_destination");
            }
            [cell setDividerVisibility:YES];
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:@"OARoutingTargetCell"] && [item[@"type"] isEqualToString:@"intermediate"])
    {
        static NSString* const reusableIdentifierPoint = item[@"cell"];
        
        OARoutingTargetCell* cell;
        cell = (OARoutingTargetCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:reusableIdentifierPoint owner:self options:nil];
            cell = (OARoutingTargetCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.finishPoint = NO;
            NSArray<OARTargetPoint *> *points = [_pointsHelper getIntermediatePoints];
            NSMutableString *via = [NSMutableString string];
            for (OARTargetPoint *point in points)
            {
                if (via.length > 0)
                    [via appendString:@" "];
                
                NSString *description = [point getOnlyName];
                [via appendString:description];
            }
            [cell.imgView setImage:[UIImage imageNamed:@"list_intermediate"]];
            cell.titleLabel.text = OALocalizedString(@"route_via");
            cell.addressLabel.text = via;
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:@"OARoutingInfoCell"])
    {
        static NSString* const reusableIdentifierPoint = item[@"cell"];
        
        OARoutingInfoCell* cell;
        cell = (OARoutingInfoCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:reusableIdentifierPoint owner:self options:nil];
            cell = (OARoutingInfoCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.directionInfo = directionInfo;
            [cell updateControls];
            cell.distanceTitleLabel.text = OALocalizedString(@"shared_string_distance");
            cell.timeTitleLabel.text = OALocalizedString(@"shared_string_time");
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:kCellReuseIdentifier])
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellReuseIdentifier];
        }
        
        if (cell && cell.contentView.subviews.count == 0)
        {
            _routeStatsController.view.frame = cell.contentView.bounds;
            _routeStatsController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [cell.contentView addSubview:_routeStatsController.view];
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:@"OARoutingSettingsCell"])
    {
        static NSString* const reusableIdentifierPoint = item[@"cell"];
        
        OARoutingSettingsCell* cell;
        cell = (OARoutingSettingsCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:reusableIdentifierPoint owner:self options:nil];
            cell = (OARoutingSettingsCell *)[nib objectAtIndex:0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:@"OAHomeWorkCell"])
    {
        static NSString* const reusableIdentifierPoint = item[@"cell"];
        
        OAHomeWorkCell *cell;
        cell = (OAHomeWorkCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:reusableIdentifierPoint owner:self options:nil];
            cell = (OAHomeWorkCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.delegate = self;
            [cell generateData];
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:@"OAMultiIconTextDescCell"])
    {
        static NSString* const reusableIdentifierPoint = item[@"cell"];
        
        OAMultiIconTextDescCell* cell;
        cell = (OAMultiIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:reusableIdentifierPoint owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText:item[@"title"]];
            [cell.descView setText:item[@"descr"]];
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
            [cell setOverflowVisibility:YES];
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:@"OADividerCell"])
    {
        static NSString* const identifierCell = @"OADividerCell";
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADividerCell" owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.whiteColor;
            cell.dividerColor = UIColorFromRGB(color_divider_blur);
            cell.dividerInsets = UIEdgeInsetsFromString(item[@"insets"]);
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:@"OADescrTitleIconCell"])
    {
        static NSString* const reusableIdentifierPoint = item[@"cell"];
        
        OADescrTitleIconCell* cell;
        cell = (OADescrTitleIconCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:reusableIdentifierPoint owner:self options:nil];
            cell = (OADescrTitleIconCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText:item[@"title"]];
            [cell.descView setText:item[@"descr"]];
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
        }
        return cell;
    }
    return nil;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"cell"] isEqualToString:@"OARoutingSettingsCell"])
        return nil;
    return indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:@"start"])
    {
        OAAddDestinationBottomSheetViewController *addDest = [[OAAddDestinationBottomSheetViewController alloc] initWithType:EOADestinationTypeStart];
        addDest.delegate = self;
        [addDest show];
    }
    else if ([item[@"type"] isEqualToString:@"finish"])
    {
        OAAddDestinationBottomSheetViewController *addDest = [[OAAddDestinationBottomSheetViewController alloc] initWithType:EOADestinationTypeFinish];
        addDest.delegate = self;
        [addDest show];
    }
    else if ([item[@"type"] isEqualToString:@"intermediate"])
    {
        [self waypointsPressed:nil];
    }
    else if ([item[@"key"] isEqualToString:@"prev_route"])
    {
        [_pointsHelper restoreTargetPoints:YES];
    }
    else if ([item[@"cell"] isEqualToString:@"OAMultiIconTextDescCell"])
    {
        OAGPX *gpx = item[@"item"];
        if (gpx)
        {
            [[OARootViewController instance].mapPanel.mapActions setGPXRouteParams:gpx];
            [_routingHelper recalculateRouteDueToSettingsChange];
            [[OATargetPointsHelper sharedInstance] updateRouteAndRefresh:YES];
            
        }
    }
}

#pragma mark - OAWaypointSelectionDialogDelegate

- (void) waypointSelectionDialogComplete:(BOOL)selectionDone showMap:(BOOL)showMap calculatingRoute:(BOOL)calculatingRoute
{
    if (selectionDone)
    {
        [self updateData];
        [self.tableView reloadData];
        [self layoutSubviews];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.allKeys.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[@(section)].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"cell"] isEqualToString:@"OARoutingTargetCell"] || [item[@"cell"] isEqualToString:@"OAHomeWorkCell"])
        return 60.0;
    else if ([item[@"cell"] isEqualToString:kCellReuseIdentifier])
        return 150.0;
    else if ([item[@"cell"] isEqualToString:@"OARoutingSettingsCell"])
        return 50.0;
    else if ([item[@"cell"] isEqualToString:@"OAMultiIconTextDescCell"])
        return [OAMultiIconTextDescCell getHeight:item[@"title"] value:item[@"descr"] cellWidth:tableView.bounds.size.width];
    else if ([item[@"cell"] isEqualToString:@"OADividerCell"])
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsFromString(item[@"insets"])];
    else if ([item[@"cell"] isEqualToString:@"OADescrTitleIconCell"])
        return [OADescrTitleIconCell getHeight:item[@"title"] value:item[@"descr"] cellWidth:tableView.bounds.size.width];
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self getTitleForSection:section];
    if (section == 0)
        return 0.01;
    else if (!title)
        return 13.0;
    else
        return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self getTitleForSection:section];
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderId];
    
    if (!title)
    {
        vw.label.text = title;
        return vw;
    }
    
    vw.label.text = [title upperCase];
    return vw;
}

- (NSString *) getTitleForSection:(NSInteger) section
{
    if ([_routingHelper isRouteCalculated])
        return nil;
    
    if (section == _prevRouteSection)
        return OALocalizedString(@"prev_route");
    else if (section == _gpxTripSection)
        return OALocalizedString(@"displayed_trips");
    else if (section == _mapMarkerSection)
        return OALocalizedString(@"map_markers");
    else if (section == _historySection)
        return OALocalizedString(@"history");
        
    return nil;
}


#pragma mark - UIGestureRecognizerDelegate

- (void) onDragged:(UIPanGestureRecognizer *)recognizer
{
    CGFloat velocity = [recognizer velocityInView:self.superview].y;
    BOOL slidingDown = velocity > 0;
    BOOL fastUpSlide = velocity < -1500.;
    BOOL fastDownSlide = velocity > 1500.;
    CGPoint touchPoint = [recognizer locationInView:self.superview];
    CGPoint initialPoint = [self calculateInitialPoint];
    
    CGFloat expandedAnchor = DeviceScreenHeight / 4 + 40.;
    CGFloat fullScreenAnchor = OAUtilities.getStatusBarHeight + 40.;
    
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            _isDragging = YES;
        case UIGestureRecognizerStateChanged:
        {
            if (DeviceScreenHeight - touchPoint.y < _buttonsView.frame.size.height)
                return;
            
            CGRect frame = self.frame;
            frame.size.height = DeviceScreenHeight - touchPoint.y;
            frame.origin.y = frame.origin.y = touchPoint.y;
            self.frame = frame;
            
            CGRect buttonsFrame = _buttonsView.frame;
            buttonsFrame.origin.y = frame.size.height - buttonsFrame.size.height;
            _buttonsView.frame = buttonsFrame;
            
            CGRect contentFrame = _contentContainer.frame;
            contentFrame.size.height = frame.size.height - buttonsFrame.size.height;
            _contentContainer.frame = contentFrame;
            return;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            _isDragging = NO;
            BOOL shouldRefresh = NO;
            if (touchPoint.y - initialPoint.y > 200 && _currentState == EOARouteInfoMenuStateInitial)
            {
                [self closePressed:nil];
                break;
            }
            else if (touchPoint.y < fullScreenAnchor || (!slidingDown && _currentState == EOARouteInfoMenuStateExpanded) || fastUpSlide)
            {
                _currentState = EOARouteInfoMenuStateFullScreen;
            }
            else if ((touchPoint.y < expandedAnchor || (touchPoint.y > expandedAnchor && !slidingDown)) && !fastDownSlide)
            {
                shouldRefresh = YES;
                _currentState = EOARouteInfoMenuStateExpanded;
            }
            else
            {
                shouldRefresh = YES;
                _currentState = EOARouteInfoMenuStateInitial;
            }
            if (shouldRefresh)
            {
               // TODO center map
            }
            
            [UIView animateWithDuration: 0.2 animations:^{
                [self layoutSubviews];
            }];
        }
        default:
        {
            break;
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ![self isLandscape];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

#pragma mark - OAHomeWorkCellDelegate

- (void)onItemSelected:(NSDictionary *)item
{
    [self onItemSelected:item overrideExisting:NO];
}

- (void) onItemSelected:(NSDictionary *)item overrideExisting:(BOOL)overrideExisting
{
    BOOL isHome = [item[@"key"] isEqualToString:@"home"];
    OARTargetPoint *point = isHome ? _app.data.homePoint : _app.data.workPoint;
    
    if (point && !overrideExisting)
    {
        [_pointsHelper navigateToPoint:point.point updateRoute:YES intermediate:-1 historyName:point.pointDescription];
    }
    else
    {
        OAAddDestinationBottomSheetViewController *addDest = [[OAAddDestinationBottomSheetViewController alloc] initWithType:isHome ? EOADestinationTypeHome : EOADestinationTypeWork];
        addDest.delegate = self;
        [addDest show];
    }
}

#pragma mark - OAStateChangedListener

- (void)stateChanged:(id)change
{
    [self updateData];
    [self.tableView reloadData];
}

@end
