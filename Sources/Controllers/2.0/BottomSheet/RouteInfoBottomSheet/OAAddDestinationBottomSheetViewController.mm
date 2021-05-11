//
//  OAAddDestinationBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAAddDestinationBottomSheetViewController.h"
#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OATitleIconRoundCell.h"
#import "OACollectionViewCell.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"
#import "OAFavoriteItem.h"
#import "OATargetPointsHelper.h"
#import "OAPointDescription.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OADestinationItemsListViewController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

#define kButtonsDividerTag 150
#define kMessageFieldIndex 1

#define kTitleIconRoundCell @"OATitleIconRoundCell"

@interface OAAddDestinationBottomSheetScreen () <OACollectionViewCellDelegate, OADestinationPointListDelegate>

@end

@implementation OAAddDestinationBottomSheetScreen
{
    OsmAndAppInstance _app;
    OADestinationsHelper *_destinationsHelper;
    OAAddDestinationBottomSheetViewController *vwController;
    OATargetPointsHelper *_pointsHelper;
    NSDictionary* _data;
    
    EOADestinationType _type;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAAddDestinationBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _type = viewController.type;
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAAddDestinationBottomSheetViewController *)viewController
{
    _app = [OsmAndApp instance];
    _destinationsHelper = [OADestinationsHelper instance];
    _pointsHelper = [OATargetPointsHelper sharedInstance];
    
    vwController = viewController;
    tblView = tableView;
    
    [self initData];
}

- (NSArray *) generateFavoritesData
{
    NSMutableArray *arr = [NSMutableArray new];
    [arr addObject:@{
        @"title" : OALocalizedString(@"favorites"),
        @"key" : @"favorites",
        @"color" : UIColorFromRGB(color_primary_purple),
        @"img" : @"ic_custom_favorites"
    }];
    if ([_pointsHelper getHomePoint] && _type != EOADestinationTypeHome)
    {
        OARTargetPoint *home = [_pointsHelper getHomePoint];
        [arr addObject:@{
            @"title" : OALocalizedString(@"home_pt"),
            @"descr" : home.pointDescription.name,
            @"color" : UIColorFromRGB(color_primary_purple),
            @"img" : @"ic_custom_home",
            @"point" : home
        }];
    }
    
    if ([_pointsHelper getWorkPoint] && _type != EOADestinationTypeWork)
    {
        OARTargetPoint *work = [_pointsHelper getWorkPoint];
        [arr addObject:@{
            @"title" : OALocalizedString(@"work_pt"),
            @"descr" : work.pointDescription.name,
            @"color" : UIColorFromRGB(color_primary_purple),
            @"img" : @"ic_custom_work",
            @"point" : work
        }];
    }
    
    
    NSArray *favorites = [self getSortedFavorites];
    for (OAFavoriteItem *item in favorites)
    {
        NSString *groupName = item.favorite->getGroup().toNSString();
        [arr addObject:@{
            @"title" : item.favorite->getTitle().toNSString(),
            @"descr" : groupName == nil || groupName.length == 0 ? OALocalizedString(@"favorites") : groupName,
            @"color" : item.getColor,
            @"img" : @"ic_custom_favorites",
            @"point" : item
        }];
    }
    return [NSArray arrayWithArray:arr];
}

- (NSArray *) generateMarkersData
{
    NSMutableArray *arr = [NSMutableArray new];
    [arr addObject:@{
        @"title" : OALocalizedString(@"map_markers"),
        @"key" : @"markers",
        @"color" : UIColorFromRGB(color_primary_purple),
        @"img" : @"ic_custom_marker"
    }];
    NSArray *markers = [_destinationsHelper sortedDestinationsWithoutParking];
    for (OADestination *item in markers)
    {
        [arr addObject:@{
            @"title" : item.desc,
            @"img" : [item.markerResourceName ? item.markerResourceName : @"ic_destination_pin_1" stringByAppendingString:@"_small"],
            @"point" : item
        }];
    }
    return [NSArray arrayWithArray:arr];
}

- (NSArray *) getSortedFavorites
{
    NSMutableArray *sortedFavoriteItems = [[NSMutableArray alloc] init];
    const auto allFavorites = _app.favoritesCollection->getFavoriteLocations();
    
    for(const auto& favorite : allFavorites)
    {
        OAFavoriteItem* favData = [[OAFavoriteItem alloc] initWithFavorite:favorite];
        [sortedFavoriteItems addObject:favData];
    }
    
    NSArray *sortedArray = [sortedFavoriteItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
        return [[obj1.favorite->getTitle().toNSString() lowerCase] compare:[obj2.favorite->getTitle().toNSString() lowerCase]];
    }];
    
    return sortedArray;
}

