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
    
    BOOL _flat;
    
    NSDictionary *_pointsMap;
    NSArray *_activePoints;
    BOOL _runningType;
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
        
        if (param)
            _flat = ((NSNumber *)param).boolValue;
        else
            _flat = NO;
        
        _runningType = -1;
        
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
    [self setupViewInternal];
    [tblView reloadData];
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
                OARTargetPoint *start = [[OATargetPointsHelper sharedInstance] getPointToStart];
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
}

- (int) sectionNumber:(int)type
{
    if (type == LPW_TARGETS || type == LPW_ANY)
        return 0;
    else if (type == LPW_WAYPOINTS)
        return 1;
    else if (type == LPW_POI)
        return 2;
    else if (type == LPW_FAVORITES)
        return 3;
    else if (type == LPW_ALARMS)
        return 4;
    else
        return -1;
}

- (int) sectionType:(int)section
{
    for (NSNumber *point in _pointsMap.allKeys)
        if ([self sectionNumber:point.intValue] == section)
            return point.intValue;

    return 0;
}

- (BOOL) onButtonClick:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSIndexPath *indexPath = [self decodePos:btn.tag];

    id item = _pointsMap[@([self sectionType:(int)indexPath.section])][indexPath.row];
    if ([item isKindOfClass:[OARadiusItem class]])
    {
        OARadiusItem *radiusItem = (OARadiusItem *)item;
        if (radiusItem.type == LPW_POI)
        {
        
        }
        else
        {
            
        }
    }
    
    return NO;
}

- (BOOL) onButtonExClick:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    NSIndexPath *indexPath = [self decodePos:btn.tag];
    
    id item = _pointsMap[@([self sectionType:(int)indexPath.section])][indexPath.row];
    if ([item isKindOfClass:[OARadiusItem class]])
    {
        
    }
    
    return NO;
}

/*
- (BOOL) onSwitchClick:(id)sender
{
    UISwitch *sw = (UISwitch *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
    [self setVisibility:indexPath visible:sw.on collapsed:NO];
    
    NSDictionary* data = tableData[indexPath.section][@"cells"][indexPath.row];
    OAMapWidgetRegInfo *r = [_mapWidgetRegistry widgetByKey:data[@"key"]];
    if (r && r.widget)
        [tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    return NO;
}

- (void) setVisibility:(NSIndexPath *)indexPath visible:(BOOL)visible collapsed:(BOOL)collapsed
{
    NSDictionary* data = tableData[indexPath.section][@"cells"][indexPath.row];
    NSString *key = data[@"key"];
    if (key)
    {
        OAMapWidgetRegInfo *r = [_mapWidgetRegistry widgetByKey:key];
        if (r)
        {
            [_mapWidgetRegistry setVisibility:r visible:visible collapsed:collapsed];
            [[OARootViewController instance].mapPanel recreateControls];
        }
        else if ([key isEqualToString:@"always_center_position_on_map"])
        {
            [_settings.centerPositionOnMap set:visible];
        }
        else if ([key isEqualToString:@"map_widget_transparent"])
        {
            [_settings.transparentMapTheme set:visible];
        }
        [self setupViewInternal];
    }
}
*/

