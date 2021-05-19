//
//  OATransportDetailsTableViewController.m
//  OsmAnd
//
//  Created by Paul on 20.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATransportDetailsTableViewController.h"
#import "OAPublicTransportRouteCell.h"
#import "OAPublicTransportShieldCell.h"
#import "OAPublicTransportPointCell.h"
#import "OATransportRoutingHelper.h"
#import "Localization.h"
#import "OAColors.h"
#import "OsmAndApp.h"
#import "OATargetPointsHelper.h"
#import "OARouteCalculationResult.h"
#import "OATransportStopRoute.h"
#import "OATargetInfoViewController.h"
#import "OAPublicTransportCollapsableCell.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAPointDescription.h"
#import "OAReverseGeocoder.h"
#import "OAPublicTransportRouteShieldCell.h"
#import "OADividerCell.h"

@interface OATransportDetailsTableViewController () <UITableViewDelegate, UITableViewDataSource, OATransportShieldDelegate>

@end

@implementation OATransportDetailsTableViewController
{
    OATransportRoutingHelper *_transportHelper;
    NSInteger _routeIndex;
    NSDictionary *_data;
    
    OsmAndAppInstance _app;
}

- (instancetype)initWithRouteIndex:(NSInteger) routeIndex
{
    self = [super init];
    if (self) {
        _transportHelper = OATransportRoutingHelper.sharedInstance;
        _routeIndex = routeIndex;
        _app = [OsmAndApp instance];
        [self generateData];
    }
    return self;
}

- (void)addStartItems:(NSMutableArray *)arr route:(const std::shared_ptr<TransportRouteResult> &)route segment:(const std::shared_ptr<TransportRouteResultSegment> &)segment start:(OARTargetPoint *)start startTime:(NSMutableArray<NSNumber *> *)startTime {
    NSString *title = @"";
    CLLocation *startLocation = nil;
    if (start)
    {
        title = start.getOnlyName.length > 0 ? start.getOnlyName :
            [NSString stringWithFormat:OALocalizedString(@"map_coords"), start.getLatitude, start.getLongitude];
        startLocation = start.point;
    }
    else
    {
        title = OALocalizedString(@"my_location");
        startLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
    }
    
    [arr addObject:@{
        @"cell" : [OAPublicTransportPointCell getCellIdentifier],
        @"img" : start ? @"ic_custom_start_point" : @"ic_action_location_color",
        @"title" : title,
        @"top_route_line" : @(NO),
        @"bottom_route_line" : @(NO),
        @"time" : [_app getFormattedTimeHM:startTime.firstObject.doubleValue],
        @"coords" : startLocation ? @[startLocation] : @[]
    }];
    
    double walkDist = [self getWalkDistance:nullptr next:segment dist:segment->walkDist];
    NSInteger time = [self getWalkTime:nullptr next:segment dist:walkDist speed:route->getWalkSpeed()];
    OARouteCalculationResult *seg = [_transportHelper getWalkingRouteSegment:[[OATransportRouteResultSegment alloc] initWithSegment:nullptr] s2:[[OATransportRouteResultSegment alloc] initWithSegment:segment]];
    if (time < 60)
        time = 60;
    
    [arr addObject:@{
        @"cell" : [OAPublicTransportPointCell getCellIdentifier],
        @"img" : @"ic_profile_pedestrian",
        @"title" : [NSString stringWithFormat:@"%@ ~%@, %@", OALocalizedString(@"walk"), [_app getFormattedTimeInterval:time shortFormat:NO], [_app getFormattedDistance:walkDist]],
        @"top_route_line" : @(NO),
        @"bottom_route_line" : @(NO),
        @"coords" : seg != nil ? seg.getImmutableAllLocations : @[]
    }];
    [startTime setObject:@(startTime.firstObject.integerValue + time) atIndexedSubscript:0];
    
    [arr addObject:@{
        @"cell" : [OADividerCell getCellIdentifier],
        @"custom_insets" : @(YES)
    }];
}

