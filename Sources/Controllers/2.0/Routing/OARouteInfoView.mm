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

#define kTopPanTreshold 16.0
#define kInfoViewLanscapeWidth 320.0
#define kButtonsViewHeight 53.0

static int directionInfo = -1;

@interface OARouteInfoView ()<OARouteInformationListener>

@end

@implementation OARouteInfoView
{
    OATargetPointsHelper *_pointsHelper;
    OARoutingHelper *_routingHelper;
    
    int _rowsCount;
    int _appModeRowIndex;
    int _startPointRowIndex;
    int _intermediatePointsRowIndex;
    int _endPointRowIndex;
    int _routeInfoRowIndex;
    
}

- (instancetype)init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OARouteInfoView class]])
            self = (OARouteInfoView *)v;
    }
    
    _pointsHelper = [OATargetPointsHelper sharedInstance];
    _routingHelper = [OARoutingHelper sharedInstance];

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
    
    _pointsHelper = [OATargetPointsHelper sharedInstance];
    _routingHelper = [OARoutingHelper sharedInstance];
    
    if (self)
    {
        self.frame = frame;
    }
    
    return self;
}

-(void)awakeFromNib
{
    [_routingHelper addListener:self];
}

- (void) setup
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

- (IBAction)closePressed:(id)sender
{
    
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
    [self setup];

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

#pragma mark - OARouteInformationListener

- (void) newRouteIsCalculated:(BOOL)newRoute
{
    dispatch_async(dispatch_get_main_queue(), ^{
        directionInfo = -1;
        [self.tableView reloadData];
    });
}

- (void) routeWasCancelled
{
    directionInfo = -1;
    // do not hide fragment (needed for use case entering Planning mode without destination)
}

- (void) routeWasFinished
{
    
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
        }
        
        if (cell)
        {
            cell.selectedMode = OAMapVariantCar;
            cell.availableModes = @[OAMapVariantCarStr, OAMapVariantBicycleStr, OAMapVariantPedestrianStr];
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
            [cell.imgView setImage:[UIImage imageNamed:@"ic_action_marker.png"]];
            cell.titleLabel.text = OALocalizedString(@"route_from");
            NSString *oname = [point getOnlyName].length > 0 ? [point getOnlyName] : [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"map_settings_map"), [self getRoutePointDescription:[point getLatitude] lon:[point getLongitude]]];
            cell.addressLabel.text = oname;
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
            NSString *oname = [self getRoutePointDescription:point.point d:[point getOnlyName]];
            cell.addressLabel.text = oname;
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
        }
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _rowsCount;
}

@end
