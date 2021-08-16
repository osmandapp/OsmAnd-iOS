//
//  OAWaypointsMainScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 14/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAWaypointsMainScreen.h"
#import "OAWaypointsViewController.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OAMapActions.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OATargetOptionsBottomSheetViewController.h"
#import "OAWaypointUIHelper.h"

#import "MGSwipeButton.h"
#import "OARadiusCell.h"
#import "OARadiusCellEx.h"
#import "OAWaypointHeaderCell.h"
#import "OAWaypointCell.h"

#import "OAWaypointHelper.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"
#import "OAPointDescription.h"
#import "OALocationServices.h"
#import "OALocationPointWrapper.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OAFavoriteItem.h"

@interface OARadiusItem : NSObject

@property (nonatomic) int type;

- (instancetype) initWithType:(int)type;

@end

@implementation OARadiusItem

- (instancetype) initWithType:(int)type
{
    self = [super init];
    if (self)
    {
        _type = type;
    }
    return self;
}

@end

@interface OAWaypointsMainScreen () <OARouteInformationListener, MGSwipeTableCellDelegate, OATargetOptionsDelegate>

@end

@implementation OAWaypointsMainScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAWaypointHelper *_waypointHelper;
    OATargetPointsHelper *_targetPointsHelper;
    
    BOOL _flat;
    BOOL _calculatingRoute;
    
    NSArray<NSNumber *> *_sections;
    NSDictionary *_pointsMap;
}

@synthesize waypointsScreen, tableData, vwController, tblView, title;

- (id) initWithTable:(UITableView *)tableView viewController:(OAWaypointsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _waypointHelper = [OAWaypointHelper sharedInstance];
        _targetPointsHelper = [OATargetPointsHelper sharedInstance];
        
        if (param)
            _flat = ((NSNumber *)param).boolValue;
        else
            _flat = NO;
        
        _calculatingRoute = NO;
        
        title = OALocalizedString(@"gpx_waypoints");
        waypointsScreen = EWaypointsScreenMain;
        
        vwController = viewController;
        tblView = tableView;
        
        tblView.allowsSelectionDuringEditing = YES;
        tblView.sectionFooterHeight = UITableViewAutomaticDimension;
        tblView.tableFooterView = nil;
        //tblView.separatorInset = UIEdgeInsetsMake(0, 44, 0, 0);
        
        UIButton *okButton = vwController.okButton;
        [okButton setTitle:nil forState:UIControlStateNormal];
        okButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        okButton.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 12);
        [self updateModeButton];
        okButton.hidden = NO;
        
        [self initData];
    }
    return self;
}

- (void) updateModeButton
{
    UIButton *okButton = vwController.okButton;
    if (_flat)
        [okButton setImage:[UIImage imageNamed:@"ic_tree_list_dark"] forState:UIControlStateNormal];
    else
        [okButton setImage:[UIImage imageNamed:@"ic_flat_list_dark"] forState:UIControlStateNormal];
}

- (void) initData
{
}

- (void) initView
{
    [[OARoutingHelper sharedInstance] addListener:self];
    
    [tblView setEditing:YES];
}

- (void) deinitView
{
    [[OARoutingHelper sharedInstance] removeListener:self];

    [tblView setEditing:NO];
}

- (void) setupView
{
    [self processRequest:YES];
    
    [self setupViewInternal];
    [tblView reloadData];
}

- (void) processRequest:(BOOL)reload
{
    OAWaypointsViewControllerRequest __block *request = [OAWaypointsViewController getRequest];
    if (request)
    {
        switch (request.action)
        {
            case EWaypointsViewControllerSelectPOIAction:
            {
                [OAWaypointsViewController resetRequest];
                [self selectPoi:request.type enable:request.param.boolValue];
                break;
            }
            case EWaypointsViewControllerChangeRadiusAction:
            {
                [_waypointHelper setSearchDeviationRadius:request.type radius:request.param.intValue];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [_waypointHelper recalculatePoints:request.type];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (request == [OAWaypointsViewController getRequest])
                            [OAWaypointsViewController resetRequest];
                        
                        [self setupView];
                    });
                });
                break;
            }
            case EWaypointsViewControllerEnableTypeAction:
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [_waypointHelper enableWaypointType:request.type enable:request.param.boolValue];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (request == [OAWaypointsViewController getRequest])
                            [OAWaypointsViewController resetRequest];
                        
                        if (reload)
                            [self setupView];
                        else
                            [self reloadTypeSection:request.type];
                    });
                });
                break;
            }
            default:
                break;
        }
    }
}