- (void)addLastItems:(NSMutableArray *)arr end:(OARTargetPoint *)end routeRes:(const std::shared_ptr<TransportRouteResult> &)routeRes segment:(const std::shared_ptr<TransportRouteResultSegment> &)segment startTime:(NSMutableArray<NSNumber *> *)startTime {
    double walkDist = [self getWalkDistance:segment next:nullptr dist:segment->walkDist];
    NSInteger time = [self getWalkTime:segment next:nullptr dist:walkDist speed:routeRes->getWalkSpeed()];
    OARouteCalculationResult *seg = [_transportHelper getWalkingRouteSegment:[[OATransportRouteResultSegment alloc] initWithSegment:segment] s2:[[OATransportRouteResultSegment alloc] initWithSegment:nullptr]];
    if (time < 60)
        time = 60;
    
    [arr addObject:@{
        @"cell" : [OAPublicTransportPointCell getCellIdentifier],
        @"img" : @"ic_profile_pedestrian",
        @"title" : [NSString stringWithFormat:@"%@ ~%@, %@", OALocalizedString(@"walk"), [_app getFormattedTimeInterval:time shortFormat:NO], [_app getFormattedDistance:walkDist]],
        @"top_route_line" : @(NO),
        @"bottom_route_line" : @(NO),
        @"coords" : seg != nil ? seg.getImmutableAllLocations : @[],
    }];
    [startTime setObject:@(startTime.firstObject.integerValue + time) atIndexedSubscript:0];
    
    [arr addObject:@{
        @"cell" : [OADividerCell getCellIdentifier],
        @"custom_insets" : @(YES)
    }];
    
    NSString *title = @"";
    if (end != nil)
    {
        title = end.getOnlyName.length > 0 ? end.getOnlyName :
        [NSString stringWithFormat:OALocalizedString(@"map_coords"), end.getLatitude, end.getLongitude];
    }
    
    [arr addObject:@{
        @"cell" : [OAPublicTransportPointCell getCellIdentifier],
        @"img" : @"ic_custom_destination",
        @"title" : title,
        @"descr" : OALocalizedString(@"map_widget_distance"),
        @"top_route_line" : @(NO),
        @"bottom_route_line" : @(NO),
        @"time" : [_app getFormattedTimeHM:startTime.firstObject.doubleValue],
        @"coords" : @[end.point]
    }];
    
    [arr addObject:@{
        @"cell" : [OADividerCell getCellIdentifier],
        @"custom_insets" : @(NO)
    }];
}

- (void)buildCollapsibleCells:(NSMutableArray *)arr color:(UIColor *)color segment:(const std::shared_ptr<TransportRouteResultSegment> &)segment stopType:(OATransportStopType *)stopType stops:(const std::vector<std::shared_ptr<TransportStop>, std::allocator<std::shared_ptr<TransportStop> > > &)stops section:(NSInteger)section {
    OATransportStopRoute *r = [[OATransportStopRoute alloc] init];
    r.type = stopType;
    NSMutableDictionary *collapsableCell = [NSMutableDictionary new];
    NSMutableArray *subItems = [NSMutableArray new];
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray new];
    [collapsableCell setObject:[OAPublicTransportCollapsableCell getCellIdentifier] forKey:@"cell"];
    [collapsableCell setObject:[NSString stringWithFormat:OALocalizedString(@"by_type"), [r getTypeStr]] forKey:@"descr"];
    [collapsableCell setObject:[NSString stringWithFormat:@"%lu %@ • %@", stops.size(), OALocalizedString(@"num_stops"), [_app getFormattedDistance:segment->getTravelDist()]] forKey:@"title"];
    [collapsableCell setObject:@(YES) forKey:@"collapsed"];
    [collapsableCell setObject:color forKey:@"line_color"];
    NSInteger row = arr.count;
    for (NSInteger i = 1; i < stops.size() - 1; i++)
    {
        const auto& stop = stops[i];
        [subItems addObject:@{
            @"cell" : [OAPublicTransportPointCell getCellIdentifier],
            @"img" : stopType ? stopType.resId : [OATransportStopType getResId:TST_BUS],
            @"title" : [NSString stringWithUTF8String:stop->name.c_str()],
            @"top_route_line" : @(YES),
            @"bottom_route_line" : @(YES),
            @"small_icon" : @(YES),
            @"custom_icon" : @(YES),
            @"line_color" : color,
            @"coords" : @[[[CLLocation alloc] initWithLatitude:stop->lat longitude:stop->lon]]
        }];
        [indexPaths addObject:[NSIndexPath indexPathForRow:(row + i) inSection:section]];
    }
    [collapsableCell setObject:indexPaths forKey:@"indexes"];
    
    [arr addObject:collapsableCell];
    [arr addObjectsFromArray:subItems];
}

