//
//  OARoutePreferencesAvoidRoadsScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARoutePreferencesAvoidRoadsScreen.h"
#import "OARoutePreferencesViewController.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAUtilities.h"
#import "OAAvoidSpecificRoads.h"
#import "OARoutingHelper.h"
#import "OAIconTextButtonCell.h"
#import "OAIconButtonCell.h"
#import "OAColors.h"

#include <OsmAndCore/Utilities.h>

@implementation OARoutePreferencesAvoidRoadsScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAAvoidSpecificRoads *_avoidRoads;
    
    NSArray<NSArray<NSDictionary *> *> *_data;
}

@synthesize preferencesScreen, tableData, vwController, tblView, title;

- (id) initWithTable:(UITableView *)tableView viewController:(OARoutePreferencesViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _avoidRoads = [OAAvoidSpecificRoads instance];
        
        title = OALocalizedString(@"impassable_road");
        preferencesScreen = ERoutePreferencesScreenAvoidRoads;
        
        vwController = viewController;
        tblView = tableView;
        [self initData];
    }
    return self;
}

- (void) initData
{
}

- (void) setupView
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray array];
    
    //avoid_roads_msg
    
    const auto& roads = [_avoidRoads getImpassableRoads];
    
    if (roads.empty())
    {
        [data addObject:@[@{ @"title"  : OALocalizedString(@"shared_string_select_on_map"),
                             @"key"    : @"select_on_map",
                             @"footer" : OALocalizedString(@"avoid_roads_msg"),
                             @"type"   : @"OAIconButtonCell"}] ];
    }
    else
    {
        [data addObject:@[@{ @"title" : OALocalizedString(@"shared_string_select_on_map"),
                             @"key"   : @"select_on_map",
                             @"type"  : @"OAIconButtonCell"}] ];
        
        NSMutableArray *roadList = [NSMutableArray array];
        for (const auto& r : roads)
        {
            [roadList addObject:@{ @"title"  : [self getText:r],
                                   @"key"    : @"road",
                                   @"descr"  : [self getDescr:r],
                                   @"header" : @"",
                                   @"type"   : @"OAIconTextButtonCell"} ];
        }

        /*
        [roadList addObject:@{ @"title"  : @"Road 1",
                               @"key"    : @"1",
                               @"descr"  : @"100 km",
                               @"header" : @"",
                               @"type"   : @"OAIconTextButtonCell"} ];

        [roadList addObject:@{ @"title"  : @"Road 2",
                               @"key"    : @"2",
                               @"descr"  : @"5 km",
                               @"header" : @"",
                               @"type"   : @"OAIconTextButtonCell"} ];
        */
        
        [data addObject:roadList];
    }
    
    _data = [NSArray arrayWithArray:data];
}

- (NSString *) getText:(const std::shared_ptr<const OsmAnd::Road>)road
{
    NSString *lang = [_settings settingPrefMapLanguage];
    if (!lang)
        lang = [OAUtilities currentLang];
    
    auto locale = QString::fromNSString(lang);
    BOOL transliterate = _settings.settingMapLanguageTranslit;
    
    NSString *streetName = road->getName(locale, transliterate).toNSString();
    NSString *refName = road->getRef(locale, transliterate).toNSString();
    NSString *destinationName = @"";//road->getDestinationName(locale, transliterate).toNSString();
    NSString *towards = OALocalizedString(@"towards");

    NSString *name = [OARoutingHelper formatStreetName:streetName ref:refName destination:destinationName towards:towards];
    return !name || name.length == 0 ? OALocalizedString(@"shared_string_road") : name;
}

- (NSString *) getDescr:(const std::shared_ptr<const OsmAnd::Road>)road
{
    CLLocation *mapLocation = [[OARootViewController instance].mapPanel.mapViewController getMapLocation];
    const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(road->points31[0]);
    float dist = [mapLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude]];
    return [_app getFormattedDistance:dist];
}

- (void) removeRoad:(id)sender
{
    if ([sender isKindOfClass:[UIButton class]])
    {
        UIButton *btn = (UIButton *) sender;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSDictionary *data = _data[section][0];
    return data[@"header"] ? 16.0 : 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *data = _data[indexPath.section][indexPath.row];
    NSString *type = data[@"type"];
    NSString *title = data[@"title"];
    NSString *descr = data[@"descr"];
    
    if ([type isEqualToString:@"OAIconTextButtonCell"])
    {
        return [OAIconTextButtonCell getHeight:title descHidden:(!descr || descr.length == 0) detailsIconHidden:NO cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return 50.0;
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSDictionary *data = _data[section][0];
    return data[@"footer"];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *data = _data[indexPath.section][indexPath.row];
    NSString *type = data[@"type"];
    NSString *title = data[@"title"];
    NSString *descr = data[@"descr"];

    if ([type isEqualToString:@"OAIconTextButtonCell"])
    {
        static NSString* const identifierCell = @"OAIconTextButtonCell";
        OAIconTextButtonCell *cell = (OAIconTextButtonCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTextButtonCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(color_icon_color);
            cell.iconView.image = [UIImage imageNamed:@"ic_action_road_works_dark"];
            //cell.detailsIconView.hidden = YES;
        }
        
        if (cell)
        {
            cell.descView.hidden = !descr || descr.length == 0;
            cell.descView.text = descr;
            [cell.buttonView removeTarget:self action:@selector(removeRoad:) forControlEvents:UIControlEventTouchUpInside];
            cell.buttonView.tag = indexPath.row;
            [cell.buttonView addTarget:self action:@selector(removeRoad:) forControlEvents:UIControlEventTouchUpInside];
            [cell.textView setText:title];
        }
        return cell;
    }
    else if ([type isEqualToString:@"OAIconButtonCell"])
    {
        static NSString* const identifierCell = @"OAIconButtonCell";
        OAIconButtonCell *cell = (OAIconButtonCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconButtonCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(color_icon_color);
            cell.iconView.image = [UIImage imageNamed:@"ic_action_road_works_dark"];
            //cell.arrowIconView.hidden = YES;
        }
        
        if (cell)
        {
            [cell.textView setText:title];
        }
        return cell;
    }
    
    return nil;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *data = _data[indexPath.section][indexPath.row];
    NSString *key = data[@"key"];

    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    if ([@"select_on_map" isEqualToString:key])
    {
        [mapPanel openTargetViewWithImpassableRoadSelection];
    }
    else if ([@"road" isEqualToString:key])
    {
        
    }
}

@end