- (void) reloadTypeSection:(int)type
{
    [self setupViewInternal];
    int section = [self sectionByType:type];
    if (section != -1)
    {
        [tblView beginUpdates];
        [tblView reloadSections:[[NSIndexSet alloc] initWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tblView endUpdates];
    }
}

- (BOOL) hasTargetPoints
{
    NSArray *targets = _pointsMap[@(LPW_TARGETS)];
    return targets && targets.count > 0;
}

- (NSDictionary *) getPoints
{
    NSDictionary *points;
    if (_flat)
        points = @{@(LPW_ANY) : [_waypointHelper getAllPoints]};
    else
        points = [self getStandardPoints];

    return points;
}

- (NSDictionary *) getStandardPoints
{
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    BOOL rc = [_waypointHelper isRouteCalculated];
    for (int i = 0; i < LPW_MAX; i++)
    {
        NSMutableArray *points = [NSMutableArray array];
        NSArray<OALocationPointWrapper *> *tp = [_waypointHelper getWaypoints:i];
        if ((rc || i == LPW_WAYPOINTS || i == LPW_TARGETS)
            && [_waypointHelper isTypeVisible:i])
        {
            [points addObject:@(i)];
            if (i == LPW_TARGETS)
            {
                OARTargetPoint *start = [_targetPointsHelper getPointToStart];
                if (!start)
                {
                    CLLocation *loc = _app.locationServices.lastKnownLocation;
                    if (!loc)
                        loc = [[OARootViewController instance].mapPanel.mapViewController getMapLocation];
                    
                    start = [OARTargetPoint createStartPoint:loc name:[[OAPointDescription alloc] initWithType:POINT_TYPE_MY_LOCATION name:OALocalizedString(@"shared_string_my_location")]];
                }
                else
                {
                    NSString *oname = [start getOnlyName].length > 0 ? [start getOnlyName] : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"map_settings_map"), [NSString stringWithFormat:@"%@ %.3f %@ %.3f", OALocalizedString(@"Lat"), [start getLatitude], OALocalizedString(@"Lon"), [start getLongitude]]];
                    
                    start = [OARTargetPoint createStartPoint:[[CLLocation alloc] initWithLatitude:[start getLatitude] longitude:[start getLongitude]] name:[[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:oname]];
                }
                [points addObject:[[OALocationPointWrapper alloc] initWithRouteCalculationResult:nil type:LPW_TARGETS point:start deviationDistance:0 routeIndex:0]];
            }
            else if ((i == LPW_POI || i == LPW_FAVORITES || i == LPW_WAYPOINTS) && rc)
            {
                if ([_waypointHelper isTypeEnabled:i])
                    [points addObject:[[OARadiusItem alloc] initWithType:i]];
            }
            if (tp.count > 0)
                [points addObjectsFromArray:tp];
        }
        res[@(i)] = points;
    }
    return res;
}

- (void) setupViewInternal
{
    NSMutableDictionary *points = [[self getPoints] mutableCopy];

    NSMutableArray<NSNumber *> *sections = [NSMutableArray array];
    if (_flat)
    {
        [sections addObject:@(LPW_ANY)];
    }
    else
    {
        for (int i = 0; i < LPW_MAX; i++)
        {
            if (_calculatingRoute && i != LPW_TARGETS && i != LPW_WAYPOINTS && _pointsMap[@(i)])
                points[@(i)] = _pointsMap[@(i)];
            
            if ([points[@(i)] count] > 0)
                [sections addObject:@(i)];
        }
    }
    _pointsMap = points;
    _sections = [NSArray arrayWithArray:sections];
}

- (int) sectionByType:(int)type
{
    for (int i = 0; i < _sections.count; i++)
    {
        if (_sections[i].intValue == type)
            return i;
    }
    return  -1;
}

