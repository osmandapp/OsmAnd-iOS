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
#import "OATransportRoutingHelper.h"
#import "OAAppModeCell.h"
#import "OARoutingTargetCell.h"
#import "OALineChartCell.h"
#import "OARTargetPoint.h"
#import "OAPointDescription.h"
#import "Localization.h"
#import "OARootViewController.h"
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
#import "OAMapLayers.h"
#import "OAAddDestinationBottomSheetViewController.h"
#import "OAFollowTrackBottomSheetViewController.h"
#import "OATrackSegmentsViewController.h"
#import "OARoutingSettingsCell.h"
#import "OAHomeWorkCell.h"
#import "OAGPXDatabase.h"
#import "OAMultiIconTextDescCell.h"
#import "OATableViewCustomHeaderView.h"
#import "OAStateChangedListener.h"
#import "OADividerCell.h"
#import "OARouteProvider.h"
#import "OASelectedGPXHelper.h"
#import "OAHistoryHelper.h"
#import "OAButtonTableViewCell.h"
#import "OARouteProgressBarCell.h"
#import "OARouteStatisticsHelper.h"
#import "OAFilledButtonCell.h"
#import "OAPublicTransportRouteCell.h"
#import "OAPublicTransportShieldCell.h"
#import "OATableViewCustomFooterView.h"
#import "OARouteAvoidTransportSettingsViewController.h"
#import "OAOsmAndFormatter.h"
#import "OALinks.h"
#import "OASimpleTableViewCell.h"
#import "OARouteBaseViewController.h"
#import "OAEmissionHelper.h"
#import "OAAutoObserverProxy.h"

#include "OAGPXDocument+cpp.h"

#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>

#define kHistoryItemLimitDefault 3
#define kCellReuseIdentifier @"emptyCell"
#define MAX_PEDESTRIAN_ROUTE_DURATION (30 * 60)
#define kSoundButtonRow 2
#define kSoundButtonSection 0

static int directionInfo = -1;
static BOOL visible = false;

typedef NS_ENUM(NSInteger, EOARouteInfoMenuState)
{
    EOARouteInfoMenuStateInitial = 0,
    EOARouteInfoMenuStateExpanded,
    EOARouteInfoMenuStateFullScreen
};

@interface OARouteInfoView ()<OARouteInformationListener, OAAppModeCellDelegate, OAWaypointSelectionDelegate, OAHomeWorkCellDelegate, OAStateChangedListener, UIGestureRecognizerDelegate, OARouteCalculationProgressCallback, OATransportRouteCalculationProgressCallback, UITextViewDelegate, OASegmentSelectionDelegate, OARoutingSettingsCellDelegate, OAEmissionHelperListener>

@end

