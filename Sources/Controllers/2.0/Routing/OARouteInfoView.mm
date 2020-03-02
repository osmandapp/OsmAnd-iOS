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
#import "OALineChartCell.h"
#import "OARTargetPoint.h"
#import "OAPointDescription.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "PXAlertView.h"
#import "OsmAndApp.h"
#import "OACommonTypes.h"
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
#import "OASizes.h"
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
#import "OAHistoryHelper.h"
#import "OAButtonCell.h"
#import "OARouteProgressBarCell.h"
#import "OARouteStatisticsHelper.h"
#import "OAFilledButtonCell.h"

#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>

#define kHistoryItemLimitDefault 3

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

@interface OARouteInfoView ()<OARouteInformationListener, OAAppModeCellDelegate, OAWaypointSelectionDelegate, OAHomeWorkCellDelegate, OAStateChangedListener, UIGestureRecognizerDelegate, OARouteCalculationProgressCallback>

@end

@implementation OARouteInfoView
{
    OATargetPointsHelper *_pointsHelper;
    OARoutingHelper *_routingHelper;
    OsmAndAppInstance _app;
    
    NSDictionary<NSNumber *, NSArray *> *_data;
    
    CALayer *_horizontalLine;
    
    BOOL _switched;
    
    OAAppModeView *_appModeView;
    
    UIPanGestureRecognizer *_panGesture;
    EOARouteInfoMenuState _currentState;
    
    BOOL _isDragging;
    BOOL _isHiding;
    BOOL _topOverScroll;
    CGFloat _initialTouchPoint;
    
    NSInteger _prevRouteSection;
    NSInteger _gpxTripSection;
    NSInteger _mapMarkerSection;
    NSInteger _historySection;
    
    int _historyItemsLimit;
    
    OALineChartCell *_routeStatsCell;
    UIProgressView *_progressBarView;
    
    OAGPXTrackAnalysis *_trackAnalysis;
    OAGPXDocument *_gpx;
    BOOL _needChartUpdate;
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
    [_buttonsView.layer addSublayer:_horizontalLine];

    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [_tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:kHeaderId];
    [_tableView setShowsVerticalScrollIndicator:NO];
    [_tableView setShowsHorizontalScrollIndicator:NO];
    _tableView.estimatedRowHeight = kEstimatedRowHeight;
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OALineChartCell" owner:self options:nil];
    _routeStatsCell = (OALineChartCell *)[nib objectAtIndex:0];
    
    self.sliderView.layer.cornerRadius = 2.;
    
    _appModeView = [NSBundle.mainBundle loadNibNamed:@"OAAppModeView" owner:nil options:nil].firstObject;
    _appModeView.frame = CGRectMake(0., 0., _appModeViewContainer.frame.size.width, _appModeViewContainer.frame.size.height);
    _appModeView.showDefault = NO;
    _appModeView.delegate = self;
    [_appModeViewContainer addSubview:_appModeView];
    
    _appModeViewContainer.layer.shadowColor = UIColor.blackColor.CGColor;
    _appModeViewContainer.layer.shadowOpacity = 0.0;
    _appModeViewContainer.layer.shadowRadius = 2.0;
    _appModeViewContainer.layer.shadowOffset = CGSizeMake(0.0, 3.0);
    _appModeViewContainer.layer.masksToBounds = NO;
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDragged:)];
    _panGesture.maximumNumberOfTouches = 1;
    _panGesture.minimumNumberOfTouches = 1;
    [self addGestureRecognizer:_panGesture];
    _panGesture.delegate = self;
    _currentState = EOARouteInfoMenuStateInitial;
    
    [_cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [_goButton setTitle:OALocalizedString(@"gpx_start") forState:UIControlStateNormal];
    
    _cancelButton.layer.cornerRadius = 9.;
    _goButton.layer.cornerRadius = 9.;
    
    [_goButton setImage:[[UIImage imageNamed:@"ic_custom_navigation_arrow"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self setupGoButton];
}

- (void) applyCornerRadius:(BOOL)enable
{
    CGFloat value = enable ? 9. : 0.;
    self.layer.cornerRadius = value;
    self.contentContainer.layer.cornerRadius = value;
}

- (void) setupGoButton
{
    BOOL isActive = _app.data.pointToNavigate != nil;
    _goButton.backgroundColor = isActive ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_route_button_inactive);
    [_goButton setTintColor:isActive ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [_goButton setTitleColor:isActive ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
    [_goButton.imageView setTintColor:_goButton.tintColor];
    
    _goButton.userInteractionEnabled = isActive;
}

- (void) setupModeViewShadowVisibility
{
    BOOL shouldShow = _tableView.contentOffset.y > 0 && self.frame.origin.y == 0;
    _appModeViewContainer.layer.shadowOpacity = shouldShow ? 0.15 : 0.0;
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
    
    _historyItemsLimit = kHistoryItemLimitDefault;
    
    [_routingHelper addProgressBar:self];
}

+ (int) getDirectionInfo
{
    return directionInfo;
}

+ (BOOL) isVisible
{
    return visible;
}

- (void)generateGpxSection:(NSMutableDictionary *)dictionary section:(NSMutableArray *)section sectionIndex:(int &)sectionIndex {
    
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
            if (doc != nullptr && (doc->hasRtePt() || doc->hasTrkPt()))
            {
                [visibleGpx addObject:gpx];
            }
        }
    }
    
    if(visibleGpx.count == 0)
        return;
    
    [section addObject:@{
        @"cell" : @"OADividerCell",
        @"custom_insets" : @(NO)
    }];
    
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
                @"custom_insets" : @(YES)
            }];
        }
    }
    [section addObject:@{
        @"cell" : @"OADividerCell",
        @"custom_insets" : @(NO)
    }];
    _gpxTripSection = sectionIndex;
    [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
    [section removeAllObjects];
}