- (void) selectPoi:(int)type enable:(BOOL)enable
{
    if (![[OAPOIFiltersHelper sharedInstance] isPoiFilterSelectedByFilterId:CUSTOM_FILTER_ID])
    {
        OAWaypointsViewController *waypointsViewController = [[OAWaypointsViewController alloc] initWithWaypointsScreen:EWaypointsScreenPOI param:@NO];
        [waypointsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    }
    else
    {
        [OAWaypointsViewController setRequest:EWaypointsViewControllerEnableTypeAction type:type param:@(enable)];
        [self processRequest:NO];
    }
}

- (void) updateRoute
{
    _calculatingRoute = YES;
    [self reloadDataAnimated:YES];
    
    [_targetPointsHelper updateRouteAndRefresh:YES];
}

- (void) updateRouteInfoMenu
{
    [[OARootViewController instance].mapPanel updateRouteInfo];
}

- (void) closeRouteInfoMenu
{
    [[OARootViewController instance].mapPanel closeRouteInfo];
}

- (void) updateControls
{
    [self setupView];
    [self updateRouteInfoMenu];
}

- (void) replaceStartWithFirstIntermediate
{
    NSArray<OARTargetPoint *> *intermediatePoints = [_targetPointsHelper getIntermediatePointsWithTarget];
    OARTargetPoint *firstIntermediate = intermediatePoints[0];
    intermediatePoints = [intermediatePoints subarrayWithRange:NSMakeRange(1, intermediatePoints.count - 1)];
    [_targetPointsHelper setStartPoint:[[CLLocation alloc] initWithLatitude:[firstIntermediate getLatitude] longitude:[firstIntermediate getLongitude]] updateRoute:NO name:[firstIntermediate getPointDescription]];
     [_targetPointsHelper reorderAllTargetPoints:intermediatePoints updateRoute:YES];
    
    [self updateControls];
}

- (void) updateVisibleCells
{
    NSArray<NSIndexPath *> *visiblePaths = [tblView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths)
    {
        UITableViewCell *cell = [tblView cellForRowAtIndexPath:indexPath];
        
        if ([cell isKindOfClass:[OAWaypointCell class]])
        {
            [self updateWaypointCell:(OAWaypointCell *)cell indexPath:indexPath];
        }
        else if ([cell isKindOfClass:[OARadiusCell class]])
        {
            [self updateRadiusCell:(OARadiusCell *)cell indexPath:indexPath];
        }
        else if ([cell isKindOfClass:[OARadiusCellEx class]])
        {
            [self updateRadiusCellEx:(OARadiusCellEx *)cell indexPath:indexPath];
        }
        else if ([cell isKindOfClass:[OAWaypointHeaderCell class]])
        {
            [self updateWaypointHeaderCell:(OAWaypointHeaderCell *)cell indexPath:indexPath];
        }
        
        [cell setNeedsLayout];
    }
}

- (void) deleteItem:(NSIndexPath *)indexPath
{
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];

    OALocationPointWrapper *point = (OALocationPointWrapper *)item;
    BOOL targets = point.type == LPW_TARGETS;
    BOOL notFlatTargets = targets && !_flat;
    BOOL startPoint = notFlatTargets && ((OARTargetPoint *) point.point).start;
    
    if (notFlatTargets && startPoint)
    {
        if (![_targetPointsHelper getPointToStart])
        {
            if ([_targetPointsHelper getIntermediatePoints].count > 0)
                [self replaceStartWithFirstIntermediate];
        }
        else
        {
            [_targetPointsHelper setStartPoint:nil updateRoute:YES name:nil];
            [self updateControls];
        }
    }
    else
    {
        BOOL needUpdateRoute = NO;
        if (point.type == LPW_TARGETS)
        {
            NSMutableArray *points;
            if (!_flat)
                points = [NSMutableArray arrayWithArray:_pointsMap[@(LPW_TARGETS)]];
            else
                points = [NSMutableArray arrayWithArray:_pointsMap[@(LPW_ANY)]];

            [points removeObject:point];
            
            if (!_flat && points.count < 3)
            {
                [vwController closeDashboard];
                [[OARootViewController instance].mapPanel.mapActions stopNavigationWithoutConfirm];
                [_targetPointsHelper removeAllWayPoints:NO clearBackup:YES];
                [self closeRouteInfoMenu];
                return;
            }
            else
            {
                [self updateTargets:points updateRoute:NO];
                [self updateRouteInfoMenu];
                needUpdateRoute = YES;
            }
        }
        else
        {
            [_waypointHelper.deletedPoints addObject:point];
            [_waypointHelper removeVisibleLocationPoint:point];
        }
        
        NSInteger numberOfSections = _sections.count;
        NSInteger rowsCount = [_pointsMap[_sections[indexPath.section]] count];
        [self setupViewInternal];
        NSInteger updatedRowsCount = [_pointsMap[_sections[indexPath.section]] count];
        if (numberOfSections != _sections.count || (rowsCount - updatedRowsCount != 1))
        {
            [tblView reloadData];
        }
        else
        {
            [tblView beginUpdates];
            [tblView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
            [tblView endUpdates];

            [self updateVisibleCells];
        }
        
        if (needUpdateRoute)
            [self updateRoute];
    }
}

- (void) updateTargets:(NSArray *)items updateRoute:(BOOL)updateRoute
{
    NSMutableArray<OARTargetPoint *> *allTargets = [NSMutableArray array];
    OARTargetPoint *start = nil;
    for (id item in items)
    {
        if ([item isKindOfClass:[OALocationPointWrapper class]])
        {
            OALocationPointWrapper *p = (OALocationPointWrapper *)item;
            if ([p.point isKindOfClass:[OARTargetPoint class]])
            {
                OARTargetPoint *t = (OARTargetPoint *) p.point;
                if (t.start)
                    start = t;
                else
                    t.intermediate = YES;
                
                [allTargets addObject:t];
            }
        }
    }
    if (allTargets.count > 0)
        allTargets[allTargets.count - 1].intermediate = NO;
    
    if (start)
    {
        int startInd = (int)[allTargets indexOfObject:start];
        OARTargetPoint *first = allTargets[0];
        [allTargets removeObjectAtIndex:0];
        if (startInd != 0)
        {
            start.start = NO;
            start.intermediate = startInd != (NSInteger) allTargets.count - 1;
            if (![_targetPointsHelper getPointToStart])
            {
                [start.pointDescription setName:[OAPointDescription getLocationNamePlain:[start getLatitude] lon:[start getLongitude]]];
            }
            first.start = YES;
            first.intermediate = NO;
            [_targetPointsHelper setStartPoint:[[CLLocation alloc] initWithLatitude:[first getLatitude] longitude:[first getLongitude]] updateRoute:NO name:first.pointDescription];
        }
    }
    
    [_targetPointsHelper reorderAllTargetPoints:allTargets updateRoute:updateRoute];
}

- (BOOL) okButtonPressed
{
    _flat = !_flat;
    [tblView setEditing:!_flat];
    [self updateModeButton];
    
    [self setupView];
    
    return NO;
}

- (BOOL) onButtonClick:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSIndexPath *indexPath = [self decodePos:(int)btn.tag];

    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    if ([item isKindOfClass:[OARadiusItem class]])
    {
        OARadiusItem *radiusItem = (OARadiusItem *)item;
        int type = radiusItem.type;
        OAWaypointsViewController *waypointsViewController = [[OAWaypointsViewController alloc] initWithWaypointsScreen:EWaypointsScreenRadius param:@(type)];
        [waypointsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    }
    else if ([item isKindOfClass:[OALocationPointWrapper class]])
    {
        if (btn.enabled)
            [self deleteItem:indexPath];
    }
    else if ([item isKindOfClass:[NSNumber class]])
    {
        int type = ((NSNumber *)item).intValue;
        if (type == LPW_TARGETS && [self hasTargetPoints])
        {
            [[[OATargetOptionsBottomSheetViewController alloc] initWithDelegate:self] show];
        }
    }

    return NO;
}

- (BOOL) onButtonExClick:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSIndexPath *indexPath = [self decodePos:(int)btn.tag];
    
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    if ([item isKindOfClass:[OARadiusItem class]])
    {
        OARadiusItem *radiusItem = (OARadiusItem *)item;
        int type = radiusItem.type;
        if (type == LPW_POI)
        {
            [OAWaypointsViewController setRequest:EWaypointsViewControllerSelectPOIAction type:LPW_POI param:@YES];
            [self processRequest:NO];
        }
    }
    
    return NO;
}