@implementation OARouteInfoView
{
    OATargetPointsHelper *_pointsHelper;
    OARoutingHelper *_routingHelper;
    OATransportRoutingHelper *_transportHelper;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
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
    
    BOOL _hasEmptyTransportRoute;
    BOOL _optionsMenuSelected;

    NSIndexPath *_routingInfoIndexPath;
    NSString *_emission;
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
    [_tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    [_tableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    [_tableView setShowsVerticalScrollIndicator:NO];
    [_tableView setShowsHorizontalScrollIndicator:NO];
    _tableView.estimatedRowHeight = kEstimatedRowHeight;
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALineChartCell getCellIdentifier] owner:self options:nil];
    _routeStatsCell = (OALineChartCell *)[nib objectAtIndex:0];

    [GpxUIHelper setupGPXChartWithChartView:_routeStatsCell.lineChartView
                               yLabelsCount:4
                                  topOffset:20
                               bottomOffset:4
                        useGesturesAndScale:NO
    ];

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

    _cancelButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
    _goButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];

    _cancelButton.layer.cornerRadius = 9.;
    _goButton.layer.cornerRadius = 9.;

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
    _goButton.backgroundColor = isActive ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_button_gray_background);
    [_goButton setTintColor:isActive ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [_goButton setTitleColor:isActive ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
    [_goButton.imageView setTintColor:_goButton.tintColor];
    
    _goButton.userInteractionEnabled = isActive;
    
    if (!_routingHelper.isPublicTransportMode)
    {
        [_goButton setTitle:OALocalizedString(@"shared_string_control_start") forState:UIControlStateNormal];
        [_goButton setImage:[UIImage templateImageNamed:@"ic_custom_navigation_arrow"] forState:UIControlStateNormal];
    }
    else
    {
        [_goButton setTitle:OALocalizedString(@"shared_string_show_on_map") forState:UIControlStateNormal];
        [_goButton setImage:[UIImage templateImageNamed:@"ic_custom_map"] forState:UIControlStateNormal];
    }
    [self layoutSubviews];
}

- (void) setupModeViewShadowVisibility
{
    BOOL shouldShow = _tableView.contentOffset.y > 0 && self.frame.origin.y == 0;
    _appModeViewContainer.layer.shadowOpacity = shouldShow ? 0.15 : 0.0;
}

- (void) commonInit
{
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _pointsHelper = [OATargetPointsHelper sharedInstance];
    _routingHelper = [OARoutingHelper sharedInstance];
    _transportHelper = [OATransportRoutingHelper sharedInstance];

    [_routingHelper addListener:self];
    [_pointsHelper addListener:self];
    
    _prevRouteSection = -1;
    _gpxTripSection = -1;
    _mapMarkerSection = -1;
    _historySection = -1;
    
    _historyItemsLimit = kHistoryItemLimitDefault;
    
    [_routingHelper addProgressBar:self];
    [_transportHelper addProgressBar:self];
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
    NSMutableArray<OAGPXDocument *> *visibleGpxDocs = [NSMutableArray array];
    NSMutableArray<OAGPX *> *visibleGpx = [NSMutableArray array];
    
    auto activeGpx = helper.activeGpx;
    for (auto it = activeGpx.begin(); it != activeGpx.end(); ++it)
    {
        NSString *gpxFilePath = [OAUtilities getGpxShortPath:it.key().toNSString()];
        OAGPX *gpx = [dbHelper getGPXItem:gpxFilePath];
        if (gpx)
        {
            auto doc = it.value();
            if (doc != nullptr && (doc->hasRtePt() || doc->hasTrkPt()))
            {
                [visibleGpx addObject:gpx];
                [visibleGpxDocs addObject:[[OAGPXDocument alloc] initWithGpxDocument:std::const_pointer_cast<OsmAnd::GpxDocument>(doc)]];
            }
        }
    }
    
    if(visibleGpx.count == 0)
        return;
    
    [section addObject:@{
        @"cell" : [OADividerCell getCellIdentifier],
        @"custom_insets" : @(NO)
    }];
    
    for (NSInteger i = 0; i < visibleGpx.count; i++)
    {
        OAGPX *gpx = visibleGpx[i];
        OAGPXDocument *doc = visibleGpxDocs[i];
        if (gpx && doc)
        {
            doc.path = gpx.absolutePath;
            [section addObject:@{
                @"cell" : [OAMultiIconTextDescCell getCellIdentifier],
                @"title" : gpx.getNiceTitle,
                @"descr" : [OAGPXUIHelper getDescription:gpx],
                @"img" : @"ic_custom_trip",
                @"item" : doc
            }];
        }
        
        if (i != visibleGpx.count - 1)
        {
            [section addObject:@{
                @"cell" : [OADividerCell getCellIdentifier],
                @"custom_insets" : @(YES)
            }];
        }
    }
    [section addObject:@{
        @"cell" : [OADividerCell getCellIdentifier],
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
            @"cell" : [OADividerCell getCellIdentifier],
            @"custom_insets" : @(NO)
        }];
        
        [section addObject:@{
            @"cell" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : destinationBackup.pointDescription.name,
            @"descr" : startBackup ? startBackup.pointDescription.name : OALocalizedString(@"shared_string_my_location"),
            @"img" : @"ic_custom_point_to_point",
            @"key" : @"prev_route"
        }];
        
        [section addObject:@{
            @"cell" : [OADividerCell getCellIdentifier],
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
            @"cell" : [OADividerCell getCellIdentifier],
            @"custom_insets" : @(NO)
        }];
        for (NSInteger i = 0; i < markers.count; i++)
        {
            OADestination *item = markers[i];
            [section addObject:@{
                @"cell" : [OAMultiIconTextDescCell getCellIdentifier],
                @"title" : item.desc,
                @"img" : [item.markerResourceName ? item.markerResourceName : @"ic_destination_pin_1" stringByAppendingString:@"_small"],
                @"item" : item
            }];
            if (i != markers.count - 1)
            {
                [section addObject:@{
                    @"cell" : [OADividerCell getCellIdentifier],
                    @"custom_insets" : @(YES)
                }];
            }
        }
        [section addObject:@{
            @"cell" : [OADividerCell getCellIdentifier],
            @"custom_insets" : @(NO)
        }];
        _mapMarkerSection = sectionIndex;
        [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
        [section removeAllObjects];
    }
}

- (void)generateHistorySection:(NSMutableDictionary *)dictionary section:(NSMutableArray *)section sectionIndex:(int &)sectionIndex {
    OAHistoryHelper *helper = [OAHistoryHelper sharedInstance];
    NSArray *allItems = [helper getPointsFromNavigation:_historyItemsLimit];
    if (allItems.count > 0)
    {
        [section addObject:@{
            @"cell" : [OADividerCell getCellIdentifier],
            @"custom_insets" : @(NO)
        }];
        for (OAHistoryItem *item in allItems)
        {
            [section addObject:@{
                @"cell" : [OAMultiIconTextDescCell getCellIdentifier],
                @"title" : item.name,
                @"img" : @"ic_custom_history",
                @"item" : item
            }];
            
            [section addObject:@{
                @"cell" : [OADividerCell getCellIdentifier],
                @"custom_insets" : @(YES)
            }];
            
        }
        if (allItems.count == _historyItemsLimit)
        {
            [section addObject:@{
                @"cell" : [OAButtonTableViewCell getCellIdentifier],
                @"title" : OALocalizedString(@"show_more")
            }];
        }
        else
        {
            [section removeObjectAtIndex:section.count - 1];
        }
        [section addObject:@{
            @"cell" : [OADividerCell getCellIdentifier],
            @"custom_insets" : @(NO)
        }];
        _historySection = sectionIndex;
        [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
    }
}

- (BOOL) isRouteCalculated
{
    return [_routingHelper isRouteCalculated] || (_routingHelper.isPublicTransportMode && _transportHelper.getRoutes.size() > 0);
}

- (void)generateTransportCells:(NSMutableDictionary *)dictionary section:(NSMutableArray *)section sectionIndex:(int &)sectionIndex {
    for (NSInteger i = 0; i < _transportHelper.getRoutes.size(); i++)
    {
        [section addObject:@{
            @"cell" : [OADividerCell getCellIdentifier],
            @"custom_insets" : @(NO)
        }];
        
        [section addObject:@{
            @"cell" : [OAPublicTransportShieldCell getCellIdentifier],
            @"route_index" : @(i)
        }];
        [section addObject:@{
            @"cell" : [OAPublicTransportRouteCell getCellIdentifier],
            @"route_index" : @(i)
        }];
        
        [section addObject:@{
            @"cell" : [OADividerCell getCellIdentifier],
            @"custom_insets" : @(NO)
        }];
        [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
        [section removeAllObjects];
    }
}

- (void)addPedestrianRouteWarningIfNeeded:(NSMutableDictionary *)dictionary section:(NSMutableArray *)section sectionIndex:(int &)sectionIndex {
    const auto route = _transportHelper.getRoutes[0];
    NSInteger walkTimeReal = [_transportHelper getWalkingTime:route->segments];
    NSInteger walkTimePT = (NSInteger) route->getWalkTime();
    NSInteger walkTime = walkTimeReal > 0 ? walkTimeReal : walkTimePT;
    NSInteger travelTime = route->getTravelTime() + walkTime;
    NSInteger approxPedestrianTime = (NSInteger) getDistance(_transportHelper.startLocation.coordinate.latitude,
                                                             _transportHelper.startLocation.coordinate.longitude,
                                                             _transportHelper.endLocation.coordinate.latitude,
                                                             _transportHelper.endLocation.coordinate.longitude);
    BOOL showPedestrianCard = approxPedestrianTime < travelTime + 60 && approxPedestrianTime < MAX_PEDESTRIAN_ROUTE_DURATION;
    if (showPedestrianCard)
    {
        [section addObject:@{
            @"cell" : [OADividerCell getCellIdentifier],
            @"custom_insets" : @(NO)
        }];
        
        NSString *time = [OAOsmAndFormatter getFormattedTimeInterval:approxPedestrianTime shortFormat:NO];
        NSString *formattedStr = [NSString stringWithFormat:OALocalizedString(@"public_transport_ped_route_title"), time];
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:formattedStr attributes:@{ NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody] }];
        
        NSRange range = [formattedStr rangeOfString:time];
        [str setAttributes:@{ NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline] } range:range];
        
        [section addObject:@{
            @"cell" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : str,
            @"img" : @"ic_profile_pedestrian",
            @"key" : @"pedestrian_short"
        }];
        
        [section addObject:@{
            @"cell" : [OAFilledButtonCell getCellIdentifier],
            @"title" : OALocalizedString(@"calc_pedestrian_route"),
            @"key": @"calc_pedestrian"
        }];
        
        [section addObject:@{
            @"cell" : [OADividerCell getCellIdentifier],
            @"custom_insets" : @(NO)
        }];
        
        [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
        [section removeAllObjects];
    }
}

- (void) updateData
{
    _emission = nil;
    _routingInfoIndexPath = nil;

    int sectionIndex = 0;
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    NSMutableArray *section = [[NSMutableArray alloc] init];
    [section addObject:@{
        @"cell" : [OARoutingTargetCell getCellIdentifier],
        @"type" : @"start"
    }];
    
    if ([self hasIntermediatePoints])
    {
        [section addObject:@{
            @"cell" : [OARoutingTargetCell getCellIdentifier],
            @"type" : @"intermediate"
        }];
    }
    else if (_routingHelper.getCurrentGPXRoute)
    {
        [section addObject:@{
            @"cell" : [OARoutingTargetCell getCellIdentifier],
            @"type" : @"gpx_route"
        }];
    }
    
    if (![self isFinishPointFromTrack])
    {
        [section addObject:@{
            @"cell" : [OARoutingTargetCell getCellIdentifier],
            @"type" : @"finish"
        }];
    }
    
    [section addObject:@{
        @"cell" : [OARoutingSettingsCell getCellIdentifier]

    }];
    
    if (_hasEmptyTransportRoute)
    {
        [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
        _data = [NSDictionary dictionaryWithDictionary:dictionary];
        [self setupGoButton];
        return;
    }
    
    if ((![_routingHelper isRouteCalculated] && [_routingHelper isRouteBeingCalculated]) || (_routingHelper.isPublicTransportMode && [_transportHelper isRouteBeingCalculated]))
    {
        [section addObject:@{
            @"cell" : [OARouteProgressBarCell getCellIdentifier]
        }];
    }
    [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
    [section removeAllObjects];
    
    if ([self isRouteCalculated] && ![_routingHelper isRouteBeingCalculated] && ![_transportHelper isRouteBeingCalculated])
    {
        if ([_routingHelper isPublicTransportMode])
        {
            [self generateTransportCells:dictionary section:section sectionIndex:sectionIndex];
            [self addPedestrianRouteWarningIfNeeded:dictionary section:section sectionIndex:sectionIndex];
        }
        else
        {
            [section addObject:@{
                @"cell" : [OADividerCell getCellIdentifier],
                @"custom_insets" : @(NO)
            }];

            [section addObject:@{
                @"cell" : [OASimpleTableViewCell getCellIdentifier],
            }];
            _routingInfoIndexPath = [NSIndexPath indexPathForRow:section.count - 1 inSection:sectionIndex];

            [section addObject:@{
                @"cell" : kCellReuseIdentifier
            }];
            [section addObject:@{
                @"cell" : [OAFilledButtonCell getCellIdentifier],
                @"title" : OALocalizedString(@"shared_string_details"),
                @"key" : @"route_details"
            }];
            [section addObject:@{
                @"cell" : [OADividerCell getCellIdentifier],
                @"custom_insets" : @(NO)
            }];
            [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
            
            OAGPXTrackAnalysis *trackAnalysis = [self getTrackAnalysis];
            if (_needChartUpdate)
            {
                [GpxUIHelper refreshLineChartWithChartView:_routeStatsCell.lineChartView
                                                  analysis:trackAnalysis
                                       useGesturesAndScale:NO
                                                 firstType:GPXDataSetTypeALTITUDE
                                                secondType:GPXDataSetTypeSLOPE];
                _needChartUpdate = NO;
            }
        }
        _currentState = EOARouteInfoMenuStateExpanded;
    }
    else if (!_routingHelper.isRouteBeingCalculated && !_transportHelper.isRouteBeingCalculated)
    {
        [section addObject:@{
            @"cell" : [OADividerCell getCellIdentifier],
            @"custom_insets" : @(NO)
        }];
        [section addObject:@{
            @"cell" : [OAHomeWorkCell getCellIdentifier]
        }];
        [section addObject:@{
            @"cell" : [OADividerCell getCellIdentifier],
            @"custom_insets" : @(NO)
        }];
        [dictionary setObject:[NSArray arrayWithArray:section] forKey:@(sectionIndex++)];
        
        [section removeAllObjects];

        BOOL isHistoryOn = [_settings.navigationHistory get];
        if (isHistoryOn)
            [self generatePrevRouteSection:dictionary section:section sectionIndex:sectionIndex];

        [self generateGpxSection:dictionary section:section sectionIndex:sectionIndex];

        [self generateMrkersSection:dictionary section:section sectionIndex:sectionIndex];

        if (isHistoryOn)
            [self generateHistorySection:dictionary section:section sectionIndex:sectionIndex];
    }
    _data = [NSDictionary dictionaryWithDictionary:dictionary];
    
    [self setupGoButton];

    if (_routingInfoIndexPath)
    {
        OAEmissionHelper *emissionHelper = [OAEmissionHelper sharedInstance];
        OAMotorType *motorType = [emissionHelper getMotorTypeForMode:[_routingHelper getAppMode]];
        if (motorType)
            [emissionHelper getEmission:motorType meters:[_routingHelper getLeftDistance] listener:self];
    }
}

- (BOOL) isFinishPointFromTrack
{
    OAGPXRouteParamsBuilder *routeParams = _routingHelper.getCurrentGPXRoute;
    if (routeParams != nil)
    {
        OARTargetPoint *target = _pointsHelper.getPointToNavigate;
        if (target != nil)
        {
            NSArray<CLLocation *> *points = routeParams.getPoints;
            if (points.count > 0)
            {
                CLLocation *loc = points.lastObject;
                return [OAUtilities isCoordEqual:loc.coordinate.latitude srcLon:loc.coordinate.longitude destLat:target.getLatitude destLon:target.getLongitude];
            }
        }
    }
    return NO;
}

- (BOOL) isGpxTrackFollowingMode
{
    return _routingHelper.getCurrentGPXRoute != nil;
}

- (NSAttributedString *) getFirstLineDescrAttributed:(SHARED_PTR<TransportRouteResult>)res
{
    NSMutableAttributedString *attributedStr = [NSMutableAttributedString new];
    vector<SHARED_PTR<TransportRouteResultSegment>> segments = res->segments;
    NSString *name = [NSString stringWithUTF8String:segments[0]->getStart().name.c_str()];
    
    NSDictionary *secondaryAttributes = @{NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline], NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)};
    NSDictionary *mainAttributes = @{NSFontAttributeName : [UIFont scaledSystemFontOfSize:15.0 weight:UIFontWeightSemibold], NSForegroundColorAttributeName : UIColor.blackColor};
    
    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:[OALocalizedString(@"route_from") stringByAppendingString:@" "] attributes:secondaryAttributes]];
    
    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:name attributes:mainAttributes]];

    if (segments.size() > 1)
    {
        [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"  •  %@ %lu", OALocalizedString(@"transfers"), segments.size() - 1] attributes:secondaryAttributes]];
    }

    return attributedStr;
}

