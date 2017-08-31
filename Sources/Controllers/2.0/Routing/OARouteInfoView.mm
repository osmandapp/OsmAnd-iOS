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
#import "OARTargetPoint.h"
#import "OAPointDescription.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "PXAlertView.h"
#import "OsmAndApp.h"
#import "OAApplicationMode.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"
#import "OAFavoriteListDialogView.h"
#import "OADestinationsListDialogView.h"
#import "OAFavoriteItem.h"
#import "OADestinationItem.h"

#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>

#define kTopPanTreshold 16.0
#define kInfoViewLanscapeWidth 320.0

static int directionInfo = -1;

@interface OARouteInfoView ()<OARouteInformationListener, OAAppModeCellDelegate, OADestinationsListDialogDelegate, OAFavoriteListDialogDelegate>

@end

@implementation OARouteInfoView
{
    OATargetPointsHelper *_pointsHelper;
    OARoutingHelper *_routingHelper;
    OsmAndAppInstance _app;

    int _rowsCount;
    int _appModeRowIndex;
    int _startPointRowIndex;
    int _intermediatePointsRowIndex;
    int _endPointRowIndex;
    int _routeInfoRowIndex;
    
    CALayer *_horizontalLine;
    CALayer *_verticalLine1;
    CALayer *_verticalLine2;
    CALayer *_verticalLine3;
    
    BOOL _currentSelectionTarget;
    PXAlertView *_currentSelectionAlertView;
}

- (instancetype)init
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

- (instancetype)initWithFrame:(CGRect)frame
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

-(void)awakeFromNib
{
    [super awakeFromNib];

    // drop shadow
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.layer setShadowOpacity:0.3];
    [self.layer setShadowRadius:3.0];
    [self.layer setShadowOffset:CGSizeMake(0.0, 0.0)];

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _verticalLine1 = [CALayer layer];
    _verticalLine1.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _verticalLine2 = [CALayer layer];
    _verticalLine2.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    _verticalLine3 = [CALayer layer];
    _verticalLine3.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    
    [_buttonsView.layer addSublayer:_horizontalLine];
    [_buttonsView.layer addSublayer:_verticalLine1];
    [_buttonsView.layer addSublayer:_verticalLine2];
    [_buttonsView.layer addSublayer:_verticalLine3];

    _tableView.separatorInset = UIEdgeInsetsZero;
}

- (void) commonInit
{
    _app = [OsmAndApp instance];
    _pointsHelper = [OATargetPointsHelper sharedInstance];
    _routingHelper = [OARoutingHelper sharedInstance];

    [_routingHelper addListener:self];
}

- (void) updateData
{
    int index = 0;
    int count = 3;
    _appModeRowIndex = index++;
    _startPointRowIndex = index++;
    _intermediatePointsRowIndex = -1;
    if ([self hasIntermediatePoints])
    {
        _intermediatePointsRowIndex = index++;
        count++;
    }
    _endPointRowIndex = index++;
    _routeInfoRowIndex = -1;
    if ([_routingHelper isRouteCalculated])
    {
        _routeInfoRowIndex = index++;
        count++;
    }
    _rowsCount = count;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    _horizontalLine.frame = CGRectMake(0.0, 0.0, _buttonsView.frame.size.width, 0.5);
    _verticalLine1.frame = CGRectMake(_waypointsButton.frame.origin.x - 0.5, 0.5, 0.5, _buttonsView.frame.size.height);
    _verticalLine2.frame = CGRectMake(_settingsButton.frame.origin.x - 0.5, 0.5, 0.5, _buttonsView.frame.size.height);
    _verticalLine3.frame = CGRectMake(_goButton.frame.origin.x - 0.5, 0.5, 0.5, _buttonsView.frame.size.height);
}

- (void) adjustHeight
{
    CGRect f = self.frame;
    f.size.height = _rowsCount * _tableView.rowHeight - 1.0 + _buttonsView.frame.size.height;
    self.frame = f;
}

- (IBAction)closePressed:(id)sender
{
    [[OARootViewController instance].mapPanel stopNavigation];
}