- (NSMutableArray<CLLocation *> *)generateLocationsFor:(const std::shared_ptr<TransportRouteResultSegment> &)segment {
    NSMutableArray<CLLocation *> *locations = [NSMutableArray new];
    vector<std::shared_ptr<Way>> geometry;
    segment->getGeometry(geometry);
    for (const auto& w : geometry)
    {
        for (const auto& n : w->nodes)
        {
            [locations addObject:[[CLLocation alloc] initWithLatitude:n.lat longitude:n.lon]];
        }
    }
    return locations;
}

- (void)buildTransportSegmentItems:(NSMutableArray *)arr sectionsDictionary:(NSMutableDictionary *)dictionary routeRes:(const std::shared_ptr<TransportRouteResult> &)routeRes segment:(const std::shared_ptr<TransportRouteResultSegment> &)segment startTime:(NSMutableArray<NSNumber *> *)startTime section:(NSInteger &)section {
    const auto& route = segment->route;
    const auto stops = segment->getTravelStops();
    const auto& startStop = segment->getStart();
    OATransportStopType *stopType = [OATransportStopType findType:[NSString stringWithUTF8String:route->type.c_str()]];
    [startTime setObject:@(startTime.firstObject.integerValue + routeRes->getBoardingTime()) atIndexedSubscript:0];
    NSString *timeText = [_app getFormattedTimeHM:startTime.firstObject.doubleValue];
    NSString *str = [NSString stringWithUTF8String:route->color.c_str()];
    str = str.length == 0 ? stopType.renderAttr : str;
    UIColor *color = [OARootViewController.instance.mapPanel.mapViewController getTransportRouteColor:OAAppSettings.sharedManager.nightMode renderAttrName:str];
    
    [arr addObject:@{
        @"cell" : [OAPublicTransportPointCell getCellIdentifier],
        @"img" : stopType ? stopType.resId : [OATransportStopType getResId:TST_BUS],
        @"title" : [NSString stringWithUTF8String:startStop.name.c_str()],
        @"descr" : OALocalizedString(@"board_at"),
        @"time" : timeText,
        @"top_route_line" : @(NO),
        @"bottom_route_line" : @(YES),
        @"custom_icon" : @(YES),
        @"line_color" : color,
        @"coords" : @[[[CLLocation alloc] initWithLatitude:startStop.lat longitude:startStop.lon]],
    }];
    // TODO: fix later for schedule
    [startTime setObject:@(startTime.firstObject.integerValue + segment->travelTime) atIndexedSubscript:0];
    timeText = [_app getFormattedTimeHM:startTime.firstObject.doubleValue];
    
    NSMutableArray<CLLocation *> * locations = [self generateLocationsFor:segment];
    
    [arr addObject:@{
        @"cell" : [OAPublicTransportRouteShieldCell getCellIdentifier],
        @"img" : stopType ? stopType.resId : [OATransportStopType getResId:TST_BUS],
        @"title" : [NSString stringWithUTF8String:route->name.c_str()],
        @"line_color" : color,
        @"coords" : locations,
    }];
    
    if (stops.size() > 2)
    {
        [dictionary setObject:[NSArray arrayWithArray:arr] forKey:@(section++)];
        [arr removeAllObjects];
        [self buildCollapsibleCells:arr color:color segment:segment stopType:stopType stops:stops section:section];
        [dictionary setObject:[NSArray arrayWithArray:arr] forKey:@(section++)];
        [arr removeAllObjects];
    }
    
    const auto &endStop = segment->getEnd();
    [arr addObject:@{
        @"cell" : [OAPublicTransportPointCell getCellIdentifier],
        @"img" : stopType ? stopType.resId : [OATransportStopType getResId:TST_BUS],
        @"title" : [NSString stringWithUTF8String:endStop.name.c_str()],
        @"descr" : OALocalizedString(@"exit_at"),
        @"time" : timeText,
        @"top_route_line" : @(YES),
        @"bottom_route_line" : @(NO),
        @"custom_icon" : @(YES),
        @"line_color" : color,
        @"coords" : @[[[CLLocation alloc] initWithLatitude:endStop.lat longitude:endStop.lon]]
    }];
    
    [arr addObject:@{
        @"cell" : [OADividerCell getCellIdentifier],
        @"custom_insets" : @(YES)
    }];
}

