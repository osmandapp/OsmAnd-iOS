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

@interface OATransportDetailsTableViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OATransportDetailsTableViewController
{
    OATransportRoutingHelper *_transportHelper;
    NSInteger _routeIndex;
    NSArray<NSDictionary *> *_data;
    
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

- (void) generateData
{
    //                  @{@"cell" : @"OAPublicTransportPointCell", @"img" : @"ic_custom_start_point", @"title" : @"Start", @"time" : @"0:00", @"top_route_line" : @(NO), @"bottom_route_line" : @(NO)},
     //                  @{@"cell" : @"OAPublicTransportPointCell", @"img" : @"ic_profile_pedestrian", @"title" : @"By foot", @"time" : @"0:05", @"top_route_line" : @(NO), @"bottom_route_line" : @(NO)},
     //                  @{@"cell" : @"OAPublicTransportPointCell", @"title" : @"Hotel ABC", @"descr" : @"Board at stop", @"time" : @"0:10", @"top_route_line" : @(YES), @"bottom_route_line" : @(YES)},
     //                  @{@"cell" : @"OAPublicTransportPointCell", @"img" : @"ic_custom_destination", @"title" : @"Independence Square", @"descr" : @"Exit at", @"time" : @"0:10", @"top_route_line" : @(YES), @"bottom_route_line" : @(NO), @"small_icon" : @(YES)}];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:@[@{@"cell" : @"OAPublicTransportShieldCell"},
                                                           @{@"cell" : @"OAPublicTransportRouteCell"}
    ]];
    const auto route = _transportHelper.getRoutes[_routeIndex];
    OATargetPointsHelper *pointsHelper = OATargetPointsHelper.sharedInstance;
    OARTargetPoint *start = pointsHelper.getPointToStart;
    OARTargetPoint *end = pointsHelper.getPointToNavigate;
    NSMutableArray<NSNumber *> *startTime = [NSMutableArray new];
    [startTime addObject:@(0)];
    
    const auto segments = route->segments;
    for (NSInteger i = 0; i < segments.size(); i++)
    {
        BOOL first = i == 0;
        BOOL last = i == segments.size() - 1;
        const auto& segment = segments[i];
        if (first)
        {
            NSString *title = @"";
            if (start != nil)
            {
                title = start.getOnlyName.length > 0 ? start.getOnlyName :
                    [NSString stringWithFormat:OALocalizedString(@"map_coords"), start.getLatitude, start.getLongitude];
            }
            
            [arr addObject:@{
                @"cell" : @"OAPublicTransportPointCell",
                @"img" : start != nil ? @"ic_custom_start_point" : @"map_pedestrian_location",
                @"title" : title,
                @"top_route_line" : @(NO),
                @"bottom_route_line" : @(NO),
                @"time" : [_app getFormattedTimeInterval:startTime.firstObject.doubleValue shortFormat:YES]
            }];
            
            double walkDist = [self getWalkDistance:nullptr next:segment dist:segment->walkDist];
            NSInteger time = [self getWalkTime:nullptr next:segment dist:walkDist speed:route->getWalkSpeed()];
            if (time < 60)
                time = 60;
            
            [arr addObject:@{
                @"cell" : @"OAPublicTransportPointCell",
                @"img" : @"ic_profile_pedestrian",
                @"title" : [NSString stringWithFormat:@"%@ ~%@", OALocalizedString(@"walk"), [_app getFormattedTimeInterval:time shortFormat:NO]],
                @"top_route_line" : @(NO),
                @"bottom_route_line" : @(NO)
            }];
        }
    }
    _data = [NSArray arrayWithArray:arr];
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

- (NSDictionary *) getItem:(NSIndexPath *) indexPath
{
    return _data[indexPath.row];
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
    NSString *name = [NSString stringWithUTF8String:segments[0]->getStart()->name.c_str()];
    
    NSDictionary *secondaryAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:15.0], NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)};
    NSDictionary *mainAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:15.0], NSForegroundColorAttributeName : UIColor.blackColor};
    
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
    NSDictionary *mainAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:15.0], NSForegroundColorAttributeName : UIColor.blackColor};
    const auto& segments = res->segments;
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
    if ([item[@"cell"] isEqualToString:@"OAPublicTransportRouteCell"])
    {
        static NSString* const identifierCell = item[@"cell"];
        OAPublicTransportRouteCell* cell = nil;
        
        cell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAPublicTransportRouteCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.topInfoLabel.attributedText = [self getFirstLineDescrAttributed:_transportHelper.getRoutes[_routeIndex]];
            cell.bottomInfoLabel.attributedText = [self getSecondLineDescrAttributed:_transportHelper.getRoutes[_routeIndex]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.detailsButton setTitle:OALocalizedString(@"res_details") forState:UIControlStateNormal];
            cell.detailsButton.tag = _routeIndex;
//            [cell.detailsButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
//            [cell.detailsButton addTarget:self action:@selector(onTransportDetailsPressed:) forControlEvents:UIControlEventTouchUpInside];
            [cell.showOnMapButton setTitle:OALocalizedString(@"sett_show") forState:UIControlStateNormal];
            cell.showOnMapButton.tag = _routeIndex;
//            [cell.showOnMapButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
//            [cell.showOnMapButton addTarget:self action:@selector(onTransportShowOnMapPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:@"OAPublicTransportShieldCell"])
    {
        static NSString* const identifierCell = item[@"cell"];
        OAPublicTransportShieldCell* cell = nil;
        
        cell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAPublicTransportShieldCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell needsSafeAreaInsets:NO];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            const auto& routes = _transportHelper.getRoutes;
            [cell setData:routes[_routeIndex]];
        }
        
        return cell;
    }
    else if ([item[@"cell"] isEqualToString:@"OAPublicTransportPointCell"])
    {
        NSString* identifierCell = item[@"cell"];
        OAPublicTransportPointCell* cell = nil;
        
        cell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAPublicTransportPointCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            NSString *imageName = item[@"img"];
            if (imageName)
            {
                cell.iconView.hidden = NO;
                [cell.iconView setImage:[UIImage imageNamed:imageName]];
            }
            else
            {
                cell.iconView.hidden = YES;
            }
            cell.descView.text = item[@"descr"];
            cell.textView.text = item[@"title"];
            
            cell.topRouteLineView.hidden = ![item[@"top_route_line"] boolValue];
            cell.bottomRouteLineView.hidden = ![item[@"bottom_route_line"] boolValue];
            
            cell.timeLabel.text = item[@"time"] ? item[@"time"] : @"";
            
            [cell showSmallIcon:[item[@"small_icon"] boolValue]];
        }
        
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
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
    
    if ([item[@"cell"] isEqualToString:@"OAPublicTransportRouteCell"] || [item[@"cell"] isEqualToString:@"OAPublicTransportPointCell"])
        return UITableViewAutomaticDimension;
    else if ([item[@"cell"] isEqualToString:@"OAPublicTransportShieldCell"])
        return [OAPublicTransportShieldCell getCellHeight:tableView.frame.size.width route:_transportHelper.getRoutes[_routeIndex] needsSafeArea:NO];
    return 44.0;
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