- (void)generatePrevRouteSection:(NSMutableDictionary *)dictionary section:(NSMutableArray *)section sectionIndex:(int &)sectionIndex {
    OARTargetPoint *startBackup = _app.data.pointToStartBackup;
    OARTargetPoint *destinationBackup = _app.data.pointToNavigateBackup;
    if (destinationBackup != nil)
    {
        [section addObject:@{
            @"cell" : @"OADividerCell",
            @"custom_insets" : @(NO)
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
            @"custom_insets" : @(NO)
        }];
        _prevRouteSection = sectionIndex;
        [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
        [section removeAllObjects];
    }
}

- (void)generateMrkersSection:(NSMutableDictionary *)dictionary section:(NSMutableArray *)section sectionIndex:(int &)sectionIndex {
    NSArray *markers = [[OADestinationsHelper instance] sortedDestinationsWithoutParking];
    if (markers.count > 0)
    {
        [section addObject:@{
            @"cell" : @"OADividerCell",
            @"custom_insets" : @(NO)
        }];
        for (NSInteger i = 0; i < markers.count; i++)
        {
            OADestination *item = markers[i];
            [section addObject:@{
                @"cell" : @"OAMultiIconTextDescCell",
                @"title" : item.desc,
                @"img" : [item.markerResourceName ? item.markerResourceName : @"ic_destination_pin_1" stringByAppendingString:@"_small"],
                @"item" : item
            }];
            if (i != markers.count - 1)
            {
                [section addObject:@{
                    @"cell" : @"OADividerCell",
                    @"custom_insets" : @(YES)
                }];
            }
        }
        [section addObject:@{
            @"cell" : @"OADividerCell",
            @"custom_insets" : @(NO)
        }];
        _mapMarkerSection = sectionIndex;
        [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
        [section removeAllObjects];
    }
}

- (void)generateHistorySection:(NSMutableDictionary *)dictionary section:(NSMutableArray *)section sectionIndex:(int &)sectionIndex {
    OAHistoryHelper *helper = [OAHistoryHelper sharedInstance];
    NSArray *allItems = [helper getPointsHavingTypes:helper.searchTypes limit:_historyItemsLimit];
    if (allItems.count > 0)
    {
        [section addObject:@{
            @"cell" : @"OADividerCell",
            @"custom_insets" : @(NO)
        }];
        for (OAHistoryItem *item in allItems)
        {
            [section addObject:@{
                @"cell" : @"OAMultiIconTextDescCell",
                @"title" : item.name,
                @"img" : @"ic_custom_history",
                @"item" : item
            }];
            
            [section addObject:@{
                @"cell" : @"OADividerCell",
                @"custom_insets" : @(YES)
            }];
            
        }
        if (allItems.count == _historyItemsLimit)
        {
            [section addObject:@{
                @"cell" : @"OAButtonCell",
                @"title" : OALocalizedString(@"shared_string_show_more")
            }];
        }
        else
        {
            [section removeObjectAtIndex:section.count - 1];
        }
        [section addObject:@{
            @"cell" : @"OADividerCell",
            @"custom_insets" : @(NO)
        }];
        _historySection = sectionIndex;
        [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
    }
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
    if (![_routingHelper isRouteCalculated] && [_routingHelper isRouteBeingCalculated])
    {
        [section addObject:@{
            @"cell" : @"OARouteProgressBarCell"
        }];
    }
    [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
    [section removeAllObjects];
    
    if ([_routingHelper isRouteCalculated])
    {
        [section addObject:@{
            @"cell" : @"OADividerCell",
            @"custom_insets" : @(NO)
        }];
        [section addObject:@{
            @"cell" : @"OARoutingInfoCell"
        }];
        [section addObject:@{
            @"cell" : kCellReuseIdentifier
        }];
        [section addObject:@{
            @"cell" : @"OAFilledButtonCell",
            @"title" : OALocalizedString(@"res_details")
        }];
        [section addObject:@{
            @"cell" : @"OADividerCell",
            @"custom_insets" : @(NO)
        }];
        [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
        
        OAGPXTrackAnalysis *trackAnalysis = [self getTrackAnalysis];
        if (_needChartUpdate)
        {
            [GpxUIHelper refreshLineChartWithChartView:_routeStatsCell.lineChartView analysis:trackAnalysis useGesturesAndScale:NO];
            _needChartUpdate = NO;
        }
        
        _currentState = EOARouteInfoMenuStateExpanded;
    }
    else if (![_routingHelper isRouteBeingCalculated])
    {
        [section addObject:@{
            @"cell" : @"OADividerCell",
            @"custom_insets" : @(NO)
        }];
        [section addObject:@{
            @"cell" : @"OAHomeWorkCell"
        }];
        [section addObject:@{
            @"cell" : @"OADividerCell",
            @"custom_insets" : @(NO)
        }];
        [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
        
        [section removeAllObjects];
        
        [self generatePrevRouteSection:dictionary section:section sectionIndex:sectionIndex];
        
        [self generateGpxSection:dictionary section:section sectionIndex:sectionIndex];
        
        [self generateMrkersSection:dictionary section:section sectionIndex:sectionIndex];
        
        [self generateHistorySection:dictionary section:section sectionIndex:sectionIndex];
    }
    _data = [NSDictionary dictionaryWithDictionary:dictionary];
    
    [self setupGoButton];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[@(indexPath.section)][indexPath.row];
}

- (void) layoutSubviews
{
    if (_isDragging || _isHiding)
        return;
    [super layoutSubviews];
    
    BOOL isLandscape = [self isLandscape];
    _currentState = isLandscape ? EOARouteInfoMenuStateFullScreen : _currentState;
    
    [self adjustFrame];
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    if (isLandscape)
    {
        if (mapPanel.mapViewController.mapPositionX != 1)
        {
            mapPanel.mapViewController.mapPositionX = 1;
            [mapPanel refreshMap];
        }
    }
    else
    {
        if (mapPanel.mapViewController.mapPositionX != 0)
        {
            mapPanel.mapViewController.mapPositionX = 0;
            [mapPanel refreshMap];
        }
    }
    
    BOOL isFullScreen = _currentState == EOARouteInfoMenuStateFullScreen;
    _statusBarBackgroundView.frame = isFullScreen ? CGRectMake(0., 0., DeviceScreenWidth, OAUtilities.getStatusBarHeight) : CGRectZero;
    
    CGRect sliderFrame = _sliderView.frame;
    sliderFrame.origin.x = self.bounds.size.width / 2 - sliderFrame.size.width / 2;
    _sliderView.frame = sliderFrame;
    
    CGRect buttonsFrame = _buttonsView.frame;
    buttonsFrame.size.width = self.bounds.size.width;
    _buttonsView.frame = buttonsFrame;
    
    CGRect contentFrame = _contentContainer.frame;
    contentFrame.size.width = self.bounds.size.width;
    contentFrame.origin.y = CGRectGetMaxY(_statusBarBackgroundView.frame);
    contentFrame.size.height -= contentFrame.origin.y;
    _contentContainer.frame = contentFrame;
    
    CGFloat width = buttonsFrame.size.width - OAUtilities.getLeftMargin * (isLandscape ? 1 : 2) - 32.;
    CGFloat buttonWidth = width / 2 - 8;
    
    _cancelButton.frame = CGRectMake(16. + OAUtilities.getLeftMargin, 9., buttonWidth, 42.);
    _goButton.frame = CGRectMake(CGRectGetMaxX(_cancelButton.frame) + 16., 9., buttonWidth, 42.);
    
    if ([_goButton isDirectionRTL])
    {
        _goButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _goButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 12);
        _goButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 11);
    }
    else
    {
        _goButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _goButton.contentEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 0);
        _goButton.titleEdgeInsets = UIEdgeInsetsMake(0, 11, 0, 0);
    }
    
    _horizontalLine.frame = CGRectMake(0.0, 0.0, _buttonsView.frame.size.width, 0.5);
    
    _sliderView.hidden = isLandscape;
    
    CGFloat tableViewY = CGRectGetMaxY(_appModeViewContainer.frame);
    _tableView.frame = CGRectMake(0., tableViewY, contentFrame.size.width, contentFrame.size.height - tableViewY);
    
    _appModeViewContainer.frame = CGRectMake(OAUtilities.getLeftMargin, _appModeViewContainer.frame.origin.y, contentFrame.size.width - OAUtilities.getLeftMargin, _appModeViewContainer.frame.size.height);
    
    _appModeView.frame = CGRectMake(0., 0., _appModeViewContainer.frame.size.width, _appModeViewContainer.frame.size.height);
    
    [self applyCornerRadius:!isLandscape && _currentState != EOARouteInfoMenuStateFullScreen];
}

- (void) adjustFrame
{
    CGRect f = self.frame;
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    if ([self isLandscape])
    {
        f.origin = CGPointZero;
        f.size.height = DeviceScreenHeight;
        f.size.width = OAUtilities.isIPad ? [self getViewWidthForPad] : DeviceScreenWidth * 0.45;
        
        CGRect buttonsFrame = _buttonsView.frame;
        buttonsFrame.origin.y = f.size.height - 60. - bottomMargin;
        buttonsFrame.size.height = 60. + bottomMargin;
        _buttonsView.frame = buttonsFrame;
        
        CGRect contentFrame = _contentContainer.frame;
        contentFrame.size.height = f.size.height - buttonsFrame.size.height;
        contentFrame.origin = CGPointZero;
        _contentContainer.frame = contentFrame;
    }
    else
    {
        CGRect buttonsFrame = _buttonsView.frame;
        buttonsFrame.size.height = 60. + bottomMargin;
        f.size.height = [self getViewHeight];
        f.size.width = DeviceScreenWidth;
        f.origin = CGPointMake(0, DeviceScreenHeight - f.size.height);
        
        buttonsFrame.origin.y = f.size.height - buttonsFrame.size.height;
        _buttonsView.frame = buttonsFrame;
        
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
            return 170.0 + ([self hasIntermediatePoints] ? 60.0 : 0.0) + _buttonsView.frame.size.height + _tableView.frame.origin.y + ([_routingHelper isRouteBeingCalculated] ? 2.0 : 0.0);
        case EOARouteInfoMenuStateExpanded:
            return DeviceScreenHeight - DeviceScreenHeight / 4;
        case EOARouteInfoMenuStateFullScreen:
            return DeviceScreenHeight;
        default:
            return 0.0;
    }
}

- (void) onHistoryButtonPressed:(id) sender
{
    _historyItemsLimit += 10;
    [self updateData];
    [self.tableView reloadData];
    [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_data[@(_historySection)].count - 1 inSection:_historySection] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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

- (IBAction) goPressed:(id)sender
{
    if ([_pointsHelper getPointToNavigate])
        [[OARootViewController instance].mapPanel closeRouteInfo];
    
    [[OARootViewController instance].mapPanel startNavigation];
}

- (void) swapPressed:(id)sender
{
    [self switchStartAndFinish];
}

- (void) editDestinationsPressed:(id)sender
{
    [[OARootViewController instance].mapPanel showWaypoints];
}

- (void) addDestinationPressed:(id)sender
{
    BOOL isIntermediate = [_pointsHelper getPointToNavigate] != nil;
    OAAddDestinationBottomSheetViewController *addDest = [[OAAddDestinationBottomSheetViewController alloc] initWithType:isIntermediate ? EOADestinationTypeIntermediate : EOADestinationTypeFinish];
    addDest.delegate = self;
    [addDest show];
}

- (void) openRouteDetails
{
    [[OARootViewController instance].mapPanel openTargetViewWithRouteDetails:_gpx analysis:_trackAnalysis];
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
    return (OAUtilities.isLandscape || OAUtilities.isIPad) && !OAUtilities.isWindowed;
}

- (CGFloat) getViewWidthForPad
{
    return OAUtilities.isLandscape ? kInfoViewLandscapeWidthPad : kInfoViewPortraitWidthPad;
}

- (void) show:(BOOL)animated onComplete:(void (^)(void))onComplete
{
    visible = YES;
    [_tableView setContentOffset:CGPointZero];
    _currentState = EOARouteInfoMenuStateFullScreen;
    [_tableView setScrollEnabled:YES];
    _historyItemsLimit = kHistoryItemLimitDefault;
    
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
            frame.size.width = OAUtilities.isIPad ? [self getViewWidthForPad] : DeviceScreenWidth * 0.45;
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
    _isHiding = YES;
    
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
                
                _isHiding = NO;
            }];
        }
        else
        {
            self.frame = frame;
            
            [self removeFromSuperview];
            
            [self onDismiss];

            if (onComplete)
                onComplete();
            
            _isHiding = NO;
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

- (OAGPXTrackAnalysis *) getTrackAnalysis
{
    OAGPXTrackAnalysis *trackAnalysis = _trackAnalysis;
    if (!trackAnalysis)
    {
        _gpx = [OAGPXUIHelper makeGpxFromRoute:_routingHelper.getRoute];
        trackAnalysis = [_gpx getAnalysis:0];
        _trackAnalysis = trackAnalysis;
        _needChartUpdate = YES;
    }
    return trackAnalysis;
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
        _trackAnalysis = nil;
        _gpx = nil;
        _progressBarView = nil;
        [self updateMenu];
    });
}

- (void) routeWasUpdated
{
    _trackAnalysis = nil;
    _gpx = nil;
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
                [cell.imgView setImage:[UIImage imageNamed:@"ic_custom_start_point"]];
                NSString *oname = [point getOnlyName].length > 0 ? [point getOnlyName] : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"map_settings_map"), [self getRoutePointDescription:[point getLatitude] lon:[point getLongitude]]];
                cell.addressLabel.text = oname;
            }
            else
            {
                [cell.imgView setImage:[UIImage imageNamed:@"ic_action_location_color"]];
                cell.addressLabel.text = OALocalizedString(@"shared_string_my_location");
            }
            [cell.routingCellButton setImage:[UIImage imageNamed:@"ic_custom_swap"] forState:UIControlStateNormal];
            [self setupButtonLayout:cell.routingCellButton];
            [cell.routingCellButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.routingCellButton addTarget:self action:@selector(swapPressed:) forControlEvents:UIControlEventTouchUpInside];
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
            [cell.imgView setImage:[UIImage imageNamed:@"ic_custom_destination"]];
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
            [cell.routingCellButton setImage:[UIImage imageNamed:@"ic_custom_add"] forState:UIControlStateNormal];
            [self setupButtonLayout:cell.routingCellButton];
            [cell.routingCellButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.routingCellButton addTarget:self action:@selector(addDestinationPressed:) forControlEvents:UIControlEventTouchUpInside];
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
            [cell setDividerVisibility:NO];
            NSArray<OARTargetPoint *> *points = [_pointsHelper getIntermediatePoints];
            NSMutableString *via = [NSMutableString string];
            for (OARTargetPoint *point in points)
            {
                if (via.length > 0)
                    [via appendString:@" "];
                
                NSString *description = [point getOnlyName];
                [via appendString:description];
            }
            [cell.imgView setImage:[UIImage imageNamed:@"ic_custom_intermediate"]];
            cell.titleLabel.text = OALocalizedString(@"route_via");
            cell.addressLabel.text = via;
            [cell.routingCellButton setImage:[UIImage imageNamed:@"ic_custom_edit"] forState:UIControlStateNormal];
            [self setupButtonLayout:cell.routingCellButton];
            [cell.routingCellButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.routingCellButton addTarget:self action:@selector(editDestinationsPressed:) forControlEvents:UIControlEventTouchUpInside];
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
        return _routeStatsCell;
    }
    else if ([item[@"cell"] isEqualToString:@"OAFilledButtonCell"])
    {
        static NSString* const reusableIdentifierPoint = item[@"cell"];
        
        OAFilledButtonCell* cell;
        cell = (OAFilledButtonCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:reusableIdentifierPoint owner:self options:nil];
            cell = (OAFilledButtonCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self action:@selector(openRouteDetails) forControlEvents:UIControlEventTouchUpInside];
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
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
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
        }
        if (cell)
        {
            cell.backgroundColor = UIColor.whiteColor;
            cell.dividerColor = UIColorFromRGB(color_divider_blur);
            CGFloat leftInset = [cell isDirectionRTL] ? 0. : 62.0;
            CGFloat rightInset = [cell isDirectionRTL] ? 62.0 : 0.;
            cell.dividerInsets = [item[@"custom_insets"] boolValue] ? UIEdgeInsetsMake(0., leftInset, 0., rightInset) : UIEdgeInsetsZero;
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
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:@"OAButtonCell"])
    {
        static NSString* const identifierCell = item[@"cell"];
        OAButtonCell* cell = nil;
        
        cell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAButtonCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            [cell.button addTarget:self action:@selector(onHistoryButtonPressed:) forControlEvents:UIControlEventTouchDown];
            [cell.button setTintColor:UIColorFromRGB(color_primary_purple)];
            [cell showImage:NO];
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:@"OARouteProgressBarCell"])
    {
        static NSString* const identifierCell = item[@"cell"];
        OARouteProgressBarCell* cell = nil;
        
        cell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OARouteProgressBarCell *)[nib objectAtIndex:0];
        }
        if (cell)
            _progressBarView = cell.progressBar;
        
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
        [self editDestinationsPressed:nil];
    }
    else if ([item[@"key"] isEqualToString:@"prev_route"])
    {
        [_pointsHelper restoreTargetPoints:YES];
    }
    else if ([item[@"cell"] isEqualToString:kCellReuseIdentifier])
    {
        [[OARootViewController instance].mapPanel openTargetViewWithRouteDetails:_gpx analysis:_trackAnalysis];
    }
    else if ([item[@"cell"] isEqualToString:@"OAMultiIconTextDescCell"])
    {
        id obj = item[@"item"];
        if (!obj)
            return;
        
        if ([obj isKindOfClass:OADestination.class])
        {
            OADestination *dest = (OADestination *) obj;
            [_pointsHelper navigateToPoint:[[CLLocation alloc] initWithLatitude:dest.latitude longitude:dest.longitude] updateRoute:YES intermediate:-1 historyName:[[OAPointDescription alloc] initWithType:POINT_TYPE_MAP_MARKER name:dest.desc]];
            [self updateData];
            [_tableView reloadData];
        }
        else if ([obj isKindOfClass:OAGPX.class])
        {
            OAGPX *gpx = (OAGPX *) obj;
            
            [[OARootViewController instance].mapPanel.mapActions setGPXRouteParams:gpx];
            [_routingHelper recalculateRouteDueToSettingsChange];
            [[OATargetPointsHelper sharedInstance] updateRouteAndRefresh:YES];
        }
        else if ([obj isKindOfClass:OAHistoryItem.class])
        {
            OAHistoryItem *historyItem = (OAHistoryItem *) obj;
            [_pointsHelper navigateToPoint:[[CLLocation alloc] initWithLatitude:historyItem.latitude longitude:historyItem.longitude] updateRoute:YES intermediate:-1 historyName:[[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION typeName:historyItem.typeName name:historyItem.name]];
            [self updateData];
            [_tableView reloadData];
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
    else if ([item[@"cell"] isEqualToString:kCellReuseIdentifier] || [item[@"cell"] isEqualToString:@"OAFilledButtonCell"])
        return UITableViewAutomaticDimension;
    else if ([item[@"cell"] isEqualToString:@"OARoutingSettingsCell"])
        return 50.0;
    else if ([item[@"cell"] isEqualToString:@"OAMultiIconTextDescCell"])
        return UITableViewAutomaticDimension;
    else if ([item[@"cell"] isEqualToString:@"OADividerCell"])
        return [OADividerCell cellHeight:0.5 dividerInsets:[item[@"custom_insets"] boolValue] ? UIEdgeInsetsMake(0., 62., 0., 0.) : UIEdgeInsetsZero];
    else if ([item[@"cell"] isEqualToString:@"OADescrTitleIconCell"])
        return UITableViewAutomaticDimension;
    else if ([item[@"cell"] isEqualToString:@"OARouteProgressBarCell"])
        return 2.0;
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.001;
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
            _initialTouchPoint = [recognizer locationInView:self].y;
        case UIGestureRecognizerStateChanged:
        {
            CGFloat newY = touchPoint.y - _initialTouchPoint;
            if (self.frame.origin.y > OAUtilities.getStatusBarHeight
                || (_initialTouchPoint < _tableView.frame.origin.y && _tableView.contentOffset.y > 0))
            {
                [_tableView setContentOffset:CGPointZero];
            }
            
            if (newY <= OAUtilities.getStatusBarHeight || _tableView.contentOffset.y > 0)
            {
                newY = 0;
                if (_tableView.contentOffset.y > 0)
                    _initialTouchPoint = [recognizer locationInView:self].y;
            }
            else if (DeviceScreenHeight - newY < _buttonsView.frame.size.height)
            {
                return;
            }
            
            CGRect frame = self.frame;
            frame.origin.y = newY > 0 && newY <= OAUtilities.getStatusBarHeight ? OAUtilities.getStatusBarHeight : newY;
            frame.size.height = DeviceScreenHeight - newY;
            self.frame = frame;
            
            _statusBarBackgroundView.frame = newY == 0 ? CGRectMake(0., 0., DeviceScreenWidth, OAUtilities.getStatusBarHeight) : CGRectZero;
            
            CGRect buttonsFrame = _buttonsView.frame;
            buttonsFrame.origin.y = frame.size.height - buttonsFrame.size.height;
            _buttonsView.frame = buttonsFrame;
            
            CGRect contentFrame = _contentContainer.frame;
            contentFrame.size.width = self.bounds.size.width;
            contentFrame.origin.y = CGRectGetMaxY(_statusBarBackgroundView.frame);
            contentFrame.size.height = frame.size.height - buttonsFrame.size.height - contentFrame.origin.y;
            _contentContainer.frame = contentFrame;
            
            CGFloat tableViewY = CGRectGetMaxY(_appModeViewContainer.frame);
            _tableView.frame = CGRectMake(0., tableViewY, contentFrame.size.width, contentFrame.size.height - tableViewY);
            
            [self applyCornerRadius:newY > 0];
            return;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            _isDragging = NO;
            BOOL shouldRefresh = NO;
            CGFloat newY = touchPoint.y - _initialTouchPoint;
            if ((newY - initialPoint.y > 180 || fastDownSlide) && _currentState == EOARouteInfoMenuStateInitial)
            {
                [[OARootViewController instance].mapPanel closeRouteInfo];
                break;
            }
            else if (newY > DeviceScreenHeight - (170.0 + ([self hasIntermediatePoints] ? 60.0 : 0.0) + _buttonsView.frame.size.height + _tableView.frame.origin.y) && !fastUpSlide)
            {
                shouldRefresh = YES;
                _currentState = EOARouteInfoMenuStateInitial;
            }
            else if (newY < fullScreenAnchor || (!slidingDown && _currentState == EOARouteInfoMenuStateExpanded) || fastUpSlide)
            {
                _currentState = EOARouteInfoMenuStateFullScreen;
            }
            else if ((newY < expandedAnchor || (newY > expandedAnchor && !slidingDown)) && !fastDownSlide)
            {
                shouldRefresh = YES;
                _currentState = EOARouteInfoMenuStateExpanded;
            }
            else
            {
                shouldRefresh = YES;
                _currentState = EOARouteInfoMenuStateInitial;
            }
            [UIView animateWithDuration: 0.2 animations:^{
                [self layoutSubviews];
            } completion:^(BOOL finished) {
                if (shouldRefresh)
                {
                    NSString *error = [_routingHelper getLastRouteCalcError];
                    OABBox routeBBox;
                    routeBBox.top = DBL_MAX;
                    routeBBox.bottom = DBL_MAX;
                    routeBBox.left = DBL_MAX;
                    routeBBox.right = DBL_MAX;
                    if ([_routingHelper isRouteCalculated] && !error)
                    {
                        routeBBox = [_routingHelper getBBox];
                        if ([_routingHelper isRoutePlanningMode] && routeBBox.left != DBL_MAX)
                        {
                            [[OARootViewController instance].mapPanel displayCalculatedRouteOnMap:CLLocationCoordinate2DMake(routeBBox.top, routeBBox.left) bottomRight:CLLocationCoordinate2DMake(routeBBox.bottom, routeBBox.right)];
                        }
                    }
                }
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
    return YES;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y <= 0 || self.frame.origin.y != 0)
        [scrollView setContentOffset:CGPointZero animated:NO];
    
    [self setupModeViewShadowVisibility];
}

#pragma mark - OAHomeWorkCellDelegate

- (void)onItemSelected:(NSString *)key
{
    [self onItemSelected:key overrideExisting:NO];
}

- (void) onItemSelected:(NSString *)key overrideExisting:(BOOL)overrideExisting
{
    BOOL isHome = [key isEqualToString:@"home"];
    OARTargetPoint *targetPoint = isHome ? _app.data.homePoint : _app.data.workPoint;
    
    if (targetPoint && !overrideExisting)
    {
        [_pointsHelper navigateToPoint:targetPoint.point updateRoute:YES intermediate:-1 historyName:targetPoint.pointDescription];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateData];
        [self.tableView reloadData];
    });
}

#pragma mark - OARouteCalculationProgressCallback

- (void) updateProgress:(int)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_progressBarView)
        {
            [self updateData];
            [self.tableView reloadData];
        }
        if (_progressBarView)
            [_progressBarView setProgress:progress / 100.];
    });
}

- (void) finish
{
}

- (void)requestPrivateAccessRouting
{
}

@end