- (NSAttributedString *) getSecondLineDescrAttributed:(SHARED_PTR<TransportRouteResult>)res
{
    NSMutableAttributedString *attributedStr = [NSMutableAttributedString new];
    NSDictionary *secondaryAttributes = @{NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline], NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)};
    NSDictionary *mainAttributes = @{NSFontAttributeName : [UIFont scaledSystemFontOfSize:15.0 weight:UIFontWeightSemibold], NSForegroundColorAttributeName : UIColor.blackColor};
    auto& segments = res->segments;
    NSInteger walkTimeReal = [_transportHelper getWalkingTime:segments];
    NSInteger walkTimePT = (NSInteger) res->getWalkTime();
    NSInteger walkTime = walkTimeReal > 0 ? walkTimeReal : walkTimePT;
    NSString *walkTimeStr = [OAOsmAndFormatter getFormattedTimeInterval:walkTime shortFormat:NO];
    NSInteger walkDistanceReal = [_transportHelper getWalkingDistance:segments];
    NSInteger walkDistancePT = (NSInteger) res->getWalkDist();
    NSInteger walkDistance = walkDistanceReal > 0 ? walkDistanceReal : walkDistancePT;
    NSString *walkDistanceStr = [OAOsmAndFormatter getFormattedDistance:walkDistance];
    NSInteger travelTime = (NSInteger) res->getTravelTime() + walkTime;
    NSString *travelTimeStr = [OAOsmAndFormatter getFormattedTimeInterval:travelTime shortFormat:NO];
    NSInteger travelDist = (NSInteger) res->getTravelDist() + walkDistance;
    NSString *travelDistStr = [OAOsmAndFormatter getFormattedDistance:travelDist];

    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:[OALocalizedString(@"shared_string_total") stringByAppendingString:@" "] attributes:secondaryAttributes]];
    
    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:travelTimeStr attributes:mainAttributes]];
    
    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@", %@  •  %@ ", travelDistStr, OALocalizedString(@"shared_string_walk")] attributes:secondaryAttributes]];
    
    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:walkTimeStr attributes:mainAttributes]];
    
    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@", %@", walkDistanceStr] attributes:secondaryAttributes]];

    return attributedStr;
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
    
    CGFloat goIconOffset = 12;
    CGFloat goIconSecondOffset = 8;
    CGFloat estimatedLabelWith = [OAUtilities calculateTextBounds:_goButton.titleLabel.text width:_goButton.frame.size.width font:_goButton.titleLabel.font].width;
    CGFloat estimatedContentWidth = goIconOffset + _goButton.imageView.frame.size.width + goIconOffset + estimatedLabelWith;
    CGFloat goLabelOffset = (buttonWidth / 2) - (estimatedLabelWith / 2) - _goButton.imageView.frame.size.width - goIconSecondOffset;
    if (estimatedContentWidth > buttonWidth || goLabelOffset < 0)
        goLabelOffset = 0;
    if ([_goButton isDirectionRTL])
    {
        _goButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _goButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, goIconOffset);
        _goButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, goLabelOffset);
    }
    else
    {
        _goButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _goButton.contentEdgeInsets = UIEdgeInsetsMake(0, goIconOffset, 0, 0);
        _goButton.titleEdgeInsets = UIEdgeInsetsMake(0, goLabelOffset, 0, 0);
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

- (void) onTransportDetailsPressed:(id)sender
{
    if ([sender isKindOfClass:UIButton.class])
    {
        UIButton *btn = (UIButton *) sender;
        [_transportHelper setCurrentRoute:btn.tag];
        [OARootViewController.instance.mapPanel openTargetViewWithTransportRouteDetails:btn.tag showFullScreen:YES];
    }
}

- (void) onTransportShowOnMapPressed:(id)sender
{
    if ([sender isKindOfClass:UIButton.class])
    {
        UIButton *btn = (UIButton *) sender;
        [_transportHelper setCurrentRoute:btn.tag];
        [OARootViewController.instance.mapPanel openTargetViewWithTransportRouteDetails:btn.tag showFullScreen:NO];
    }
}

- (IBAction) closePressed:(id)sender
{
    [[OARootViewController instance].mapPanel stopNavigation];
}

- (IBAction) goPressed:(id)sender
{
    if (_app.carPlayActive)
    {
        [NSNotificationCenter.defaultCenter postNotificationName:kCarPlayTripStartedNotification object:nil];
        [[OARootViewController instance].mapPanel closeRouteInfo:YES
                                                      onComplete:nil];
    }
    else
    {
        BOOL isPublicTransport = [_routingHelper isPublicTransportMode];
        if ([_pointsHelper getPointToNavigate] || isPublicTransport)
        {
            if (!isPublicTransport)
                [[OARootViewController instance].mapPanel startNavigation];
            [[OARootViewController instance].mapPanel closeRouteInfo:YES
                                                          onComplete:nil];
        }
    }
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

- (void) calcPedestrianRoute
{
    [_appModeView setSelectedMode:OAApplicationMode.PEDESTRIAN];
    [self appModeChanged:OAApplicationMode.PEDESTRIAN];
    [_pointsHelper updateRouteAndRefresh:YES];
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

        [self show:NO fullMenu:NO onComplete:nil];
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

- (void)show:(BOOL)animated fullMenu:(BOOL)fullMenu onComplete:(void (^)(void))onComplete
{
    [[OARootViewController instance].keyCommandUpdateObserver handleObservedEventFrom:nil withKey:kCommandNavigationScreenOpen];

    visible = YES;
    _optionsMenuSelected = NO;
    [_appModeView setupModeButtons];
    [_tableView setContentOffset:CGPointZero];
    _currentState = fullMenu ? EOARouteInfoMenuStateFullScreen : _currentState;
    [_tableView setScrollEnabled:YES];
    _historyItemsLimit = kHistoryItemLimitDefault;
    
    [self updateData];
    [self setNeedsLayout];
    [self adjustFrame];
    [self.tableView reloadData];
    
    BOOL isNight = _settings.nightMode;
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    [mapPanel setTopControlsVisible:NO
           onlyMapSettingsAndSearch:NO
               customStatusBarStyle:isNight ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
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
    OAApplicationMode *am = [_routingHelper getAppMode];
    _appModeView.selectedMode = am;
	if ([_settings.applicationMode get] != am)
        [self appModeChanged:am];
}

- (void) hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    visible = NO;
    _isHiding = YES;

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
    
    if (![_pointsHelper getPointToNavigate] && ![self isSelectingTargetOnMap] && !_optionsMenuSelected)
        [mapPanel.mapActions stopNavigationWithoutConfirm];

    [[OARootViewController instance].keyCommandUpdateObserver handleObservedEventFrom:nil withKey:kCommandNavigationScreenClose];
}

- (void) addWaypoint
{
    // not implemented
}

- (void) update
{
    [self updateData];
    [self.tableView reloadData];
}

- (void) updateMenu
{
    if ([self superview])
        [self show:NO fullMenu:YES onComplete:nil];
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
    _hasEmptyTransportRoute = NO;
    [_routingHelper setAppMode:next];
    [_settings setApplicationModePref:next markAsLastUsed:NO];
    [_app initVoiceCommandPlayer:next warningNoneProvider:YES showDialog:NO force:NO];
    if ([_routingHelper isRouteBeingCalculated] || (_routingHelper.isPublicTransportMode && [_transportHelper isRouteBeingCalculated]))
        [_tableView reloadData];
    else
        [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kSoundButtonRow inSection:kSoundButtonSection]] withRowAnimation:UITableViewRowAnimationNone];
    [self setupGoButton];
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
        _hasEmptyTransportRoute = _routingHelper.isPublicTransportMode && _transportHelper.getRoutes.size() == 0;
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
    if ([item[@"cell"] isEqualToString:[OARoutingTargetCell getCellIdentifier]])
    {
        OARoutingTargetCell* cell;
        cell = (OARoutingTargetCell *)[self.tableView dequeueReusableCellWithIdentifier:[OARoutingTargetCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARoutingTargetCell getCellIdentifier] owner:self options:nil];
            cell = (OARoutingTargetCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            NSString *type = item[@"type"];
            if ([type isEqualToString:@"start"])
            {
                cell.finishPoint = NO;
                OARTargetPoint *point = [_pointsHelper getPointToStart];
                cell.titleLabel.text = OALocalizedString(@"route_from");
                if (point)
                {
                    [cell.imgView setImage:[UIImage imageNamed:@"ic_custom_start_point"]];
                    NSString *oname = [point getOnlyName].length > 0 ? [point getOnlyName] : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"shared_string_map"), [self getRoutePointDescription:[point getLatitude] lon:[point getLongitude]]];
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
                cell.routingCellButton.hidden = self.isGpxTrackFollowingMode;
                cell.routingCellButton.userInteractionEnabled = !cell.routingCellButton.isHidden;
            }
            else if ([type isEqualToString:@"finish"])
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
                cell.routingCellButton.hidden = _routingHelper.isPublicTransportMode;
                cell.routingCellButton.userInteractionEnabled = !cell.routingCellButton.isHidden;
                UIImage *image = self.isGpxTrackFollowingMode ? [UIImage imageNamed:@"ic_navbar_close"] : [UIImage imageNamed:@"ic_custom_add"];
                [cell.routingCellButton setImage:image forState:UIControlStateNormal];
                [self setupButtonLayout:cell.routingCellButton];
                [cell.routingCellButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                if (self.isGpxTrackFollowingMode)
                    [cell.routingCellButton addTarget:self action:@selector(removeFinishDestination) forControlEvents:UIControlEventTouchUpInside];
                else
                    [cell.routingCellButton addTarget:self action:@selector(addDestinationPressed:) forControlEvents:UIControlEventTouchUpInside];
            }
            else if ([type isEqualToString:@"intermediate"])
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
                if (cell.routingCellButton.isHidden)
                {
                    cell.routingCellButton.hidden = NO;
                    cell.routingCellButton.userInteractionEnabled = YES;
                }
            }
            else if ([type isEqualToString:@"gpx_route"])
            {
                OAGPXRouteParamsBuilder *gpxParams = _routingHelper.getCurrentGPXRoute;
                OAGPXDocument *gpx = gpxParams.file;
                NSString *fileName = @"";
                if (gpx.path.length > 0)
                    fileName = [gpx.path.lastPathComponent stringByDeletingPathExtension];
                else if (gpx.tracks.count > 0)
                    fileName = gpx.tracks.firstObject.name;
                
                if (fileName.length == 0)
                    fileName = OALocalizedString(@"shared_string_gpx_track");
                
                if (gpx.getNonEmptySegmentsCount > 1 && gpxParams != nil && gpxParams.selectedSegment != -1)
                {
                    fileName = [NSString stringWithFormat:@"%@, %@", [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_of"), gpxParams.selectedSegment + 1, gpx.getNonEmptySegmentsCount], fileName];
                }
                
                cell.finishPoint = NO;
                [cell setDividerVisibility:self.isFinishPointFromTrack];
                [cell.imgView setImage:[UIImage templateImageNamed:@"ic_custom_trip"]];
                cell.imgView.tintColor = UIColorFromRGB(color_icon_inactive);
                cell.titleLabel.text = OALocalizedString(@"follow_track");
                cell.addressLabel.text = fileName;
                if (self.isGpxTrackFollowingMode && !self.isFinishPointFromTrack)
                {
                    cell.routingCellButton.hidden = YES;
                    cell.routingCellButton.userInteractionEnabled = NO;
                }
                else
                {
                    cell.routingCellButton.hidden = NO;
                    cell.routingCellButton.userInteractionEnabled = YES;
                    [cell.routingCellButton setImage:[UIImage imageNamed:@"ic_custom_add"] forState:UIControlStateNormal];
                    [self setupButtonLayout:cell.routingCellButton];
                    [cell.routingCellButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
                    [cell.routingCellButton addTarget:self action:@selector(addFinishDestination) forControlEvents:UIControlEventTouchUpInside];
                }
            }
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
        }
        if (cell)
        {
            NSString *key = item[@"key"];
            if ([key isEqualToString:@"prev_route"] || [key isEqualToString:@"pedestrian_short"])
            {
                [cell leftIconVisibility:YES];
                if ([key isEqualToString:@"pedestrian_short"])
                {
                    cell.leftIconView.image = [UIImage templateImageNamed:item[@"img"]];
                    cell.leftIconView.tintColor = UIColorFromRGB(color_icon_inactive);
                    cell.descriptionLabel.text = nil;
                    cell.descriptionLabel.attributedText = item[@"title"];
                }
                else
                {
                    cell.leftIconView.image = [UIImage imageNamed:item[@"img"]];
                    cell.descriptionLabel.attributedText = nil;
                    cell.descriptionLabel.text = item[@"title"];
                }
                cell.descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
                cell.descriptionLabel.textColor = UIColor.blackColor;
                cell.titleLabel.attributedText = nil;
                cell.titleLabel.text = item[@"descr"];
                cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
                cell.titleLabel.textColor = UIColorFromRGB(color_text_footer);
            }
            else if (indexPath == _routingInfoIndexPath)
            {
                [cell leftIconVisibility:NO];
                cell.titleLabel.text = nil;
                cell.titleLabel.attributedText = [OARouteBaseViewController getFormattedDistTimeString];
                cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
                cell.titleLabel.textColor = UIColor.blackColor;
                NSMutableAttributedString *attrDescription =
                [[NSMutableAttributedString alloc] initWithAttributedString:[OARouteBaseViewController getFormattedElevationString:[self getTrackAnalysis]]];
                if (_emission)
                {
                    NSString *emission = [NSString stringWithFormat:@"    |    %@", _emission];
                    [attrDescription addString:emission fontWeight:UIFontWeightRegular size:15.];
                    [attrDescription setColor:UIColorFromRGB(color_text_footer) forString:emission];
                }
                cell.descriptionLabel.text = nil;
                cell.descriptionLabel.attributedText = attrDescription;
                cell.descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
                cell.descriptionLabel.textColor = UIColorFromRGB(color_text_footer);
            }
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:kCellReuseIdentifier])
    {
        return _routeStatsCell;
    }
    else if ([item[@"cell"] isEqualToString:[OAFilledButtonCell getCellIdentifier]])
    {
        OAFilledButtonCell* cell;
        cell = (OAFilledButtonCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAFilledButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            NSString *key = item[@"key"];
            if ([key isEqualToString:@"route_details"])
                [cell.button addTarget:self action:@selector(openRouteDetails) forControlEvents:UIControlEventTouchUpInside];
            else if ([key isEqualToString:@"calc_pedestrian"])
                [cell.button addTarget:self action:@selector(calcPedestrianRoute) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:[OARoutingSettingsCell getCellIdentifier]])
    {
        OARoutingSettingsCell* cell;
        cell = (OARoutingSettingsCell *)[self.tableView dequeueReusableCellWithIdentifier:[OARoutingSettingsCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARoutingSettingsCell getCellIdentifier] owner:self options:nil];
            cell = (OARoutingSettingsCell *)[nib objectAtIndex:0];
            cell.delegate = self;
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:[OAHomeWorkCell getCellIdentifier]])
    {
        OAHomeWorkCell *cell;
        cell = (OAHomeWorkCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAHomeWorkCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAHomeWorkCell getCellIdentifier] owner:self options:nil];
            cell = (OAHomeWorkCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.delegate = self;
            [cell generateData];
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:[OAMultiIconTextDescCell getCellIdentifier]])
    {
        OAMultiIconTextDescCell* cell;
        cell = (OAMultiIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:[OAMultiIconTextDescCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            [cell setOverflowVisibility:YES];
        }
        
        if (cell)
        {
            [cell.textView setText:item[@"title"]];
            [cell.descView setText:item[@"descr"]];
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
        }
        if ([cell needsUpdateConstraints])
            [cell updateConstraints];
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
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
    else if ([item[@"cell"] isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
    {
        OAButtonTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAButtonTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAButtonTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell titleVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        }
        if (cell)
        {
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            [cell.button removeTarget:self action:NULL forControlEvents:UIControlEventTouchDown];
            [cell.button addTarget:self action:@selector(onHistoryButtonPressed:) forControlEvents:UIControlEventTouchDown];
        }
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:[OARouteProgressBarCell getCellIdentifier]])
    {
        OARouteProgressBarCell* cell = nil;
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OARouteProgressBarCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARouteProgressBarCell getCellIdentifier] owner:self options:nil];
            cell = (OARouteProgressBarCell *)[nib objectAtIndex:0];
        }
        if (cell)
            _progressBarView = cell.progressBar;
        
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:[OAPublicTransportRouteCell getCellIdentifier]])
    {
        OAPublicTransportRouteCell* cell = nil;
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OAPublicTransportRouteCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPublicTransportRouteCell getCellIdentifier] owner:self options:nil];
            cell = (OAPublicTransportRouteCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            NSInteger routeIndex = [item[@"route_index"] integerValue];
            cell.topInfoLabel.attributedText = [self getFirstLineDescrAttributed:_transportHelper.getRoutes[routeIndex]];
            cell.bottomInfoLabel.attributedText = [self getSecondLineDescrAttributed:_transportHelper.getRoutes[routeIndex]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.detailsButton setTitle:OALocalizedString(@"shared_string_details") forState:UIControlStateNormal];
            cell.detailsButton.tag = routeIndex;
            [cell.detailsButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.detailsButton addTarget:self action:@selector(onTransportDetailsPressed:) forControlEvents:UIControlEventTouchUpInside];
            [cell.showOnMapButton setTitle:OALocalizedString(@"recording_context_menu_show") forState:UIControlStateNormal];
            cell.showOnMapButton.tag = routeIndex;
            [cell.showOnMapButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.showOnMapButton addTarget:self action:@selector(onTransportShowOnMapPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:[OAPublicTransportShieldCell getCellIdentifier]])
    {
        OAPublicTransportShieldCell* cell = nil;
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OAPublicTransportShieldCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPublicTransportShieldCell getCellIdentifier] owner:self options:nil];
            cell = (OAPublicTransportShieldCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            NSInteger routeIndex = [item[@"route_index"] integerValue];
            const auto& routes = _transportHelper.getRoutes;
            [cell setData:routes[routeIndex]];
        }
        
        return cell;
    }
    return nil;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"cell"] isEqualToString:[OARoutingSettingsCell getCellIdentifier]])
        return nil;
    return indexPath;
}