- (void) generateData
{
    NSMutableDictionary *resData = [NSMutableDictionary new];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@{@"cell" : [OAPublicTransportShieldCell getCellIdentifier]},
                                                           @{@"cell" : [OAPublicTransportRouteCell getCellIdentifier]},
                                                           @{
                                                               @"cell" : [OADividerCell getCellIdentifier],
                                                               @"custom_insets" : @(NO)
                                                           }]];
    NSInteger section  = 0;
    const auto routeRes = _transportHelper.getRoutes[_routeIndex];
    OATargetPointsHelper *pointsHelper = OATargetPointsHelper.sharedInstance;
    OARTargetPoint *start = pointsHelper.getPointToStart;
    OARTargetPoint *end = pointsHelper.getPointToNavigate;
    NSMutableArray<NSNumber *> *startTime = [NSMutableArray new];
    [startTime addObject:@(0)];
    
    const auto segments = routeRes->segments;
    
    for (NSInteger i = 0; i < segments.size(); i++)
    {
        BOOL first = i == 0;
        BOOL last = i == segments.size() - 1;
        const auto& segment = segments[i];
        if (first)
        {
            [self addStartItems:arr route:routeRes segment:segment start:start startTime:startTime];
        }
        [self buildTransportSegmentItems:arr sectionsDictionary:resData routeRes:routeRes segment:segment startTime:startTime section:section];
        
        if (i < segments.size() - 1)
        {
            const auto& nextSegment = segments[i + 1];
            
            if (nextSegment != nullptr) {
                double walkDist = [self getWalkDistance:segment next:nextSegment dist:segment->walkDist];
                if (walkDist > 0)
                {
                    NSInteger time = [self getWalkTime:segment next:nextSegment dist:walkDist speed:routeRes->getWalkSpeed()];
                    if (time < 60)
                        time = 60;
                    OARouteCalculationResult *seg = [_transportHelper getWalkingRouteSegment:[[OATransportRouteResultSegment alloc] initWithSegment:segment] s2:[[OATransportRouteResultSegment alloc] initWithSegment:nextSegment]];
                    [arr addObject:@{
                        @"cell" : [OAPublicTransportPointCell getCellIdentifier],
                        @"img" : @"ic_profile_pedestrian",
                        @"title" : [NSString stringWithFormat:@"%@ ~%@, %@", OALocalizedString(@"walk"), [_app getFormattedTimeInterval:time shortFormat:NO], [_app getFormattedDistance:walkDist]],
                        @"top_route_line" : @(NO),
                        @"bottom_route_line" : @(NO),
                        @"coords" : seg != nil ? seg.getImmutableAllLocations : @[]
                    }];
                    [startTime setObject:@(startTime.firstObject.integerValue + time) atIndexedSubscript:0];
                    
                    [arr addObject:@{
                        @"cell" : [OADividerCell getCellIdentifier],
                        @"custom_insets" : @(YES)
                    }];
                }
            }
        }
        
        if (last)
        {
            [self addLastItems:arr end:end routeRes:routeRes segment:segment startTime:startTime];
        }
    }
    [resData setObject:arr forKey:@(section++)];
    _data = [NSDictionary dictionaryWithDictionary:resData];
}