- (IBAction)waypointsPressed:(id)sender
{
    
}

- (IBAction)settingsPressed:(id)sender
{
    
}

- (IBAction)goPressed:(id)sender
{
    
}

- (BOOL) hasIntermediatePoints
{
    return [_pointsHelper getIntermediatePoints]  && [_pointsHelper getIntermediatePoints].count > 0;
}

- (NSString *) getRoutePointDescription:(double)lat lon:(double)lon
{
    return [NSString stringWithFormat:@"%@ %.3f %@ %.3f", OALocalizedString(@"Lat"), lat, OALocalizedString(@"Lon"), lon];
}

- (NSString *) getRoutePointDescription:(CLLocation *)l d:(NSString *)d
{
    if (d && d.length > 0)
        return [d stringByReplacingOccurrencesOfString:@":" withString:@" "];;

    if (l)
        return [NSString stringWithFormat:@"%@ %.3f %@ %.3f", OALocalizedString(@"Lat"), l.coordinate.latitude, OALocalizedString(@"Lon"), l.coordinate.longitude];
    
    return @"";
}

- (BOOL)isLandscape
{
    return DeviceScreenWidth > 470.0 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

- (void) show:(BOOL)animated onComplete:(void (^)(void))onComplete
{
    [self updateData];
    [self adjustHeight];
    [self.tableView reloadData];
    
    if (animated)
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
        {
            frame.origin.x = -self.bounds.size.width;
            frame.origin.y = 20.0 - kTopPanTreshold;
            self.frame = frame;
            
            frame.origin.x = 0.0;
        }
        else
        {
            frame.origin.x = 0.0;
            frame.origin.y = DeviceScreenHeight + 10.0;
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
            frame.origin.y = 20.0 - kTopPanTreshold;
        else
            frame.origin.y = DeviceScreenHeight - self.bounds.size.height;
        
        self.frame = frame;
        
        if (onComplete)
            onComplete();
    }
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
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
                
                if (onComplete)
                    onComplete();
            }];
        }
        else
        {
            self.frame = frame;
            
            [self removeFromSuperview];
            
            if (onComplete)
                onComplete();
        }
    }
}

- (void) update
{
    [self.tableView reloadData];
}

- (void) selectFavorite:(BOOL)sortByName target:(BOOL)target
{
    OAFavoriteListDialogView *favView = [[OAFavoriteListDialogView alloc] initWithFrame:CGRectMake(0, 0, 270, -1) sortingType:sortByName ? 0 : 1];
    favView.delegate = self;
    _currentSelectionTarget = target;
    
    _currentSelectionAlertView = [PXAlertView showAlertWithTitle:OALocalizedString(@"favorites") message:nil cancelTitle:OALocalizedString(@"shared_string_cancel") otherTitle:sortByName ? OALocalizedString(@"sort_by_distance") : OALocalizedString(@"sort_by_name") otherDesc:nil otherImage:nil contentView:favView completion:^(BOOL cancelled, NSInteger buttonIndex) {
        
        _currentSelectionAlertView = nil;
        if (!cancelled)
        {
            [self selectFavorite:!sortByName target:target];
        }
    }];
}

- (void) selectDestination:(BOOL)target
{
    OADestinationsListDialogView *directionsView = [[OADestinationsListDialogView alloc] initWithFrame:CGRectMake(0, 0, 270, -1)];
    directionsView.delegate = self;
    _currentSelectionTarget = target;
    
    _currentSelectionAlertView = [PXAlertView showAlertWithTitle:OALocalizedString(@"directions") message:nil cancelTitle:OALocalizedString(@"shared_string_cancel") otherTitle:nil otherDesc:nil otherImage:nil contentView:directionsView completion:^(BOOL cancelled, NSInteger buttonIndex) {
        _currentSelectionAlertView = nil;
    }];
}

#pragma mark - OAAppModeCellDelegate