- (void)addFinishDestination
{
    OAAddDestinationBottomSheetViewController *addDest = [[OAAddDestinationBottomSheetViewController alloc] initWithType:EOADestinationTypeFinish];
    addDest.delegate = self;
    [addDest show];
}

- (void)removeFinishDestination
{
    if (_routingHelper.getCurrentGPXRoute != nil)
    {
        OAGPXRouteParamsBuilder *routeParams = _routingHelper.getCurrentGPXRoute;
        CLLocation *finalPoint = routeParams.getPoints.lastObject;
        
        if (finalPoint)
            [[OATargetPointsHelper sharedInstance] navigateToPoint:finalPoint updateRoute:YES intermediate:-1];
    }
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
        [self addFinishDestination];
    }
    else if ([item[@"type"] isEqualToString:@"intermediate"])
    {
        [self editDestinationsPressed:nil];
    }
    else if ([item[@"type"] isEqualToString:@"gpx_route"])
    {
        OAFollowTrackBottomSheetViewController *bottomSheet = [[OAFollowTrackBottomSheetViewController alloc] initWithFile:_routingHelper.getCurrentGPXRoute.file];
        [bottomSheet presentInViewController:OARootViewController.instance];
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
        else if ([obj isKindOfClass:OAGPXDocument.class])
        {
            OAGPXDocument *gpx = (OAGPXDocument *) obj;
            
            OAApplicationMode *mode = [gpx getRouteProfile];
            if (mode)
            {
                [_routingHelper setAppMode:mode];
                [_app initVoiceCommandPlayer:mode warningNoneProvider:YES showDialog:NO force:NO];
            }
            
            if (gpx.getNonEmptySegmentsCount > 1)
            {
                OATrackSegmentsViewController *segmentsController = [[OATrackSegmentsViewController alloc] initWithFile:gpx];
                segmentsController.delegate = self;
                [OARootViewController.instance presentViewController:segmentsController animated:YES completion:nil];
            }
            else
            {
                [[OARootViewController instance].mapPanel.mapActions setGPXRouteParamsWithDocument:gpx path:gpx.path];
                [_routingHelper recalculateRouteDueToSettingsChange];
                [[OATargetPointsHelper sharedInstance] updateRouteAndRefresh:YES];
            }
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
    if ([item[@"cell"] isEqualToString:[OAHomeWorkCell getCellIdentifier]])
        return 60.0;
    else if ([item[@"cell"] isEqualToString:[OARoutingSettingsCell getCellIdentifier]])
        return 50.0;
    else if ([item[@"cell"] isEqualToString:[OADividerCell getCellIdentifier]])
        return [OADividerCell cellHeight:0.5 dividerInsets:[item[@"custom_insets"] boolValue] ? UIEdgeInsetsMake(0., 62., 0., 0.) : UIEdgeInsetsZero];
    else if ([item[@"cell"] isEqualToString:[OARouteProgressBarCell getCellIdentifier]])
        return 2.0;
    else if ([item[@"cell"] isEqualToString:[OAPublicTransportShieldCell getCellIdentifier]])
        return [OAPublicTransportShieldCell getCellHeight:tableView.frame.size.width route:_transportHelper.getRoutes[[item[@"route_index"] integerValue]]];
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"cell"] isEqualToString:[OAPublicTransportRouteCell getCellIdentifier]])
        return 118.;
    else if ([item[@"cell"] isEqualToString:[OAFilledButtonCell getCellIdentifier]])
        return 58.;
    
    return kEstimatedRowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (((_routingHelper.isPublicTransportMode && [_transportHelper isRouteBeingCalculated]) || _hasEmptyTransportRoute) && section == _data.count - 1)
    {
        return [OAUtilities calculateTextBounds:_hasEmptyTransportRoute ?
                [self getAttributedEmptyRouteWarning] : [self getAttributedBetaWarning] width:tableView.bounds.size.width].height + 8.0;
    }
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
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    
    if (!title)
    {
        vw.label.text = title;
        return vw;
    }
    
    vw.label.text = [title upperCase];
    return vw;
}