- (BOOL) onSwitchClick:(id)sender
{
    UISwitch *sw = (UISwitch *)sender;
    int position = (int)sw.tag;
    NSIndexPath *indexPath = [self decodePos:position];
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    
    if ([item isKindOfClass:[NSNumber class]])
    {
        int type = ((NSNumber *)item).intValue;
        if (type == LPW_POI && sw.isOn)
            [OAWaypointsViewController setRequest:EWaypointsViewControllerSelectPOIAction type:LPW_POI param:@(sw.isOn)];
        else
            [OAWaypointsViewController setRequest:EWaypointsViewControllerEnableTypeAction type:type param:@(sw.isOn)];
        
        [self processRequest:NO];
    }

    return NO;
}

- (void) onItemsSwapped:(NSIndexPath *)source destination:(NSIndexPath *)destination
{
    if ([source isEqual:destination])
        return;
    
    id sourceItem = _pointsMap[_sections[source.section]][source.row];
    id destItem = _pointsMap[_sections[destination.section]][destination.row];
    
    if ([sourceItem isKindOfClass:[OALocationPointWrapper class]] && [destItem isKindOfClass:[OALocationPointWrapper class]])
    {
        OALocationPointWrapper *src = (OALocationPointWrapper *)sourceItem;
        
        NSMutableArray<OALocationPointWrapper *> *points = (NSMutableArray<OALocationPointWrapper *> *)_pointsMap[_sections[source.section]];
        [points removeObjectAtIndex:source.row];
        [points insertObject:src atIndex:destination.row];
        
        [self updateTargets:points updateRoute:NO];
    }
}

