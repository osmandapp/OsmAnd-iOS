//
//  OAWaypointUIHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 10/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAWaypointUIHelper.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "Localization.h"
#import "OALocationPointWrapper.h"
#import "OALocationPoint.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"
#import "OARoutingHelper.h"
#import "OAVoiceRouter.h"
#import "OALocationPoint.h"
#import "OAPointDescription.h"
#import "OAMapUtils.h"
#import "OsmAndApp.h"
#import "MBProgressHUD.h"
#import "OATspAnt.h"
#import "OAFavoriteListDialogView.h"
#import "OADestinationsListDialogView.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"
#import "OAFavoriteItem.h"
#import "OADestinationItem.h"
#import "PXAlertView.h"

#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>

@interface OAWaypointSelectionDialog () <OADestinationsListDialogDelegate, OAFavoriteListDialogDelegate>

@end

@implementation OAWaypointSelectionDialog
{
    OsmAndAppInstance _app;
    OATargetPointsHelper *_pointsHelper;
    
    BOOL _currentSelectionTarget;
    BOOL _currentSelectionIntermediate;
    PXAlertView *_currentSelectionAlertView;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _pointsHelper = [OATargetPointsHelper sharedInstance];
    }
    return self;
}

- (void) selectFavorite:(BOOL)sortByName target:(BOOL)target intermediate:(BOOL)intermediate
{
    OAFavoriteListDialogView *favView = [[OAFavoriteListDialogView alloc] initWithFrame:CGRectMake(0, 0, 270, -1) sortingType:sortByName ? 0 : 1];
    favView.delegate = self;
    _currentSelectionTarget = target;
    _currentSelectionIntermediate = intermediate;
    
    _currentSelectionAlertView = [PXAlertView showAlertWithTitle:OALocalizedString(@"favorites") message:nil cancelTitle:OALocalizedString(@"shared_string_cancel") otherTitle:sortByName ? OALocalizedString(@"sort_by_distance") : OALocalizedString(@"sort_by_name") otherDesc:nil otherImage:nil contentView:favView completion:^(BOOL cancelled, NSInteger buttonIndex) {
        
        _currentSelectionAlertView = nil;
        if (!cancelled)
            [self selectFavorite:!sortByName target:target intermediate:intermediate];
    }];
}

- (void) selectDestination:(BOOL)target intermediate:(BOOL)intermediate
{
    OADestinationsListDialogView *directionsView = [[OADestinationsListDialogView alloc] initWithFrame:CGRectMake(0, 0, 270, -1)];
    directionsView.delegate = self;
    _currentSelectionTarget = target;
    _currentSelectionIntermediate = intermediate;
    
    _currentSelectionAlertView = [PXAlertView showAlertWithTitle:OALocalizedString(@"directions") message:nil cancelTitle:OALocalizedString(@"shared_string_cancel") otherTitle:nil otherDesc:nil otherImage:nil contentView:directionsView completion:^(BOOL cancelled, NSInteger buttonIndex) {
        _currentSelectionAlertView = nil;
    }];
}