- (NSAttributedString *) getAttributedEmptyRouteWarning
{
    NSString *mainText = OALocalizedString(@"public_transport_empty_warning_title");
    NSString *additionalText = OALocalizedString(@"public_transport_try_change_settings");
    NSString *settingName = OALocalizedString(@"avoid_transport_type");
    NSDictionary *attributes = @{ NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline], NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer) };
    
    NSMutableAttributedString *res = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n\n%@\n%@", mainText, additionalText, settingName] attributes:attributes];
    
    NSRange settingRange = [res.string rangeOfString:settingName];
    if (settingRange.location != NSNotFound)
    {
        [res addAttributes:@{NSLinkAttributeName: @"osmand://open_transport_settings",
                             NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple),
                             NSFontAttributeName: [UIFont scaledSystemFontOfSize:15 weight:UIFontWeightSemibold]
        } range:settingRange];
    }
    return [[NSAttributedString alloc] initWithAttributedString:res];
}

- (NSAttributedString *) getAttributedBetaWarning
{
    NSString *mainText = OALocalizedString(@"public_transport_warning_title");
    NSString *additionalText = OALocalizedString(@"public_transport_warning_descr_blog");
    NSDictionary *attributes = @{ NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline], NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer) };
    
    NSMutableAttributedString *res = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n\n%@", mainText, additionalText] attributes:attributes];
    
    [res addAttributes:@{NSLinkAttributeName: kBlogGuideline,
                         NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple),
                         NSFontAttributeName: [UIFont scaledSystemFontOfSize:15 weight:UIFontWeightSemibold]
    } range:NSMakeRange(mainText.length + 2, additionalText.length)];
    return [[NSAttributedString alloc] initWithAttributedString:res];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (((_routingHelper.isPublicTransportMode && [_transportHelper isRouteBeingCalculated]) || _hasEmptyTransportRoute) && section == _data.count - 1)
    {
        OATableViewCustomFooterView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
        NSAttributedString* res = _hasEmptyTransportRoute ? [self getAttributedEmptyRouteWarning] : [self getAttributedBetaWarning];
        vw.label.attributedText = res;
        vw.label.delegate = self;
        [vw setIcon:_hasEmptyTransportRoute ? @"ic_custom_no_route" : @"ic_action_bus_dark"];
        return vw;
    }
    else
    {
        return nil;
    }
}