- (NSString *) getTitle
{
    switch (_type) {
        case EOADestinationTypeHome:
            return OALocalizedString(@"add_home");
        case EOADestinationTypeWork:
            return OALocalizedString(@"add_work");
        case EOADestinationTypeStart:
            return OALocalizedString(@"add_start");
        case EOADestinationTypeFinish:
            return OALocalizedString(@"add_destination");
        case EOADestinationTypeIntermediate:
            return OALocalizedString(@"add_intermediate");
        default:
            return @"";
    }
}

- (void) setupView
{
    tblView.separatorColor = UIColorFromRGB(color_tint_gray);
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableDictionary *model = [NSMutableDictionary new];
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:@{
                     @"type" : [OABottomSheetHeaderCell getCellIdentifier],
                     @"title" : [self getTitle],
                     @"description" : @""
                     }];
    
    OADestination *parking = _destinationsHelper.getParkingPoint;
    
    [arr addObject:@{
        @"type" : kTitleIconRoundCell,
        @"title" : OALocalizedString(@"shared_string_search"),
        @"img" : @"ic_navbar_search",
        @"key" : @"regular_search",
        @"round_bottom" : @(NO),
        @"round_top" : @(YES)
    }];
    
    [arr addObject:@{
        @"type" : kTitleIconRoundCell,
        @"title" : OALocalizedString(@"shared_string_address"),
        @"img" : @"ic_custom_home",
        @"key" : @"address_search",
        @"round_bottom" : @(parking == nil),
        @"round_top" : @(NO)
    }];
    
    if (parking)
    {
        [arr addObject:@{
            @"type" : kTitleIconRoundCell,
            @"title" : OALocalizedString(@"parking_place"),
            @"img" : @"parking_position",
            @"key" : @"parking",
            @"round_bottom" : @(YES),
            @"round_top" : @(NO)
        }];
    }
    [model setObject:[NSArray arrayWithArray:arr] forKey:@(0)];
    
    [arr removeAllObjects];
    if (_type == EOADestinationTypeStart)
    {
        [arr addObject:@{
            @"type" : kTitleIconRoundCell,
            @"title" : OALocalizedString(@"shared_string_my_location"),
            @"img" : @"map_default_location",
            @"key" : @"my_location",
            @"round_bottom" : @(NO),
            @"round_top" : @(YES),
            @"skip_tint" : @(YES)
        }];
    }
    [arr addObject:@{
        @"type" : kTitleIconRoundCell,
        @"title" : OALocalizedString(@"shared_string_select_on_map"),
        @"img" : @"ic_custom_show_on_map",
        @"key" : @"select_on_map",
        @"round_bottom" : @(YES),
        @"round_top" : @(_type != EOADestinationTypeStart)
    }];
    [model setObject:[NSArray arrayWithArray:arr] forKey:@(1)];
    [arr removeAllObjects];
    
    [arr addObject:@{
        @"type" : [OACollectionViewCell getCellIdentifier],
        @"key" : @"favorites"
    }];
    [model setObject:[NSArray arrayWithArray:arr] forKey:@(2)];
    
    [arr removeAllObjects];
    
    [arr addObject:@{
        @"type" : [OACollectionViewCell getCellIdentifier],
        @"key" : @"markers"
    }];
    [model setObject:[NSArray arrayWithArray:arr] forKey:@(3)];
    
    [arr removeAllObjects];
    [arr addObject:@{
        @"type" : kTitleIconRoundCell,
        @"title" : OALocalizedString(@"swap_points"),
        @"img" : @"ic_custom_swap",
        @"key" : @"swap_points",
        @"round_bottom" : @(YES),
        @"round_top" : @(YES)
    }];
    [model setObject:[NSArray arrayWithArray:arr] forKey:@(4)];
    
    _data = [NSDictionary dictionaryWithDictionary:model];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]] || [item[@"type"] isEqualToString:kTitleIconRoundCell])
    {
        return UITableViewAutomaticDimension;
    }
    else if ([item[@"type"] isEqualToString:[OACollectionViewCell getCellIdentifier]])
    {
        return 60.0;
    }
    else
    {
        return 44.0;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionData = _data[@(section)];
    return sectionData.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]])
    {
        OABottomSheetHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:[OABottomSheetHeaderCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OABottomSheetHeaderCell" owner:self options:nil];
            cell = (OABottomSheetHeaderCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            cell.sliderView.layer.cornerRadius = 3.0;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kTitleIconRoundCell])
    {
        static NSString* const identifierCell = kTitleIconRoundCell;
        OATitleIconRoundCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kTitleIconRoundCell owner:self options:nil];
            cell = (OATitleIconRoundCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            cell.titleView.text = item[@"title"];
            if (![item[@"skip_tint"] boolValue])
            {
                [cell.iconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
                cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            }
            else
            {
                [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
            }
            [cell roundCorners:[item[@"round_top"] boolValue] bottomCorners:[item[@"round_bottom"] boolValue]];
            cell.separatorInset = UIEdgeInsetsMake(0., 32., 0., 20.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OACollectionViewCell getCellIdentifier]])
    {
        OACollectionViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OACollectionViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACollectionViewCell getCellIdentifier] owner:self options:nil];
            cell = (OACollectionViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            cell.collectionView.backgroundColor = UIColor.clearColor;
            if ([item[@"key"] isEqualToString:@"favorites"])
                [cell setData:[self generateFavoritesData]];
            else if ([item[@"key"] isEqualToString:@"markers"])
                [cell setData:[self generateMarkersData]];
            
            cell.delegate = self;
            
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[@(indexPath.section)][indexPath.row];
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 16.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if (![item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]])
        return indexPath;
    else
        return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL selectionDone = NO;
    BOOL showMap = NO;
    NSDictionary *item = [self getItem:indexPath];
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    if ([item[@"key"] isEqualToString:@"regular_search"])
    {
        if (_type == EOADestinationTypeIntermediate)
            [mapPanel openSearch:OAQuickSearchType::INTERMEDIATE];
        else if (_type == EOADestinationTypeFinish)
            [mapPanel openSearch:OAQuickSearchType::DESTINATION];
        else if (_type == EOADestinationTypeStart)
            [mapPanel openSearch:OAQuickSearchType::START_POINT];
        else if (_type == EOADestinationTypeHome)
            [mapPanel openSearch:OAQuickSearchType::HOME];
        else if (_type == EOADestinationTypeWork)
            [mapPanel openSearch:OAQuickSearchType::WORK];
    }
    else if ([item[@"key"] isEqualToString:@"address_search"])
    {
        if (_type == EOADestinationTypeIntermediate)
            [mapPanel openSearch:OAQuickSearchType::INTERMEDIATE location:nil tabIndex:2];
        else if (_type == EOADestinationTypeFinish)
            [mapPanel openSearch:OAQuickSearchType::DESTINATION location:nil tabIndex:2];
        else if (_type == EOADestinationTypeStart)
            [mapPanel openSearch:OAQuickSearchType::START_POINT location:nil tabIndex:2];
        else if (_type == EOADestinationTypeHome)
            [mapPanel openSearch:OAQuickSearchType::HOME location:nil tabIndex:2];
        else if (_type == EOADestinationTypeWork)
            [mapPanel openSearch:OAQuickSearchType::WORK location:nil tabIndex:2];
    }
    else if ([item[@"key"] isEqualToString:@"my_location"])
    {
        selectionDone = YES;
        [_pointsHelper clearStartPoint:YES];
        [_app.data backupTargetPoints];
    }
    else if ([item[@"key"] isEqualToString:@"parking"])
    {
        [self onDestinationSelected:_destinationsHelper.getParkingPoint];
    }
    else if ([item[@"key"] isEqualToString:@"select_on_map"])
    {
        OATargetPointType type = OATargetRouteFinishSelection;
        if (_type == EOADestinationTypeFinish)
            type = OATargetRouteFinishSelection;
        else if (_type == EOADestinationTypeIntermediate)
            type = OATargetRouteIntermediateSelection;
        else if (_type == EOADestinationTypeStart)
            type = OATargetRouteStartSelection;
        else if (_type == EOADestinationTypeHome)
            type = OATargetHomeSelection;
        else if (_type == EOADestinationTypeWork)
            type = OATargetWorkSelection;
        
        [mapPanel openTargetViewWithRouteTargetSelection:type];
        showMap = YES;
    }
    else if ([item[@"key"] isEqualToString:@"swap_points"])
    {
        [mapPanel swapStartAndFinish];
        [self.vwController dismiss];
        return;
    }
    
    if (vwController.delegate)
        [vwController.delegate waypointSelectionDialogComplete:selectionDone showMap:showMap calculatingRoute:NO];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.vwController dismiss];
}