- (double) getWalkDistance:(SHARED_PTR<TransportRouteResultSegment>) segment next:(SHARED_PTR<TransportRouteResultSegment>)next dist:(double) dist
{
    OARouteCalculationResult *walkingRouteSegment = [_transportHelper getWalkingRouteSegment:[[OATransportRouteResultSegment alloc] initWithSegment:segment] s2:[[OATransportRouteResultSegment alloc] initWithSegment:next]];
    if (walkingRouteSegment)
        return walkingRouteSegment.getWholeDistance;
    return dist;
}

- (double) getWalkTime:(SHARED_PTR<TransportRouteResultSegment>) segment next:(SHARED_PTR<TransportRouteResultSegment>)next dist:(double) dist speed:(double)speed
{
    OARouteCalculationResult *walkingRouteSegment = [_transportHelper getWalkingRouteSegment:[[OATransportRouteResultSegment alloc] initWithSegment:segment] s2:[[OATransportRouteResultSegment alloc] initWithSegment:next]];
    if (walkingRouteSegment)
        return walkingRouteSegment.routingTime;
    return dist / speed;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void) onTransportDetailsPressed:(id)sender
{
    [self.delegate onDetailsRequested];
}

- (void) onStartPressed:(id)sender
{
    [self.delegate onStartPressed];
}

- (NSDictionary *) getItem:(NSIndexPath *) indexPath
{
    return _data[@(indexPath.section)][indexPath.row];
}

- (CGFloat) getMinimizedContentHeight
{
    CGFloat res = 0;
    for (NSInteger i = 0; i < 2; i++)
    {
        res += [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]].frame.size.height;
    }
    return res;
}