- (void) selectWaypoint:(NSString *)title target:(BOOL)target intermediate:(BOOL)intermediate
{
    int index = 0;
    int myLocationIndex = !target && !intermediate ? index++ : -1;
    int favoritesIndex = -1;
    int selectOnMapIndex = -1;
    int addressIndex = -1;
    int firstDirectionIndex = -1;
    int secondDirectionIndex = -1;
    int otherDirectionsIndex = -1;
    
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *images = [NSMutableArray array];

    if (myLocationIndex != -1)
    {
        [titles addObject:OALocalizedString(@"shared_string_my_location")];
        [images addObject:@"ic_coordinates_location"];
    }

    if (!_app.favoritesCollection->getFavoriteLocations().isEmpty())
    {
        [titles addObject:[NSString stringWithFormat:@"%@%@", OALocalizedString(@"favorite"), OALocalizedString(@"shared_string_ellipsis")]];
        [images addObject:@"menu_star_icon"];
        favoritesIndex = index++;
    }
    
    [titles addObject:OALocalizedString(@"shared_string_select_on_map")];
    [images addObject:@"ic_action_marker"];
    selectOnMapIndex = index++;
    
    [titles addObject:[NSString stringWithFormat:@"%@%@", OALocalizedString(@"shared_string_address"), OALocalizedString(@"shared_string_ellipsis")]];
    [images addObject:@"ic_action_home_dark"];
    addressIndex = index++;
    
    NSMutableArray *destinations = [OADestinationsHelper instance].sortedDestinations;
    OADestination *firstDestination;
    OADestination *secondDestination;
    if (destinations.count > 0)
    {
        firstDestination = destinations[0];
        
        NSString *title = firstDestination.desc ? firstDestination.desc : OALocalizedString(@"ctx_mnu_direction");
        NSString *imageName;
        if (firstDestination.parking)
            imageName = @"ic_parking_pin_small";
        else
            imageName = [firstDestination.markerResourceName ? firstDestination.markerResourceName : @"ic_destination_pin_1" stringByAppendingString:@"_small"];
        
        [titles addObject:title];
        [images addObject:imageName];
        firstDirectionIndex = index++;
    }
    if (destinations.count > 1)
    {
        secondDestination = destinations[1];
        
        NSString *title = secondDestination.desc ? secondDestination.desc : OALocalizedString(@"ctx_mnu_direction");
        NSString *imageName;
        if (secondDestination.parking)
            imageName = @"ic_parking_pin_small";
        else
            imageName = [secondDestination.markerResourceName ? secondDestination.markerResourceName : @"ic_destination_pin_1" stringByAppendingString:@"_small"];
        
        [titles addObject:title];
        [images addObject:imageName];
        secondDirectionIndex = index++;
    }
    if (destinations.count > 2)
    {
        [titles addObject:OALocalizedString(@"directions_other")];
        [images addObject:@""];
        otherDirectionsIndex = index++;
    }
    
    _currentSelectionTarget = target;
    _currentSelectionIntermediate = intermediate;
    
    [PXAlertView showAlertWithTitle:title
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_cancel")
                        otherTitles:titles
                          otherDesc:nil
                        otherImages:images
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 BOOL selectionDone = NO;
                                 BOOL showMap = NO;
                                 OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
                                 if (buttonIndex == myLocationIndex)
                                 {
                                     selectionDone = YES;
                                     [_pointsHelper clearStartPoint:YES];
                                     [_app.data backupTargetPoints];
                                 }
                                 else if (buttonIndex == favoritesIndex)
                                 {
                                     [self selectFavorite:YES target:target intermediate:intermediate];
                                 }
                                 else if (buttonIndex == selectOnMapIndex)
                                 {
                                     [mapPanel openTargetViewWithRouteTargetSelection:target intermediate:intermediate];
                                     showMap = YES;
                                 }
                                 else if (buttonIndex == addressIndex)
                                 {
                                     if (intermediate)
                                         [mapPanel openSearch:OAQuickSearchType::INTERMEDIATE];
                                     else if (target)
                                         [mapPanel openSearch:OAQuickSearchType::DESTINATION];
                                     else
                                         [mapPanel openSearch:OAQuickSearchType::START_POINT];
                                 }
                                 else if (buttonIndex == firstDirectionIndex)
                                 {
                                     selectionDone = YES;
                                     [self onDestinationSelected:firstDestination];
                                 }
                                 else if (buttonIndex == secondDirectionIndex)
                                 {
                                     selectionDone = YES;
                                     [self onDestinationSelected:secondDestination];
                                 }
                                 else if (buttonIndex == otherDirectionsIndex)
                                 {
                                     [self selectDestination:target intermediate:intermediate];
                                 }
                                 
                                 if (self.delegate)
                                     [self.delegate waypointSelectionDialogComplete:self selectionDone:selectionDone showMap:showMap calculatingRoute:NO];
                             }
                         }];
}

#pragma mark - OAFavoriteListDialogDelegate