- (NSString *) getTitleForSection:(NSInteger) section
{
    if ([_routingHelper isRouteCalculated])
        return nil;
    
    if (section == _prevRouteSection)
        return OALocalizedString(@"previous_route");
    else if (section == _gpxTripSection)
        return OALocalizedString(@"tracks_on_map");
    else if (section == _mapMarkerSection)
        return OALocalizedString(@"map_markers");
    else if (section == _historySection)
        return OALocalizedString(@"shared_string_history");
        
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
                    if (([_routingHelper isRouteCalculated] && !error) || (_routingHelper.isPublicTransportMode && !_transportHelper.isRouteBeingCalculated && _transportHelper.getRoutes.size() > 0 && _transportHelper.currentRoute != -1))
                    {
                        routeBBox = _routingHelper.isPublicTransportMode? [_transportHelper getBBox] : [_routingHelper getBBox];
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
    OARTargetPoint *targetPoint = isHome ? [_pointsHelper getHomePoint] : [_pointsHelper getWorkPoint];
    
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
        _hasEmptyTransportRoute = NO;
        [self updateData];
        [self.tableView reloadData];
    });
}

#pragma mark - OARouteCalculationProgressCallback

- (void)start
{
}

- (void) updateProgress:(int)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_progressBarView)
        {
            _hasEmptyTransportRoute = NO;
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

- (void)startProgress {
    dispatch_async(dispatch_get_main_queue(), ^{
        _hasEmptyTransportRoute = NO;
        if (!_progressBarView)
        {
            [self updateData];
            [self.tableView reloadData];
        }
        if (_progressBarView)
            [_progressBarView setProgress:0.];
    });
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    if ([URL.absoluteString hasPrefix:@"osmand"])
    {
        if ([URL.absoluteString hasSuffix:@"open_transport_settings"])
        {
            OARouteAvoidTransportSettingsViewController *avoidTransportController = [[OARouteAvoidTransportSettingsViewController alloc] init];
            [OARootViewController.instance.mapPanel presentViewController:avoidTransportController animated:YES completion:nil];
            return NO;
        }
    }
    return YES;
}

#pragma mark - OASegmentSelectionDelegate

- (void) onSegmentSelected:(NSInteger)position gpx:(OAGPXDocument *)gpx
{
    [OAAppSettings.sharedManager.gpxRouteSegment set:position];
    
    [[OARootViewController instance].mapPanel.mapActions setGPXRouteParamsWithDocument:gpx path:gpx.path];
    [_routingHelper recalculateRouteDueToSettingsChange];
    [[OATargetPointsHelper sharedInstance] updateRouteAndRefresh:YES];
    
    [self updateData];
    [self.tableView reloadData];
}

#pragma mark - OASettingsDataDelegate

- (void) onOptionsButtonPressed
{
    _optionsMenuSelected = YES;
}

#pragma mark - OAEmissionHelperListener

- (void)onSetupEmission:(NSString *)result
{
    _emission = result;
    if (_routingInfoIndexPath)
        [_tableView reloadRowsAtIndexPaths:@[_routingInfoIndexPath] withRowAnimation:UITableViewRowAnimationNone];

}

@end
