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
#import "OAUtilities.h"
#import "OAColors.h"

#import "OASettingSwitchCell.h"
#import "OARadiusCell.h"
#import "OARadiusCellEx.h"
#import "OAWaypointHeaderCell.h"
#import "OAWaypointCell.h"

#import "OAWaypointHelper.h"
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

@interface OAWaypointsMainScreen ()

@end

@implementation OAWaypointsMainScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAWaypointHelper *_waypointHelper;
    OATargetPointsHelper *_targetPointsHelper;
    
    BOOL _flat;
    
    NSArray<NSNumber *> *_sections;
    NSDictionary *_pointsMap;
    NSArray *_activePoints;
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
        
        title = OALocalizedString(@"gpx_waypoints");
        waypointsScreen = EWaypointsScreenMain;
        
        vwController = viewController;
        tblView = tableView;
        //tblView.separatorInset = UIEdgeInsetsMake(0, 44, 0, 0);
        
        [self initData];
    }
    return self;
}

- (void) initData
{
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
        [tblView reloadSections:[[NSIndexSet alloc] initWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
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

- (NSArray *) getActivePoints:(NSDictionary *)pointsMap
{
    NSMutableArray *activePoints = [NSMutableArray array];
    for (id p in pointsMap.allValues)
    {
        if ([p isKindOfClass:[OALocationPointWrapper class]])
        {
            OALocationPointWrapper *w = (OALocationPointWrapper *)p;
            if (w.type == LPW_TARGETS)
                [activePoints addObject:p];
        }
    }
    return activePoints;
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
    _pointsMap = [self getPoints];
    _activePoints = [self getActivePoints:_pointsMap];

    NSMutableArray<NSNumber *> *sections = [NSMutableArray array];
    for (int i = 0; i < LPW_MAX; i++)
    {
        if ([_pointsMap[@(i)] count] > 0)
            [sections addObject:@(i)];
    }
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

- (void) updateRouteInfoMenu
{
    [[OARootViewController instance].mapPanel updateRouteInfo];
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

- (void) deleteItem:(NSIndexPath *)indexPath
{
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    if ([item isKindOfClass:[OALocationPointWrapper class]])
    {
        OALocationPointWrapper *point = (OALocationPointWrapper *)item;
        if (point.type == LPW_TARGETS)
        {
            /*
             [_pointsMap[@(LPW_TARGETS)] removeObject:point];
             StableArrayAdapter stableAdapter = (StableArrayAdapter) adapter;
             if (helper != null && helper.helperCallbacks != null && needCallback) {
             helper.helperCallbacks.deleteWaypoint(stableAdapter.getPosition(item));
             }
             */
            [self updateRouteInfoMenu];
        }
        else
        {
            [_waypointHelper.deletedPoints addObject:point];
            [_waypointHelper removeVisibleLocationPoint:point];

            [self setupViewInternal];

            [tblView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];

            NSArray<NSIndexPath *> *visiblePaths = [tblView indexPathsForVisibleRows];
            for (NSIndexPath *indexPath in visiblePaths)
            {
                UITableViewCell *cell = [tblView cellForRowAtIndexPath:indexPath];
                if ([cell isKindOfClass:[OAWaypointCell class]])
                {
                    [self updateWaypointCellButton:(OAWaypointCell *)cell indexPath:indexPath];
                }
            }
        }
    }
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
        OALocationPointWrapper *point = (OALocationPointWrapper *)item;
        BOOL targets = point.type == LPW_TARGETS;
        BOOL notFlatTargets = targets && !_flat;
        BOOL startPoint = notFlatTargets && ((OARTargetPoint *) point.point).start;

        if (btn.enabled)
        {
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
                [self deleteItem:indexPath];
            }
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

- (void) updateWaypointCellButton:(OAWaypointCell *)cell indexPath:(NSIndexPath *)indexPath
{
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    if ([item isKindOfClass:[OALocationPointWrapper class]])
    {
        OALocationPointWrapper *p = (OALocationPointWrapper *)item;
        
        BOOL targets = p.type == LPW_TARGETS;
        //BOOL notFlatTargets = targets && !_flat;
        //BOOL startPoint = notFlatTargets && ((OARTargetPoint *) point).start;
        BOOL canRemove = !targets || [_targetPointsHelper getIntermediatePoints].count > 0;
        
        cell.removeButton.hidden = NO;
        cell.removeButton.enabled = canRemove;
        cell.removeButton.alpha = canRemove ? 1.0 : 0.5;
        [cell.removeButton removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
        cell.removeButton.tag = [self encodePos:indexPath];
        [cell.removeButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
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
            static NSString* const identifierCell = @"OARadiusCellEx";
            OARadiusCellEx* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OARadiusCellEx" owner:self options:nil];
                cell = (OARadiusCellEx *)[nib objectAtIndex:0];
            }
            if (cell)
            {
                NSString *desc = [_app getFormattedDistance:[_waypointHelper getSearchDeviationRadius:type]];
                [cell setButtonLeftTitle:[OALocalizedString(@"search_radius_proximity") stringByAppendingString:@":"] description:desc];
                
                OAPOIFiltersHelper *helper = [OAPOIFiltersHelper sharedInstance];
                NSString *descEx = [helper isShowingAnyPoi] ? OALocalizedString(@"poi") : [helper getSelectedPoiFiltersName];
                [cell setButtonRightTitle:[OALocalizedString(@"res_type") stringByAppendingString:@":"] description:descEx];

                [cell.buttonLeft removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
                cell.buttonLeft.tag = [self encodePos:indexPath];
                [cell.buttonLeft addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];

                [cell.buttonRight removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
                cell.buttonRight.tag = [self encodePos:indexPath];
                [cell.buttonRight addTarget:self action:@selector(onButtonExClick:) forControlEvents:UIControlEventTouchUpInside];
            }
            outCell = cell;
        }
        else
        {
            static NSString* const identifierCell = @"OARadiusCell";
            OARadiusCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OARadiusCell" owner:self options:nil];
                cell = (OARadiusCell *)[nib objectAtIndex:0];
            }
            if (cell)
            {
                cell.title.text = OALocalizedString(@"search_radius_proximity");
                NSString *desc = [_app getFormattedDistance:[_waypointHelper getSearchDeviationRadius:type]];
                [cell.button setTitle:desc forState:UIControlStateNormal];
                [cell.button removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
                cell.button.tag = [self encodePos:indexPath];
                [cell.button addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
            }
            outCell = cell;
        }
    }
    // Category item
    else if ([item isKindOfClass:[NSNumber class]])
    {
        int type = ((NSNumber *)item).intValue;
        static NSString* const identifierCell = @"OAWaypointHeaderCell";
        OAWaypointHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAWaypointHeaderCell" owner:self options:nil];
            cell = (OAWaypointHeaderCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            OAWaypointsViewControllerRequest *request = [OAWaypointsViewController getRequest];
            cell.progressView.hidden = request ? type != request.type : YES;

            cell.switchView.hidden = ![_waypointHelper isTypeConfigurable:type];
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            BOOL checked = [_waypointHelper isTypeEnabled:type];
            if (!cell.switchView.hidden)
            {
                cell.switchView.on = checked;
                cell.switchView.enabled = !request;
                cell.switchView.tag = [self encodePos:indexPath];
                [cell.switchView addTarget:self action:@selector(onSwitchClick:) forControlEvents:UIControlEventValueChanged];
            }

            UIButton *moreBtn = cell.imageButton;
            [moreBtn removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            if (type == LPW_TARGETS)
            {
                moreBtn.tag = [self encodePos:indexPath];
                [moreBtn addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
                moreBtn.hidden = NO;
            }
            else
            {
                moreBtn.hidden = YES;
            }

            cell.titleView.text = [self getHeader:type checked:checked];
            [cell updateLayout];
        }
        outCell = cell;
    }
    // Location point
    else if ([item isKindOfClass:[OALocationPointWrapper class]])
    {
        OALocationPointWrapper *p = (OALocationPointWrapper *)item;
        id<OALocationPoint> point = p.point;
        static NSString* const identifierCell = @"OAWaypointCell";
        OAWaypointCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAWaypointCell" owner:self options:nil];
            cell = (OAWaypointCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
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
            if (distAttrStr)
                [descAttrStr appendAttributedString:distAttrStr];
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
                [descAttrStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-Regular" size:14] range:NSMakeRange(0, descAttrStr.length)];
            }
            cell.descLabel.attributedText = descAttrStr;

            cell.moreButton.hidden = YES;
            
            [self updateWaypointCellButton:cell indexPath:indexPath];
        }
        outCell = cell;
    }

    return outCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = _pointsMap[_sections[indexPath.section]][indexPath.row];
    OAWaypointsViewController *waypointsViewController;

    if ([item isKindOfClass:[OARadiusItem class]])
    {
        OARadiusItem *radiusItem = (OARadiusItem *)item;
        int type = radiusItem.type;
        if (type != LPW_POI)
        {
            waypointsViewController = [[OAWaypointsViewController alloc] initWithWaypointsScreen:EWaypointsScreenRadius param:@(type)];
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
    
    if (waypointsViewController)
        [waypointsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