- (void) onFavoriteSelected:(OAFavoriteItem *)item
{
    double latitude = item.favorite->getLatLon().latitude;
    double longitude = item.favorite->getLatLon().longitude;
    NSString *title = item.favorite->getTitle().toNSString();
    
    if (!_currentSelectionTarget)
        [_pointsHelper setStartPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:NO name:[[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:title]];
    else
        [_pointsHelper navigateToPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:NO intermediate:(!_currentSelectionIntermediate ? -1 : (int)[_pointsHelper getIntermediatePoints].count) historyName:[[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:title]];
    
    if (_currentSelectionAlertView)
    {
        NSInteger cancelButtonIndex = [_currentSelectionAlertView getCancelButtonIndex];
        [_currentSelectionAlertView dismissWithClickedButtonIndex:cancelButtonIndex animated:YES];
    }
    if (self.delegate)
        [self.delegate waypointSelectionDialogComplete:self selectionDone:YES showMap:NO calculatingRoute:YES];
    
    [_pointsHelper updateRouteAndRefresh:YES];
}

#pragma mark - OADestinationsListDialogDelegate

- (void) onDestinationSelected:(OADestination *)destination
{
    double latitude = destination.latitude;
    double longitude = destination.longitude;
    NSString *title = destination.desc;
    
    if (!_currentSelectionTarget)
        [_pointsHelper setStartPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:NO name:[[OAPointDescription alloc] initWithType:POINT_TYPE_MAP_MARKER name:title]];
    else
        [_pointsHelper navigateToPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:NO intermediate:(!_currentSelectionIntermediate ? -1 : (int)[_pointsHelper getIntermediatePoints].count) historyName:[[OAPointDescription alloc] initWithType:POINT_TYPE_MAP_MARKER name:title]];
    
    if (_currentSelectionAlertView)
    {
        NSInteger cancelButtonIndex = [_currentSelectionAlertView getCancelButtonIndex];
        [_currentSelectionAlertView dismissWithClickedButtonIndex:cancelButtonIndex animated:YES];
    }
    if (self.delegate)
        [self.delegate waypointSelectionDialogComplete:self selectionDone:YES showMap:NO calculatingRoute:YES];
    
    [_pointsHelper updateRouteAndRefresh:YES];
}

@end

@implementation OAWaypointUIHelper

+ (void) showOnMap:(OALocationPointWrapper *)p
{
    id<OALocationPoint> point = p.point;
    
    double latitude = [point getLatitude];
    double longitude = [point getLongitude];
    const OsmAnd::LatLon latLon(latitude, longitude);
    OAMapViewController *mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OAMapRendererView *mapRendererView = (OAMapRendererView *)mapVC.view;
    
    CGPoint touchPoint = CGPointMake(mapRendererView.bounds.size.width / 2.0, mapRendererView.bounds.size.height / 2.0);
    touchPoint.x *= mapRendererView.contentScaleFactor;
    touchPoint.y *= mapRendererView.contentScaleFactor;
    
    OAMapSymbol *symbol = [[OAMapSymbol alloc] init];
    symbol.type = OAMapSymbolLocation;
    symbol.touchPoint = CGPointMake(touchPoint.x, touchPoint.y);
    symbol.location = CLLocationCoordinate2DMake(latitude, longitude);
    symbol.caption = [point getPointDescription].name;
    symbol.centerMap = YES;
    symbol.minimized = YES;
    [OAMapViewController postTargetNotification:symbol];
}

+ (void) sortAllTargets:(void (^)(void))onComplete
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIView *topView = [[[UIApplication sharedApplication] windows] lastObject];
        MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:topView];
        progressHUD.removeFromSuperViewOnHide = YES;
        progressHUD.labelText = [OALocalizedString(@"sorting") stringByAppendingString:@"..."];
        progressHUD.graceTime = 0.5;
        progressHUD.minShowTime = 0.5;
        [topView addSubview:progressHUD];
        
        [progressHUD showAnimated:YES whileExecutingBlock:^{
            
            OATargetPointsHelper *targets = [OATargetPointsHelper sharedInstance];
            NSArray<OARTargetPoint *> *intermediates = [targets getIntermediatePointsWithTarget];
            
            CLLocation *cll = [OsmAndApp instance].locationServices.lastKnownLocation;
            NSMutableArray<OARTargetPoint *> *lt = [NSMutableArray arrayWithArray:intermediates];
            OARTargetPoint *start;
            
            if (cll)
            {
                CLLocation *ll = [[CLLocation alloc] initWithLatitude:cll.coordinate.latitude longitude:cll.coordinate.longitude];
                start = [OARTargetPoint create:ll name:nil];
            }
            else if ([targets getPointToStart])
            {
                OARTargetPoint *ps = [targets getPointToStart];
                CLLocation *ll = [[CLLocation alloc] initWithLatitude:[ps getLatitude] longitude:[ps getLongitude]];
                start = [OARTargetPoint create:ll name:nil];
            }
            else
            {
                start = lt[0];;
            }
            OARTargetPoint *end = lt[lt.count - 1];
            [lt removeObjectAtIndex:lt.count - 1];
            NSMutableArray *al = [NSMutableArray array];
            for (OARTargetPoint *p in lt)
                [al addObject:p.point];
            
            OATspAnt *t = [[OATspAnt alloc] init];
            [t readGraph:al start:start.point end:end.point];
            NSArray *result = [t solve];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSMutableArray<OARTargetPoint *> *alocs = [NSMutableArray array];
                for (int k = 0; k < result.count; k++)
                {
                    int i = [result[k] intValue];
                    if (i > 0)
                        [alocs addObject:intermediates[i - 1]];
                }
                
                BOOL eq = YES;
                for (int j = 0; j < intermediates.count && j < alocs.count; j++)
                {
                    if (intermediates[j] != alocs[j])
                    {
                        eq = NO;
                        break;
                    }
                }
                if (!eq)
                {
                    [targets reorderAllTargetPoints:alocs updateRoute:NO];

                    if (onComplete)
                        onComplete();
                    
                    [targets updateRouteAndRefresh:YES];
                }
            });
        }];
    });
}

// switch start & finish
+ (void) switchStartAndFinish:(void (^)(void))onComplete
{
    OsmAndAppInstance app = [OsmAndApp instance];
    OATargetPointsHelper *targets = [OATargetPointsHelper sharedInstance];
    OARTargetPoint *finish = [targets getPointToNavigate];
    OARTargetPoint *start = [targets getPointToStart];

    if (finish)
    {
        [targets setStartPoint:[[CLLocation alloc] initWithLatitude:[finish getLatitude] longitude:[finish getLongitude]] updateRoute:NO name:finish.pointDescription];
        if (!start)
        {
            CLLocation *loc = app.locationServices.lastKnownLocation;
            if (loc)
            {
                [targets navigateToPoint:[[CLLocation alloc] initWithLatitude:loc.coordinate.latitude longitude:loc.coordinate.longitude] updateRoute:NO intermediate:-1];
            }
        }
        else
        {
            [targets navigateToPoint:[[CLLocation alloc] initWithLatitude:[start getLatitude] longitude:[start getLongitude]] updateRoute:NO intermediate:-1 historyName:start.pointDescription];
        }
        
        if (onComplete)
            onComplete();
        
        [targets updateRouteAndRefresh:YES];
    }
}

@end