- (NSAttributedString *) getFirstLineDescrAttributed:(SHARED_PTR<TransportRouteResult>)res
{
    NSMutableAttributedString *attributedStr = [NSMutableAttributedString new];
    vector<SHARED_PTR<TransportRouteResultSegment>> segments = res->segments;
    NSString *name = [NSString stringWithUTF8String:segments[0]->getStart().name.c_str()];
    
    NSDictionary *secondaryAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:15.0], NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)};
    NSDictionary *mainAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold], NSForegroundColorAttributeName : UIColor.blackColor};
    
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
    NSDictionary *secondaryAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:15.0], NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)};
    NSDictionary *mainAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold], NSForegroundColorAttributeName : UIColor.blackColor};
    auto& segments = res->segments;
    NSInteger walkTimeReal = [_transportHelper getWalkingTime:segments];
    NSInteger walkTimePT = (NSInteger) res->getWalkTime();
    NSInteger walkTime = walkTimeReal > 0 ? walkTimeReal : walkTimePT;
    NSString *walkTimeStr = [OsmAndApp.instance getFormattedTimeInterval:walkTime shortFormat:NO];
    NSInteger walkDistanceReal = [_transportHelper getWalkingDistance:segments];
    NSInteger walkDistancePT = (NSInteger) res->getWalkDist();
    NSInteger walkDistance = walkDistanceReal > 0 ? walkDistanceReal : walkDistancePT;
    NSString *walkDistanceStr = [OsmAndApp.instance getFormattedDistance:walkDistance];
    NSInteger travelTime = (NSInteger) res->getTravelTime() + walkTime;
    NSString *travelTimeStr = [OsmAndApp.instance getFormattedTimeInterval:travelTime shortFormat:NO];
    NSInteger travelDist = (NSInteger) res->getTravelDist() + walkDistance;
    NSString *travelDistStr = [OsmAndApp.instance getFormattedDistance:travelDist];

    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:[OALocalizedString(@"total") stringByAppendingString:@" "] attributes:secondaryAttributes]];
    
    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:travelTimeStr attributes:mainAttributes]];
    
    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@", %@  •  %@ ", travelDistStr, OALocalizedString(@"walk")] attributes:secondaryAttributes]];
    
    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:walkTimeStr attributes:mainAttributes]];
    
    [attributedStr appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@", %@", walkDistanceStr] attributes:secondaryAttributes]];

    return attributedStr;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"cell"] isEqualToString:[OAPublicTransportRouteCell getCellIdentifier]])
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
            cell.topInfoLabel.attributedText = [self getFirstLineDescrAttributed:_transportHelper.getRoutes[_routeIndex]];
            cell.bottomInfoLabel.attributedText = [self getSecondLineDescrAttributed:_transportHelper.getRoutes[_routeIndex]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.detailsButton setTitle:OALocalizedString(@"res_details") forState:UIControlStateNormal];
            cell.detailsButton.tag = _routeIndex;
            [cell.detailsButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.detailsButton addTarget:self action:@selector(onTransportDetailsPressed:) forControlEvents:UIControlEventTouchUpInside];
            [cell.showOnMapButton setTitle:OALocalizedString(@"gpx_start") forState:UIControlStateNormal];
            cell.showOnMapButton.tag = _routeIndex;
            [cell.showOnMapButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.showOnMapButton addTarget:self action:@selector(onStartPressed:) forControlEvents:UIControlEventTouchUpInside];
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
            [cell needsSafeAreaInsets:NO];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            const auto& routes = _transportHelper.getRoutes;
            [cell setData:routes[_routeIndex]];
            cell.delegate = self.delegate;
        }
        
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:[OAPublicTransportPointCell getCellIdentifier]])
    {
        OAPublicTransportPointCell* cell = nil;
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OAPublicTransportPointCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPublicTransportPointCell getCellIdentifier] owner:self options:nil];
            cell = (OAPublicTransportPointCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            BOOL smallIcon = [item[@"small_icon"] boolValue];
            NSString *imageName = item[@"img"];
            if (imageName)
            {
                cell.iconView.hidden = NO;
                if ([item[@"custom_icon"] boolValue])
                {
                    UIImage *img = [[OATargetInfoViewController getIcon:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    img = smallIcon ? [[OAUtilities resizeImage:img newSize:CGSizeMake(16., 16.)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : img;
                    [cell.iconView setImage:img];
                    cell.iconView.tintColor = smallIcon ? UIColorFromRGB(color_icon_inactive) : UIColorFromRGB(color_chart_orange);
                    [cell showOutiline:YES];
                    cell.iconView.contentMode = UIViewContentModeCenter;
                }
                else
                {
                    [cell.iconView setImage:[UIImage imageNamed:imageName]];
                    [cell showOutiline:NO];
                    cell.iconView.contentMode = UIViewContentModeScaleAspectFit;
                }
            }
            else
            {
                cell.iconView.hidden = YES;
            }
            cell.descView.text = item[@"descr"];
            cell.textView.text = item[@"title"];
            
            cell.topRouteLineView.hidden = ![item[@"top_route_line"] boolValue];
            cell.bottomRouteLineView.hidden = ![item[@"bottom_route_line"] boolValue];
            
            UIColor *routeColor = item[@"line_color"];
            if (routeColor)
            {
                cell.topRouteLineView.backgroundColor = routeColor;
                cell.bottomRouteLineView.backgroundColor = routeColor;
            }
            
            cell.timeLabel.text = item[@"time"] ? item[@"time"] : @"";
            
            [cell showSmallIcon:smallIcon];
        }
        
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:[OAPublicTransportCollapsableCell getCellIdentifier]])
    {
        OAPublicTransportCollapsableCell* cell = nil;
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OAPublicTransportCollapsableCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPublicTransportCollapsableCell getCellIdentifier] owner:self options:nil];
            cell = (OAPublicTransportCollapsableCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.iconView setImage:
             [UIImage templateImageNamed:([item[@"collapsed"] boolValue] ? @"ic_custom_arrow_down" : @"ic_custom_arrow_up")]];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            
            cell.descView.text = item[@"descr"];
            cell.textView.text = item[@"title"];
            
            UIColor *routeColor = item[@"line_color"];
            if (routeColor)
            {
                cell.routeLineView.backgroundColor = routeColor;
            }
        }
        
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:[OAPublicTransportRouteShieldCell getCellIdentifier]])
    {
        OAPublicTransportRouteShieldCell* cell = nil;
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OAPublicTransportRouteShieldCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPublicTransportRouteShieldCell getCellIdentifier] owner:self options:nil];
            cell = (OAPublicTransportRouteShieldCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.iconView setImage:[[OATargetInfoViewController getIcon:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            cell.textView.text = item[@"title"];
            
            cell.routeShieldContainerView.tag = indexPath.section << 10 | indexPath.row;
            cell.delegate = self;
            
            UIColor *routeColor = item[@"line_color"];
            if (routeColor)
            {
                [cell setShieldColor:routeColor];
                cell.routeLineView.backgroundColor = routeColor;
            }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
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
            cell.dividerColor = UIColorFromRGB(color_tint_gray);
            CGFloat leftInset = [cell isDirectionRTL] ? 0. : 62.0;
            CGFloat rightInset = [cell isDirectionRTL] ? 62.0 : 0.;
            cell.dividerInsets = [item[@"custom_insets"] boolValue] ? UIEdgeInsetsMake(0., leftInset, 0., rightInset) : UIEdgeInsetsZero;
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionData = _data[@(section)];
    NSDictionary *item = sectionData.firstObject;
    
    if ([item[@"cell"] isEqualToString:[OAPublicTransportCollapsableCell getCellIdentifier]])
    {
        return [item[@"collapsed"] boolValue] ? 1 : sectionData.count;
    }
    return sectionData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"cell"] isEqualToString:[OADividerCell getCellIdentifier]])
        return [OADividerCell cellHeight:0.5 dividerInsets:[item[@"custom_insets"] boolValue] ? UIEdgeInsetsMake(0., 62., 0., 0.) : UIEdgeInsetsZero];
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        return 118.;
    return 44.;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"cell"] isEqualToString:[OAPublicTransportCollapsableCell getCellIdentifier]])
    {
        NSMutableDictionary *mutableItem = (NSMutableDictionary *) item;
        [tableView beginUpdates];
        if ([mutableItem[@"collapsed"] boolValue])
        {
            [mutableItem setObject:@(NO) forKey:@"collapsed"];
            [tableView insertRowsAtIndexPaths:item[@"indexes"] withRowAnimation:UITableViewRowAnimationFade];
        }
        else
        {
            [mutableItem setObject:@(YES) forKey:@"collapsed"];
            [tableView deleteRowsAtIndexPaths:item[@"indexes"] withRowAnimation:UITableViewRowAnimationFade];
        }
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
        [self.delegate onContentHeightChanged];
    }
    else if ([item[@"cell"] isEqualToString:[OAPublicTransportPointCell getCellIdentifier]])
    {
        NSArray<CLLocation *> *locations = item[@"coords"];
        [self.delegate showSegmentOnMap:locations];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - OATransportShieldDelegate

- (void) onShileldPressed:(NSInteger)index
{
    NSDictionary *item = [self getItem:[NSIndexPath indexPathForRow:index & 0x3FF inSection:index >> 10]];
    [self.delegate showSegmentOnMap:item[@"coords"]];
}

@end
