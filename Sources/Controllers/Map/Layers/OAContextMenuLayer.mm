//
//  OAContextMenuLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAContextMenuLayer.h"
#import "OANativeUtilities.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

@interface OAContextMenuLayer () <CAAnimationDelegate>
@end

@implementation OAContextMenuLayer
{
    // Context pin marker
    std::shared_ptr<OsmAnd::MapMarkersCollection> _contextPinMarkersCollection;
    std::shared_ptr<OsmAnd::MapMarker> _contextPinMarker;
    
    UIImageView *_animatedPin;
    BOOL _animationDone;
    CGFloat _latPin, _lonPin;
    
    BOOL _initDone;
}

+ (NSString *) getLayerId
{
    return kContextMenuLayerId;
}

- (void) initLayer
{
    // Create context pin marker
    _contextPinMarkersCollection.reset(new OsmAnd::MapMarkersCollection());
    _contextPinMarker = OsmAnd::MapMarkerBuilder()
    .setIsAccuracyCircleSupported(false)
    .setBaseOrder(-210000)
    .setIsHidden(true)
    .setPinIcon([OANativeUtilities skBitmapFromPngResource:@"ic_map_pin"])
    .setPinIconVerticalAlignment(OsmAnd::MapMarker::Top)
    .setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal)
    .buildAndAddToCollection(_contextPinMarkersCollection);

    _initDone = YES;

    // Add context pin markers
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_contextPinMarkersCollection];
    }];
}

- (void) onFrameRendered
{
    if (_initDone && _animatedPin)
    {
        if (_animationDone)
        {
            [self hideAnimatedPin];
        }
        else
        {
            CGPoint targetPoint;
            OsmAnd::PointI targetPositionI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_latPin, _lonPin));
            [self.mapView convert:&targetPositionI toScreen:&targetPoint];
            _animatedPin.center = CGPointMake(targetPoint.x, targetPoint.y);
        }
    }
}

- (std::shared_ptr<OsmAnd::MapMarker>) getContextPinMarker
{
    return _contextPinMarker;
}

- (void) showContextPinMarker:(double)latitude longitude:(double)longitude animated:(BOOL)animated
{
    if (!_initDone)
        return;
    
    _contextPinMarker->setIsHidden(true);
    
    if (!self.mapView.hidden && animated)
    {
        _animationDone = NO;
        
        _latPin = latitude;
        _lonPin = longitude;
        
        const OsmAnd::LatLon latLon(_latPin, _lonPin);
        _contextPinMarker->setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon));
        
        if (_animatedPin)
            [self hideAnimatedPin];
        
        _animatedPin = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_map_pin"]];
        
        @try
        {
            CGPoint targetPoint;
            OsmAnd::PointI targetPositionI = OsmAnd::Utilities::convertLatLonTo31(latLon);
            [self.mapView convert:&targetPositionI toScreen:&targetPoint];
            
            _animatedPin.center = CGPointMake(targetPoint.x, targetPoint.y);
        }
        @catch (NSException *e)
        {
            _animatedPin = nil;
            _contextPinMarker->setIsHidden(false);
            return;
        }
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation
                                          animationWithKeyPath:@"transform"];
        
        CATransform3D scale1 = CATransform3DMakeScale(0.5, 0.5, 1);
        CATransform3D scale2 = CATransform3DMakeScale(1.2, 1.2, 1);
        CATransform3D scale3 = CATransform3DMakeScale(0.9, 0.9, 1);
        CATransform3D scale4 = CATransform3DMakeScale(1.0, 1.0, 1);
        
        NSArray *frameValues = [NSArray arrayWithObjects:
                                [NSValue valueWithCATransform3D:scale1],
                                [NSValue valueWithCATransform3D:scale2],
                                [NSValue valueWithCATransform3D:scale3],
                                [NSValue valueWithCATransform3D:scale4],
                                nil];
        [animation setValues:frameValues];
        
        NSArray *frameTimes = [NSArray arrayWithObjects:
                               [NSNumber numberWithFloat:0.0],
                               [NSNumber numberWithFloat:0.5],
                               [NSNumber numberWithFloat:0.9],
                               [NSNumber numberWithFloat:1.0],
                               nil];
        [animation setKeyTimes:frameTimes];
        
        animation.fillMode = kCAFillModeForwards;
        animation.removedOnCompletion = NO;
        animation.duration = .3;
        animation.delegate = self;
        _animatedPin.layer.anchorPoint = CGPointMake(0.5, 1.0);
        [_animatedPin.layer addAnimation:animation forKey:@"popup"];
        
        [self.mapView addSubview:_animatedPin];
    }
    else
    {
        const OsmAnd::LatLon latLon(latitude, longitude);
        _contextPinMarker->setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon));
        _contextPinMarker->setIsHidden(false);
    }
}

- (void) hideContextPinMarker
{
    if (!_initDone)
        return;

    _contextPinMarker->setIsHidden(true);
}

- (void) hideAnimatedPin
{
    if (_animatedPin)
    {
        [_animatedPin.layer removeAllAnimations];
        [_animatedPin removeFromSuperview];
        _animatedPin = nil;
    }
}

#pragma  mark - CAAnimationDelegate

- (void) animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    _animationDone = YES;
    _contextPinMarker->setIsHidden(false);
}

@end