- (int) encodePos:(NSIndexPath *)indexPath
{
    return indexPath.section << 10 | indexPath.row;
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

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _pointsMap.allKeys.count;
}


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_pointsMap[@([self sectionType:(int)section])] count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = _pointsMap[@([self sectionType:(int)indexPath.section])][indexPath.row];

    UITableViewCell* outCell = nil;
    // Radius item
    if ([item isKindOfClass:[OARadiusItem class]])
    {
        OARadiusItem *radiusItem = (OARadiusItem *)item;
        int type = radiusItem.type;
        if (radiusItem.type == LPW_POI)
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
            cell.progressView.hidden = [self encodePos:indexPath] != _runningType;

            cell.switchView.hidden = ![_waypointHelper isTypeConfigurable:type];
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            BOOL checked = [_waypointHelper isTypeEnabled:type];
            if (!cell.switchView.hidden)
            {
                cell.switchView.on = checked;
                cell.switchView.enabled = _runningType == -1;
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
            BOOL startPoint = p.type == LPW_TARGETS && ((OARTargetPoint *) point).start;
            if (!startPoint)
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
                UIColor *color = UIColorFromRGBA(color_secondary_text_light_argb);
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
                pointDescription = [@"  •  " stringByAppendingString:pointDescription];
            
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
                UIColor *color = UIColorFromRGBA(color_secondary_text_light_argb);
                [descAttrStr addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, descAttrStr.length)];
                [descAttrStr addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"AvenirNext-Medium" size:11] range:NSMakeRange(0, descAttrStr.length)];
            }
            cell.descLabel.attributedText = descAttrStr;

            cell.moreButton.hidden = YES;
            
            OATargetPointsHelper *targetPointsHelper = [OATargetPointsHelper sharedInstance];
            BOOL canRemove = [targetPointsHelper getIntermediatePoints].count > 0;
            
            cell.removeButton.hidden = NO;
            cell.removeButton.enabled = canRemove;
            cell.removeButton.alpha = canRemove ? 1.0 : 0.5;
            [cell.removeButton removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            cell.removeButton.tag = [self encodePos:indexPath];
            [cell.removeButton addTarget:self action:@selector(onButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        }
        outCell = cell;
    }
    
    /*
    UITableViewCell* outCell = nil;
    if ([data[@"type"] isEqualToString:@"OAAppModeCell"])
    {
        if (!_appModeCell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAAppModeCell" owner:self options:nil];
            _appModeCell = (OAAppModeCell *)[nib objectAtIndex:0];
            _appModeCell.showDefault = YES;
            _appModeCell.selectedMode = [OAAppSettings sharedManager].applicationMode;
            _appModeCell.delegate = self;
        }
        
        outCell = _appModeCell;
    }
    else if ([data[@"type"] isEqualToString:@"OASettingSwitchCell"])
    {
        static NSString* const identifierCell = @"OASettingSwitchCell";
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingSwitchCell" owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [self updateSettingSwitchCell:cell data:data];
            
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = ((NSNumber *)data[@"selected"]).boolValue;
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(onSwitchClick:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    */
    return outCell;
}

- (void) updateSettingSwitchCell:(OASettingSwitchCell *)cell data:(NSDictionary *)data
{
    UIImage *img = nil;
    NSString *imgName = data[@"img"];
    if (imgName)
    {
        UIColor *color = nil;
        if (data[@"color"] != [NSNull null])
            color = data[@"color"];
        
        if (color)
            img = [OAUtilities tintImageWithColor:[UIImage imageNamed:imgName] color:color];
        else
            img = [UIImage imageNamed:imgName];
    }
    
    cell.textView.text = data[@"title"];
    NSString *desc = data[@"description"];
    cell.descriptionView.text = desc;
    cell.descriptionView.hidden = desc.length == 0;
    cell.imgView.image = img;
    cell.secondaryImgView.image = data[@"secondaryImg"] != [NSNull null] ? [UIImage imageNamed:data[@"secondaryImg"]] : nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSDictionary* data = tableData[section][@"cells"][0];
    if ([data[@"type"] isEqualToString:@"OAAppModeCell"])
        return 0.01;
    else
        return 34.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    OAWaypointsViewController *waypointsViewController;
    NSDictionary* data = tableData[indexPath.section][@"cells"][indexPath.row];
    if ([data[@"type"] isEqualToString:@"OASettingSwitchCell"])
    {
        OAMapWidgetRegInfo *r = [_mapWidgetRegistry widgetByKey:data[@"key"]];
        if (r && r.widget)
        {
            //waypointsViewController = [[OAWaypointsViewController alloc] initWithWaypointsScreen:EWaypointsScreenVisibility param:data[@"key"]];
        }
        else
        {
            OASettingSwitchCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            BOOL visible = !cell.switchView.isOn;
            [cell.switchView setOn:visible animated:YES];
            [self onSwitchClick:cell.switchView];
        }
    }
    
    if (waypointsViewController)
        [waypointsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    */
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

