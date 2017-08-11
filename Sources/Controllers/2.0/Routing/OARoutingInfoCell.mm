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
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    _routingHelper = [OARoutingHelper sharedInstance];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
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
    if (_directionInfo >= 0 && [_routingHelper getRouteDirections] && _directionInfo < [_routingHelper getRouteDirections].count)
    {
        OARouteDirectionInfo *ri = [_routingHelper getRouteDirections][_directionInfo];
        if (![[ri getDescriptionRoutePart] hasSuffix:[[OsmAndApp instance] getFormattedDistance:ri.distance]])
        {
            _turnInfoLabel.text = [NSString stringWithFormat:@"%d. %@ %@", (_directionInfo + 1), [ri getDescriptionRoutePart],[[OsmAndApp instance] getFormattedDistance:ri.distance]];
        }
        else
        {
            _turnInfoLabel.text = [NSString stringWithFormat:@"%d. %@", (_directionInfo + 1), [ri getDescriptionRoutePart]];
        }
    }
    else
    {
        _distanceLabel.text = [[OsmAndApp instance] getFormattedDistance:[_routingHelper getLeftDistance]];
        _timeLabel.text = [[OsmAndApp instance] getFormattedTimeInterval:[_routingHelper getLeftTime] shortFormat:NO];
    }
}

- (CGPoint) showPinAtLatitude:(double)latitude longitude:(double)longitude
{
    const OsmAnd::LatLon latLon(latitude, longitude);
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OAMapRendererView* mapRendererView = (OAMapRendererView*)mapVC.view;
    Point31 pos = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
    [mapVC goToPosition:pos andZoom:kDefaultZoomOnShow animated:YES];
    [mapVC showContextPinMarker:latLon.latitude longitude:latLon.longitude animated:NO];
    
    CGPoint touchPoint = CGPointMake(mapRendererView.bounds.size.width / 2.0, mapRendererView.bounds.size.height / 2.0);
    touchPoint.x *= mapRendererView.contentScaleFactor;
    touchPoint.y *= mapRendererView.contentScaleFactor;
    return touchPoint;
}

- (void) showTurnOnMap:(double)latitude longitude:(double)longitude title:(NSString *)title
{
    CGPoint touchPoint = [self.class showPinAtLatitude:latitude longitude:longitude];
    
    OAMapSymbol *symbol = [[OAMapSymbol alloc] init];
    symbol.type = OAMapSymbolLocation;
    symbol.touchPoint = CGPointMake(touchPoint.x, touchPoint.y);
    symbol.location = CLLocationCoordinate2DMake(latitude, longitude);
    symbol.caption = title;
    symbol.centerMap = YES;
    [OAMapViewController postTargetNotification:symbol];
}

- (IBAction) leftButtonPress:(id)sender
{
    if (_directionInfo >= 0) {
        _directionInfo--;
    }
    if ([_routingHelper getRouteDirections] && _directionInfo >= 0)
    {
        if ([_routingHelper getRouteDirections].count > _directionInfo)
        {
            OARouteDirectionInfo *info = [_routingHelper getRouteDirections][_directionInfo];
            CLLocation *l = [_routingHelper getLocationFromRouteDirection:info];
            [self showTurnOnMap:l.coordinate.latitude longitude:l.coordinate.longitude title:[info getDescriptionRoute]];
        }
    }
    [self updateControls];
}

- (IBAction) rightButtonPress:(id)sender
{
    if ([_routingHelper getRouteDirections] && _directionInfo < [_routingHelper getRouteDirections].count - 1)
    {
        _directionInfo++;
        OARouteDirectionInfo *info = [_routingHelper getRouteDirections][_directionInfo];
        CLLocation *l = [_routingHelper getLocationFromRouteDirection:info];
        [self showTurnOnMap:l.coordinate.latitude longitude:l.coordinate.longitude title:[info getDescriptionRoute]];
    }
    [self updateControls];
}

@end
