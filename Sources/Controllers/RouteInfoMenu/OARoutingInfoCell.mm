//
//  OARoutingInfoCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutingInfoCell.h"
#import "OARoutingHelper.h"
#import "OARouteDirectionInfo.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

#define kDefaultZoomOnShow 16.0f

@implementation OARoutingInfoCell
{
    OARoutingHelper *_routingHelper;
    CALayer *_divider;
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    // Initialization code
    _divider = [CALayer layer];
    _divider.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    [self.contentView.layer addSublayer:_divider];

    _routingHelper = [OARoutingHelper sharedInstance];
    _directionInfo = -1;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    _divider.frame = CGRectMake(51.0, self.contentView.frame.size.height - 0.5, self.contentView.frame.size.width - 101.0, 0.5);
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setDirectionInfo:(int)directionInfo
{
    int prevInfo = _directionInfo;
    _directionInfo = directionInfo;
    
    if (_directionInfo != prevInfo)
        [self updateControls];
}

-(void) updateControls
{
    _leftArrowButton.hidden = _directionInfo < 0;
    _rightArrowButton.hidden = NO;
    
    if (_directionInfo >= 0)
    {
        _trackImgView.hidden = YES;
        _timeImgView.hidden = YES;
        _distanceTitleLabel.hidden = YES;
        _distanceLabel.hidden = YES;
        _timeTitleLabel.hidden = YES;
        _timeLabel.hidden = YES;
        _turnInfoLabel.hidden = NO;
    }
    else
    {
        _trackImgView.hidden = NO;
        _timeImgView.hidden = NO;
        _distanceTitleLabel.hidden = NO;
        _distanceLabel.hidden = NO;
        _timeTitleLabel.hidden = NO;
        _timeLabel.hidden = NO;
        _turnInfoLabel.hidden = YES;
    }
    NSArray<OARouteDirectionInfo *> *routeDirections = [_routingHelper getRouteDirections];
    if (_directionInfo >= 0 && routeDirections && _directionInfo < routeDirections.count)
    {
        OARouteDirectionInfo *ri = routeDirections[_directionInfo];
        _turnInfoLabel.text = [self getTurnDescription:ri];
    }
    else
    {
        _distanceLabel.text = [[OsmAndApp instance] getFormattedDistance:[_routingHelper getLeftDistance]];
        _timeLabel.text = [[OsmAndApp instance] getFormattedTimeInterval:[_routingHelper getLeftTime] shortFormat:NO];
    }
}

- (NSString *) getTurnDescription:(OARouteDirectionInfo *)ri
{
    if (![[ri getDescriptionRoutePart] hasSuffix:[[OsmAndApp instance] getFormattedDistance:ri.distance]])
    {
        return [NSString stringWithFormat:@"%d. %@ %@", (_directionInfo + 1), [ri getDescriptionRoutePart],[[OsmAndApp instance] getFormattedDistance:ri.distance]];
    }
    else
    {
        return [NSString stringWithFormat:@"%d. %@", (_directionInfo + 1), [ri getDescriptionRoutePart]];
    }
}

- (void) showTurnOnMap:(double)latitude longitude:(double)longitude title:(NSString *)title
{
    const OsmAnd::LatLon latLon(latitude, longitude);
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.type = OATargetTurn;
    targetPoint.location = CLLocationCoordinate2DMake(latitude, longitude);
    targetPoint.centerMap = YES;
    targetPoint.title = title;
    targetPoint.centerMap = YES;
    targetPoint.minimized = YES;
    [[OARootViewController instance].mapPanel showContextMenu:targetPoint];
}

- (IBAction) leftButtonPress:(id)sender
{
    if (_directionInfo >= 0) {
        _directionInfo--;
    }
    NSArray<OARouteDirectionInfo *> *routeDirections = [_routingHelper getRouteDirections];
    if (routeDirections && _directionInfo >= 0)
    {
        if ((int)routeDirections.count > _directionInfo)
        {
            OARouteDirectionInfo *info = routeDirections[_directionInfo];
            CLLocation *l = [_routingHelper getLocationFromRouteDirection:info];
            [self showTurnOnMap:l.coordinate.latitude longitude:l.coordinate.longitude title:[self getTurnDescription:info]];
        }
    }
    [self updateControls];
}

- (IBAction) rightButtonPress:(id)sender
{
    NSArray<OARouteDirectionInfo *> *routeDirections = [_routingHelper getRouteDirections];
    if (routeDirections && _directionInfo < (int)routeDirections.count - 1)
    {
        _directionInfo++;
        OARouteDirectionInfo *info = routeDirections[_directionInfo];
        CLLocation *l = [_routingHelper getLocationFromRouteDirection:info];
        [self showTurnOnMap:l.coordinate.latitude longitude:l.coordinate.longitude title:[self getTurnDescription:info]];
    }
    [self updateControls];
}

@end