- (int) encodePos:(NSIndexPath *)indexPath
{
    return (int)(indexPath.section << 10 | indexPath.row);
}

- (NSIndexPath *) decodePos:(int)position
{
    return [NSIndexPath indexPathForRow:position & 0x3FF inSection:position >> 10];
}

- (NSString *) getHeader:(int)type checked:(BOOL)checked
{
    switch (type)
    {
        case LPW_TARGETS:
            return OALocalizedString(@"targets");
        case LPW_ALARMS:
            return OALocalizedString(@"show_traffic_warnings");
        case LPW_FAVORITES:
            return OALocalizedString(@"my_favorites");
        case LPW_WAYPOINTS:
            return OALocalizedString(@"gpx_waypoints");
        case LPW_POI:
            return OALocalizedString(@"poi");
            
        default:
            return OALocalizedString(@"waypoints");
    }
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    if ([item isKindOfClass:[OARadiusItem class]])
    {
        OARadiusItem *radiusItem = (OARadiusItem *)item;
        if (radiusItem.type != LPW_POI)
        {
            return 44.0;
        }
    }
    else if ([item isKindOfClass:[NSNumber class]])
    {
        return 44.0;
    }
    return 50.0;
}

- (void) updateWaypointCell:(OAWaypointCell * _Nonnull )cell indexPath:(NSIndexPath * _Nonnull )indexPath
{
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    if ([item isKindOfClass:[OALocationPointWrapper class]])
    {
        OALocationPointWrapper *p = (OALocationPointWrapper *)item;
        id<OALocationPoint> point = p.point;

        if (p.type == LPW_TARGETS)
        {
            cell.delegate = self;
            cell.allowsSwipeWhenEditing = YES;
        }
        
        cell.leftIcon.image = [p getImage:NO];
        
        NSString *descr;
        OAPointDescription *pd = [point getPointDescription];
        if (pd.name.length == 0)
            descr = pd.typeName;
        else
            descr = pd.name;
        
        cell.titleLabel.text = descr;
        
        int dist = -1;
        BOOL startPnt = p.type == LPW_TARGETS && ((OARTargetPoint *) point).start;
        if (!startPnt)
        {
            if (![_waypointHelper isRouteCalculated])
            {
                [[OARootViewController instance].mapPanel.mapViewController getMapLocation];
                dist = [[[CLLocation alloc] initWithLatitude:[point getLatitude] longitude:[point getLongitude]] distanceFromLocation:[[OARootViewController instance].mapPanel.mapViewController getMapLocation]];
            }
            else
            {
                dist = [_waypointHelper getRouteDistance:p];
            }
        }
        
        NSString *distStr = nil;
        if (dist > 0)
            distStr = [_app getFormattedDistance:dist];
        
        NSString *deviationStr = nil;
        UIImage *deviationImg = nil;
        if (dist > 0 && p.deviationDistance > 0) {
            deviationStr = [NSString stringWithFormat:@"+%@", [_app getFormattedDistance:p.deviationDistance]];
            UIColor *color = UIColorFromARGB(color_secondary_text_light_argb);
            if (p.deviationDirectionRight)
                deviationImg = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_small_turn_right"] color:color];
            else
                deviationImg = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_small_turn_left"] color:color];
        }
        
        NSMutableAttributedString *distAttrStr = nil;
        if (distStr)
        {
            distAttrStr = [[NSMutableAttributedString alloc] initWithString:distStr];
            UIColor *color = UIColorFromRGB(color_myloc_distance);
            [distAttrStr addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, distStr.length)];
            [distAttrStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12.0] range:NSMakeRange(0, distAttrStr.length)];
        }
        NSMutableAttributedString *deviationAttrStr = nil;
        if (deviationStr)
        {
            deviationAttrStr = [[NSMutableAttributedString alloc] initWithString:deviationImg ? [@"  " stringByAppendingString:deviationStr] : deviationStr];
            if (deviationImg)
            {
                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = deviationImg;
                NSAttributedString *strWithImage = [NSAttributedString attributedStringWithAttachment:attachment];
                [deviationAttrStr replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:strWithImage];
                [deviationAttrStr addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
            }
        }
        
        NSString *pointDescription = @"";
        switch (p.type)
        {
            case LPW_TARGETS:
            {
                OARTargetPoint *targetPoint = (OARTargetPoint *)p.point;
                if (targetPoint.start)
                    pointDescription = OALocalizedString(@"starting_point");
                else
                    pointDescription = [targetPoint getPointDescription].typeName;
                
                break;
            }
            case LPW_FAVORITES:
            {
                OAFavoriteItem *favPoint = (OAFavoriteItem *)p.point;
                pointDescription = favPoint.favorite->getGroup().isEmpty() ? OALocalizedString(@"favorites") : favPoint.favorite->getGroup().toNSString();
                break;
            }
        }
        
        if ([descr isEqualToString:pointDescription])
            pointDescription = @"";
        
        if (dist > 0 && pointDescription.length > 0)
            pointDescription = [@" •  " stringByAppendingString:pointDescription];
        
        NSMutableAttributedString *descAttrStr = [[NSMutableAttributedString alloc] init];
        if (deviationAttrStr)
        {
            if (descAttrStr.length > 0)
                [descAttrStr appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
            
            [descAttrStr appendAttributedString:deviationAttrStr];
        }
        if (pointDescription.length > 0)
        {
            if (descAttrStr.length > 0)
                [descAttrStr appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
            
            [descAttrStr appendAttributedString:[[NSAttributedString alloc] initWithString:pointDescription]];
        }
        if (descAttrStr.length > 0)
        {
            UIColor *color = UIColorFromARGB(color_secondary_text_light_argb);
            [descAttrStr addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, descAttrStr.length)];
            [descAttrStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:12.0] range:NSMakeRange(0, descAttrStr.length)];
        }
        if (distAttrStr)
        {
            if (descAttrStr.length > 0)
            {
                [distAttrStr appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
                [descAttrStr insertAttributedString:distAttrStr atIndex:0];
            }
            else
            {
                descAttrStr = distAttrStr;
            }
        }
        
        cell.descLabel.attributedText = descAttrStr;
        cell.moreButton.hidden = YES;
        
        BOOL targets = p.type == LPW_TARGETS;
        BOOL canRemove = (!targets || [_targetPointsHelper getIntermediatePoints].count > 0) && !_calculatingRoute;
        
        cell.removeButton.hidden = targets && !_flat;
        cell.removeButton.enabled = canRemove;
        cell.removeButton.alpha = canRemove ? 1.0 : 0.5;
        [cell.removeButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        cell.removeButton.tag = [self encodePos:indexPath];
        [cell.removeButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void) updateRadiusCell:(OARadiusCell * _Nonnull )cell indexPath:(NSIndexPath * _Nonnull )indexPath
{
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    if ([item isKindOfClass:[OARadiusItem class]])
    {
        OARadiusItem *radiusItem = (OARadiusItem *)item;
        int type = radiusItem.type;

        cell.title.text = OALocalizedString(@"search_radius_proximity");
        NSString *desc = [_app getFormattedDistance:[_waypointHelper getSearchDeviationRadius:type]];
        [cell.button setTitle:desc forState:UIControlStateNormal];
        [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        cell.button.tag = [self encodePos:indexPath];
        cell.button.enabled = !_calculatingRoute;
        [cell.button addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void) updateRadiusCellEx:(OARadiusCellEx * _Nonnull )cell indexPath:(NSIndexPath * _Nonnull )indexPath
{
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    if ([item isKindOfClass:[OARadiusItem class]])
    {
        BOOL inProgress = _calculatingRoute;
        
        OARadiusItem *radiusItem = (OARadiusItem *)item;
        int type = radiusItem.type;
        
        NSString *desc = [_app getFormattedDistance:[_waypointHelper getSearchDeviationRadius:type]];
        [cell setButtonLeftTitle:[OALocalizedString(@"search_radius_proximity") stringByAppendingString:@":"] description:desc];
        
        OAPOIFiltersHelper *helper = [OAPOIFiltersHelper sharedInstance];
        NSString *descEx = [helper isShowingAnyPoi] ? OALocalizedString(@"poi") : [helper getSelectedPoiFiltersName];
        [cell setButtonRightTitle:[OALocalizedString(@"res_type") stringByAppendingString:@":"] description:descEx];
        
        [cell.buttonLeft removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        cell.buttonLeft.tag = [self encodePos:indexPath];
        cell.buttonLeft.enabled = !inProgress;
        if (!inProgress)
            [cell.buttonLeft addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell.buttonRight removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        cell.buttonRight.tag = [self encodePos:indexPath];
        cell.buttonRight.enabled = !_calculatingRoute;
        [cell.buttonRight addTarget:self action:@selector(onButtonExClick:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void) updateWaypointHeaderCell:(OAWaypointHeaderCell * _Nonnull )cell indexPath:(NSIndexPath * _Nonnull )indexPath
{
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    if ([item isKindOfClass:[NSNumber class]])
    {
        int type = ((NSNumber *)item).intValue;
        
        OAWaypointsViewControllerRequest *request = [OAWaypointsViewController getRequest];
        BOOL inProgress = _calculatingRoute;
        if (!inProgress && request && type == request.type)
            inProgress = YES;
        
        if (inProgress)
        {
            cell.progressView.hidden = NO;
            [cell.progressView startAnimating];
        }
        else
        {
            cell.progressView.hidden = YES;
            [cell.progressView stopAnimating];
        }
        
        cell.switchView.hidden = ![_waypointHelper isTypeConfigurable:type];
        [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        BOOL checked = [_waypointHelper isTypeEnabled:type];
        if (!cell.switchView.hidden)
        {
            cell.switchView.on = checked;
            cell.switchView.enabled = !inProgress;
            cell.switchView.tag = [self encodePos:indexPath];
            [cell.switchView addTarget:self action:@selector(onSwitchClick:) forControlEvents:UIControlEventValueChanged];
        }
        else
        {
            cell.switchView.enabled = NO;
        }
        
        cell.imageButton.hidden = YES;
        UIButton *optionsBtn = cell.textButton;
        [optionsBtn removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        if (type == LPW_TARGETS)
        {
            [optionsBtn setTitle:OALocalizedString(@"shared_string_options") forState:UIControlStateNormal];
            optionsBtn.tag = [self encodePos:indexPath];
            [optionsBtn addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
            optionsBtn.hidden = NO;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else
        {
            optionsBtn.hidden = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        
        cell.titleView.text = [self getHeader:type checked:checked];
    }
}

- (void) reloadDataAnimated:(BOOL)animated
{
    NSInteger numberOfSections = _sections.count;
    if (!animated || numberOfSections < 4)
    {
        [self setupView];
        return;
    }
    
    [self setupViewInternal];
    if (numberOfSections != _sections.count)
    {
        [tblView reloadData];
        return;
    }
    
    [tblView beginUpdates];
    [tblView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, [tblView numberOfSections] - 1)] withRowAnimation:UITableViewRowAnimationNone];
    [tblView endUpdates];
    
    [self updateVisibleCells];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_pointsMap[_sections[section]] count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];

    UITableViewCell* outCell = nil;
    // Radius item
    if ([item isKindOfClass:[OARadiusItem class]])
    {
        OARadiusItem *radiusItem = (OARadiusItem *)item;
        int type = radiusItem.type;
        if (type == LPW_POI)
        {
            OARadiusCellEx* cell = [tableView dequeueReusableCellWithIdentifier:[OARadiusCellEx getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARadiusCellEx getCellIdentifier] owner:self options:nil];
                cell = (OARadiusCellEx *)[nib objectAtIndex:0];
            }
            if (cell)
            {
                [self updateRadiusCellEx:cell indexPath:indexPath];
            }
            outCell = cell;
        }
        else
        {
            OARadiusCell* cell = [tableView dequeueReusableCellWithIdentifier:[OARadiusCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARadiusCell getCellIdentifier] owner:self options:nil];
                cell = (OARadiusCell *)[nib objectAtIndex:0];
            }
            if (cell)
            {
                [self updateRadiusCell:cell indexPath:indexPath];
            }
            outCell = cell;
        }
    }
    // Category item
    else if ([item isKindOfClass:[NSNumber class]])
    {
        OAWaypointHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAWaypointHeaderCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAWaypointHeaderCell getCellIdentifier] owner:self options:nil];
            cell = (OAWaypointHeaderCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            [self updateWaypointHeaderCell:cell indexPath:indexPath];
        }
        outCell = cell;
    }
    // Location point
    else if ([item isKindOfClass:[OALocationPointWrapper class]])
    {
        OAWaypointCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAWaypointCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAWaypointCell getCellIdentifier] owner:self options:nil];
            cell = (OAWaypointCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 50, 0., 0.);
        }
        if (cell)
        {
            [self updateWaypointCell:cell indexPath:indexPath];
        }
        outCell = cell;
    }

    return outCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    return 1.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    if ([item isKindOfClass:[NSNumber class]] || [item isKindOfClass:[OALocationPointWrapper class]])
        return UITableViewAutomaticDimension;
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    if ([item isKindOfClass:[NSNumber class]] || [item isKindOfClass:[OALocationPointWrapper class]])
        return UITableViewAutomaticDimension;
    return [self heightForRow:indexPath tableView:tableView];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    OAWaypointsViewController *waypointsViewController;

    if ([item isKindOfClass:[OARadiusItem class]])
    {
        if (!_calculatingRoute)
        {
            OARadiusItem *radiusItem = (OARadiusItem *)item;
            int type = radiusItem.type;
            if (type != LPW_POI)
            {
                waypointsViewController = [[OAWaypointsViewController alloc] initWithWaypointsScreen:EWaypointsScreenRadius param:@(type)];
            }
        }
    }
    else if ([item isKindOfClass:[NSNumber class]])
    {
        OAWaypointHeaderCell* cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell.switchView.enabled)
        {
            BOOL visible = !cell.switchView.isOn;
            [cell.switchView setOn:visible animated:YES];
            [self onSwitchClick:cell.switchView];
        }
    }
    else if ([item isKindOfClass:[OALocationPointWrapper class]])
    {
        [vwController closeDashboard];
        
        OALocationPointWrapper *p = (OALocationPointWrapper *)item;
        [OAWaypointUIHelper showOnMap:p];
    }
    
    if (waypointsViewController)
        [waypointsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 0 && indexPath.row > 0;
}

- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 0 && indexPath.row > 0;
}

- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    [self onItemsSwapped:sourceIndexPath destination:destinationIndexPath];
}

- (NSIndexPath *) tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.section == 0 && proposedDestinationIndexPath.row < 1)
        return [NSIndexPath indexPathForRow:1 inSection:0];

    if (proposedDestinationIndexPath.section > 0)
        return [NSIndexPath indexPathForRow:[self tableView:tableView numberOfRowsInSection:0] - 1 inSection:0];

    // Allow the proposed destination.
    return proposedDestinationIndexPath;
}

- (void) tableView:(UITableView *)tableView willBeginReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void) tableView:(UITableView *)tableView didEndReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self updateRoute];
}