- (void) appModeChanged:(OAMapVariantType)next
{
    OAMapVariantType am = [_routingHelper getAppMode];
    OAMapVariantType appMode = [OAApplicationMode getVariantType:_app.data.lastMapSource.variant];
    if ([_routingHelper isFollowingMode] && appMode == am)
    {
        [_app.data setLastMapSourceVariant:[OAApplicationMode getVariantStr:next]];
    }
    [_routingHelper setAppMode:next];
    [_app initVoiceCommandPlayer:next warningNoneProvider:YES showDialog:NO force:NO];
    [_routingHelper recalculateRouteDueToSettingsChange];
}

#pragma mark - OARouteInformationListener

- (void) newRouteIsCalculated:(BOOL)newRoute
{
    directionInfo = -1;
    [self updateData];
    [self adjustHeight];
    [self.tableView reloadData];
    if ([self superview])
    {
        [self show:NO onComplete:nil];
    }
}

- (void) routeWasCancelled
{
    directionInfo = -1;
    // do not hide fragment (needed for use case entering Planning mode without destination)
}

- (void) routeWasFinished
{
    
}

#pragma mark - OAFavoriteListDialogDelegate

- (void) onFavoriteSelected:(OAFavoriteItem *)item
{
    double latitude = item.favorite->getLatLon().latitude;
    double longitude = item.favorite->getLatLon().longitude;
    NSString *title = item.favorite->getTitle().toNSString();
    
    if (!_currentSelectionTarget)
        [_pointsHelper setStartPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:YES name:[[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:title]];
    else
        [_pointsHelper navigateToPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:YES intermediate:-1 historyName:[[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:title]];
    
    if (_currentSelectionAlertView)
    {
        NSInteger cancelButtonIndex = [_currentSelectionAlertView getCancelButtonIndex];
        [_currentSelectionAlertView dismissWithClickedButtonIndex:cancelButtonIndex animated:YES];
        [self.tableView reloadData];
    }
}

#pragma mark - OADestinationsListDialogDelegate

- (void) onDestinationSelected:(OADestination *)destination
{
    double latitude = destination.latitude;
    double longitude = destination.longitude;
    NSString *title = destination.desc;
    
    if (!_currentSelectionTarget)
        [_pointsHelper setStartPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:YES name:[[OAPointDescription alloc] initWithType:POINT_TYPE_MAP_MARKER name:title]];
    else
        [_pointsHelper navigateToPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:YES intermediate:-1 historyName:[[OAPointDescription alloc] initWithType:POINT_TYPE_MAP_MARKER name:title]];

    if (_currentSelectionAlertView)
    {
        NSInteger cancelButtonIndex = [_currentSelectionAlertView getCancelButtonIndex];
        [_currentSelectionAlertView dismissWithClickedButtonIndex:cancelButtonIndex animated:YES];
        [self.tableView reloadData];
    }
}

#pragma mark - UITableViewDelegate

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == _appModeRowIndex)
    {
        static NSString* const reusableIdentifierPoint = @"OAAppModeCell";
        
        OAAppModeCell* cell;
        cell = (OAAppModeCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAAppModeCell" owner:self options:nil];
            cell = (OAAppModeCell *)[nib objectAtIndex:0];
            cell.availableModes = @[OAMapVariantCarStr, OAMapVariantBicycleStr, OAMapVariantPedestrianStr];
            cell.delegate = self;
        }
        
        if (cell)
        {
            cell.selectedMode = [_routingHelper getAppMode];
        }
        return cell;
    }
    else if (indexPath.row == _startPointRowIndex)
    {
        static NSString* const reusableIdentifierPoint = @"OARoutingTargetCell";
        
        OARoutingTargetCell* cell;
        cell = (OARoutingTargetCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OARoutingTargetCell" owner:self options:nil];
            cell = (OARoutingTargetCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OARTargetPoint *point = [_pointsHelper getPointToStart];
            cell.titleLabel.text = OALocalizedString(@"route_from");
            if (point)
            {
                [cell.imgView setImage:[UIImage imageNamed:@"ic_action_marker.png"]];
                NSString *oname = [point getOnlyName].length > 0 ? [point getOnlyName] : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"map_settings_map"), [self getRoutePointDescription:[point getLatitude] lon:[point getLongitude]]];
                cell.addressLabel.text = oname;
            }
            else
            {
                [cell.imgView setImage:[UIImage imageNamed:[OAApplicationMode getVariantTypeMyLocationIconName:[_routingHelper getAppMode]]]];
                cell.addressLabel.text = OALocalizedString(@"shared_string_my_location");
            }
        }
        return cell;
    }
    else if (indexPath.row == _endPointRowIndex)
    {
        static NSString* const reusableIdentifierPoint = @"OARoutingTargetCell";
        
        OARoutingTargetCell* cell;
        cell = (OARoutingTargetCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OARoutingTargetCell" owner:self options:nil];
            cell = (OARoutingTargetCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OARTargetPoint *point = [_pointsHelper getPointToNavigate];
            [cell.imgView setImage:[UIImage imageNamed:@"ic_action_marker.png"]];
            cell.titleLabel.text = OALocalizedString(@"route_to");
            if (point)
            {
                NSString *oname = [self getRoutePointDescription:point.point d:[point getOnlyName]];
                cell.addressLabel.text = oname;
            }
            else
            {
                cell.addressLabel.text = OALocalizedString(@"route_descr_select_destination");
            }
        }
        return cell;
    }
    else if (indexPath.row == _intermediatePointsRowIndex)
    {
        static NSString* const reusableIdentifierPoint = @"OARoutingTargetCell";
        
        OARoutingTargetCell* cell;
        cell = (OARoutingTargetCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OARoutingTargetCell" owner:self options:nil];
            cell = (OARoutingTargetCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            NSArray<OARTargetPoint *> *points = [_pointsHelper getIntermediatePoints];
            NSMutableString *via = [NSMutableString string];
            for (OARTargetPoint *point in points)
            {
                if (via.length > 0)
                    [via appendString:@" "];
                
                NSString *description = [point getOnlyName];
                [via appendString:[self getRoutePointDescription:point.point d:description]];
            }
            [cell.imgView setImage:[UIImage imageNamed:@"ic_action_marker.png"]];
            cell.titleLabel.text = OALocalizedString(@"route_via");
            cell.addressLabel.text = via;
        }
        return cell;
    }
    else if (indexPath.row == _routeInfoRowIndex)
    {
        static NSString* const reusableIdentifierPoint = @"OARoutingInfoCell";
        
        OARoutingInfoCell* cell;
        cell = (OARoutingInfoCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OARoutingInfoCell" owner:self options:nil];
            cell = (OARoutingInfoCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.directionInfo = directionInfo;
            [cell updateControls];
        }
        return cell;
    }
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == _startPointRowIndex)
    {
        int index = 0;
        int myLocationIndex = index++;
        int favoritesIndex = -1;
        int selectOnMapIndex = -1;
        int addressIndex = -1;
        int firstDirectionIndex = -1;
        int secondDirectionIndex = -1;
        int otherDirectionsIndex = -1;

        NSMutableArray *titles = [NSMutableArray array];
        NSMutableArray *images = [NSMutableArray array];

        [titles addObject:OALocalizedString(@"shared_string_my_location")];
        [images addObject:@"ic_coordinates_location"];

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
        [images addObject:@"ic_action_marker"];
        addressIndex = index++;
        
        NSMutableArray *destinations = [OADestinationsHelper instance].sortedDestinations;
        OADestination *firstDestination;
        OADestination *secondDestination;
        if (destinations.count > 0)
        {
            firstDestination = destinations[0];
            [titles addObject:firstDestination.desc];
            [images addObject:[firstDestination.markerResourceName stringByAppendingString:@"_small"]];
            firstDirectionIndex = index++;
        }
        if (destinations.count > 1)
        {
            secondDestination = destinations[1];
            [titles addObject:secondDestination.desc];
            [images addObject:[secondDestination.markerResourceName stringByAppendingString:@"_small"]];
            secondDirectionIndex = index++;
        }
        if (destinations.count > 2)
        {
            [titles addObject:OALocalizedString(@"directions_other")];
            [images addObject:@""];
            otherDirectionsIndex = index++;
        }
        
        _currentSelectionTarget = NO;
        [PXAlertView showAlertWithTitle:OALocalizedString(@"route_from")
                                message:nil
                            cancelTitle:OALocalizedString(@"shared_string_cancel")
                            otherTitles:titles
                              otherDesc:nil
                            otherImages:images
                             completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                 if (!cancelled)
                                 {
                                     if (buttonIndex == myLocationIndex)
                                     {
                                         [_pointsHelper clearStartPoint:YES];
                                         [_app.data backupTargetPoints];
                                     }
                                     else if (buttonIndex == favoritesIndex)
                                     {
                                         [self selectFavorite:YES target:NO];
                                     }
                                     else if (buttonIndex == selectOnMapIndex)
                                     {
                                         [[OARootViewController instance].mapPanel openTargetViewWithRouteTargetSelection:NO];
                                     }
                                     else if (buttonIndex == addressIndex)
                                     {
                                         [[OARootViewController instance].mapPanel openSearch:OAQuickSearchType::START_POINT];
                                     }
                                     else if (buttonIndex == firstDirectionIndex)
                                     {
                                         [self onDestinationSelected:firstDestination];
                                     }
                                     else if (buttonIndex == secondDirectionIndex)
                                     {
                                         [self onDestinationSelected:secondDestination];
                                     }
                                     else if (buttonIndex == otherDirectionsIndex)
                                     {
                                         [self selectDestination:NO];
                                     }
                                     [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                                 }
                             }];
    }
    else if (indexPath.row == _endPointRowIndex)
    {
        int index = 0;
        int favoritesIndex = -1;
        int selectOnMapIndex = -1;
        int addressIndex = -1;
        int firstDirectionIndex = -1;
        int secondDirectionIndex = -1;
        int otherDirectionsIndex = -1;
        
        NSMutableArray *titles = [NSMutableArray array];
        NSMutableArray *images = [NSMutableArray array];
        
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
        [images addObject:@"ic_action_marker"];
        addressIndex = index++;
        
        NSMutableArray *destinations = [OADestinationsHelper instance].sortedDestinations;
        OADestination *firstDestination;
        OADestination *secondDestination;
        if (destinations.count > 0)
        {
            firstDestination = destinations[0];
            [titles addObject:firstDestination.desc];
            [images addObject:[firstDestination.markerResourceName stringByAppendingString:@"_small"]];
            firstDirectionIndex = index++;
        }
        if (destinations.count > 1)
        {
            secondDestination = destinations[1];
            [titles addObject:secondDestination.desc];
            [images addObject:[secondDestination.markerResourceName stringByAppendingString:@"_small"]];
            secondDirectionIndex = index++;
        }
        if (destinations.count > 2)
        {
            [titles addObject:OALocalizedString(@"directions_other")];
            [images addObject:@""];
            otherDirectionsIndex = index++;
        }
        
        [PXAlertView showAlertWithTitle:OALocalizedString(@"route_to")
                                message:nil
                            cancelTitle:OALocalizedString(@"shared_string_cancel")
                            otherTitles:titles
                              otherDesc:nil
                            otherImages:images
                             completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                 if (!cancelled)
                                 {
                                     if (buttonIndex == favoritesIndex)
                                     {
                                         [self selectFavorite:YES target:YES];
                                     }
                                     else if (buttonIndex == selectOnMapIndex)
                                     {
                                         [[OARootViewController instance].mapPanel openTargetViewWithRouteTargetSelection:YES];
                                     }
                                     else if (buttonIndex == addressIndex)
                                     {
                                         [[OARootViewController instance].mapPanel openSearch:OAQuickSearchType::DESTINATION];
                                     }
                                     else if (buttonIndex == firstDirectionIndex)
                                     {
                                         [self onDestinationSelected:firstDestination];
                                     }
                                     else if (buttonIndex == secondDirectionIndex)
                                     {
                                         [self onDestinationSelected:secondDestination];
                                     }
                                     else if (buttonIndex == otherDirectionsIndex)
                                     {
                                         [self selectDestination:YES];
                                     }
                                     [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                                 }
                             }];
    }

}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _rowsCount;
}

@end