@synthesize vwController;

#pragma mark - OACollectionViewCellDelegate

- (void) onItemSelected:(NSString *)key point:(id)point
{
    if (key && key.length > 0)
    {
        [vwController dismiss];
        OADestinationItemsListViewController *destinations = [[OADestinationItemsListViewController alloc] initWithDestinationType:[key isEqualToString:@"favorites"] ? EOADestinationPointTypeFavorite : EOADestinationPointTypeMarker];
        destinations.delegate = self;
        [[OARootViewController instance].navigationController presentViewController:destinations animated:YES completion:nil];
    }
    else
    {
        if (point)
        {
            if ([point isKindOfClass:OAFavoriteItem.class])
            {
                OAFavoriteItem *favPoint = (OAFavoriteItem *) point;
                [self onFavoriteSelected:favPoint];
            }
            else if ([point isKindOfClass:OADestination.class])
            {
                OADestination *markerPoint = (OADestination *) point;
                [self onDestinationSelected:markerPoint];
            }
            else if ([point isKindOfClass:OARTargetPoint.class])
            {
                OARTargetPoint *target = (OARTargetPoint *) point;
                [self onHomeWorkSelected:target];
            }
        }
    }
}

#pragma mark - OADestinationPointListDelegate

- (void) onFavoriteSelected:(OAFavoriteItem *)item
{
    double latitude = item.favorite->getLatLon().latitude;
    double longitude = item.favorite->getLatLon().longitude;
    NSString *title = item.favorite->getTitle().toNSString();
    
    if (_type == EOADestinationTypeStart)
        [_pointsHelper setStartPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:NO name:[[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:title]];
    else if (_type == EOADestinationTypeIntermediate || _type == EOADestinationTypeFinish)
        [_pointsHelper navigateToPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:NO intermediate:(_type != EOADestinationTypeIntermediate ? -1 : (int)[_pointsHelper getIntermediatePoints].count) historyName:[[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:title]];
    else if (_type == EOADestinationTypeHome)
    {
        [_pointsHelper setHomePoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] description:[[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:title]];
    }
    else if (_type == EOADestinationTypeWork)
    {
        [_pointsHelper setWorkPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] description:[[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:title]];
    }
    
    [vwController dismiss];
    if (vwController.delegate)
        [vwController.delegate waypointSelectionDialogComplete:YES showMap:NO calculatingRoute:YES];
    
    [_pointsHelper updateRouteAndRefresh:YES];
}

- (void) onDestinationSelected:(OADestination *)destination
{
    double latitude = destination.latitude;
    double longitude = destination.longitude;
    NSString *title = destination.desc;
    
    if (_type == EOADestinationTypeStart)
        [_pointsHelper setStartPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:NO name:[[OAPointDescription alloc] initWithType:POINT_TYPE_MAP_MARKER name:title]];
    else if (_type == EOADestinationTypeIntermediate || _type == EOADestinationTypeFinish)
        [_pointsHelper navigateToPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:NO intermediate:(_type != EOADestinationTypeIntermediate ? -1 : (int)[_pointsHelper getIntermediatePoints].count) historyName:[[OAPointDescription alloc] initWithType:POINT_TYPE_MAP_MARKER name:title]];
    else if (_type == EOADestinationTypeHome)
    {
        [_pointsHelper setHomePoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] description:[[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:title]];
    }
    else if (_type == EOADestinationTypeWork)
    {
        [_pointsHelper setWorkPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] description:[[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:title]];
    }
    
    [vwController dismiss];
    if (vwController.delegate)
        [vwController.delegate waypointSelectionDialogComplete:YES showMap:NO calculatingRoute:YES];
    
    [_pointsHelper updateRouteAndRefresh:YES];
}

- (void) onHomeWorkSelected:(OARTargetPoint *)destination
{
    if (_type == EOADestinationTypeStart)
        [_pointsHelper setStartPoint:destination.point updateRoute:NO name:destination.pointDescription];
    else if (_type == EOADestinationTypeIntermediate || _type == EOADestinationTypeFinish)
        [_pointsHelper navigateToPoint:destination.point updateRoute:NO intermediate:(_type != EOADestinationTypeIntermediate ? -1 : (int)[_pointsHelper getIntermediatePoints].count) historyName:destination.pointDescription];
    else if (_type == EOADestinationTypeHome)
    {
        [_pointsHelper setHomePoint:[[CLLocation alloc] initWithLatitude:destination.point.coordinate.latitude longitude:destination.point.coordinate.longitude] description:destination.pointDescription];
    }
    else if (_type == EOADestinationTypeWork)
    {
        [_pointsHelper setWorkPoint:[[CLLocation alloc] initWithLatitude:destination.point.coordinate.latitude longitude:destination.point.coordinate.longitude] description:destination.pointDescription];
    }
    
    [vwController dismiss];
    if (vwController.delegate)
        [vwController.delegate waypointSelectionDialogComplete:YES showMap:NO calculatingRoute:YES];
    
    [_pointsHelper updateRouteAndRefresh:YES];
}

@end

@interface OAAddDestinationBottomSheetViewController ()

@end

@implementation OAAddDestinationBottomSheetViewController

- (instancetype) initWithType:(EOADestinationType)type
{
    _type = type;
    return [super initWithParam:nil];
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAAddDestinationBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
    
    [super setupView];
}

- (void)additionalSetup
{
    [super additionalSetup];
    self.tableBackgroundView.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);
    self.buttonsView.subviews.firstObject.backgroundColor = UIColorFromRGB(color_bottom_sheet_background);;
    [self hideDoneButton];
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
}

@end