- (void) tableView:(UITableView *)tableView didCancelReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL) tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - OARouteInformationListener

- (void) newRouteIsCalculated:(BOOL)newRoute
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL animated = _calculatingRoute;
        _calculatingRoute = NO;
        [self reloadDataAnimated:animated];
    });
}

- (void) routeWasUpdated
{
}

- (void) routeWasCancelled
{
}

- (void) routeWasFinished
{
}

#pragma mark - Swipe Delegate

- (BOOL) swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction;
{
    return !_flat;
}

- (NSArray *) swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction
             swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings
{
    swipeSettings.transition = MGSwipeTransitionDrag;
    expansionSettings.buttonIndex = 0;
    
    if (direction == MGSwipeDirectionRightToLeft)
    {
        //expansionSettings.fillOnTrigger = YES;
        expansionSettings.threshold = 10.0;
        
        CGFloat padding = 15;
        
        NSIndexPath * indexPath = [tblView indexPathForCell:cell];
        
        MGSwipeButton *remove = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"ic_trip_removepoint"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
                                 {
                                     [self deleteItem:indexPath];
                                     return YES;
                                 }];

        return @[remove];
    }
    return nil;
}

- (void) swipeTableCell:(MGSwipeTableCell *)cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive
{
    if (state != MGSwipeStateNone)
        cell.showsReorderControl = NO;
    else
        cell.showsReorderControl = YES;
}

#pragma mark - OATargetOptionsDelegate

- (void) targetOptionsUpdateControls:(BOOL)calculatingRoute
{
    if (calculatingRoute)
        _calculatingRoute = YES;
    
    [self updateControls];
}

@end

