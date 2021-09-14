//
//  OANextTurnInfoWidget.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OANextTurnWidget.h"
#import "OsmAndApp.h"
#import "OATurnDrawable.h"
#import "OARoutingHelper.h"
#import "OARouteDirectionInfo.h"
#import "OARouteCalculationResult.h"
#import "OAUtilities.h"
#import "OAVoiceRouter.h"
#import "OAAppSettings.h"
#import "OAOsmAndFormatter.h"

@interface OANextTurnWidget ()

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *leftView;

@end

@implementation OANextTurnWidget
{
    BOOL _horisontalMini;
    
    int _deviatedPath;
    int _nextTurnDistance;
    
    OATurnDrawable *_turnDrawable;
    OsmAndAppInstance _app;
    
    BOOL _nextNext;
    OANextDirectionInfo *_calc1;
}

- (instancetype) initWithHorisontalMini:(BOOL)horisontalMini nextNext:(BOOL)nextNext
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _horisontalMini = horisontalMini;
        _nextNext = nextNext;
        _calc1 = [[OANextDirectionInfo alloc] init];
        _turnDrawable = [[OATurnDrawable alloc] initWithMini:horisontalMini];
        if (horisontalMini)
        {
            [self setTurnDrawable:_turnDrawable gone:NO];
            [self setTopTurnDrawable:nil];
        }
        else
        {
            [self setTurnDrawable:nil gone:YES];
            [self setTopTurnDrawable:_turnDrawable];
        }
        if (!_nextNext)
        {
            self.onClickFunction = ^(id sender) {
                OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
                if ([routingHelper isRouteCalculated] && ![OARoutingHelper isDeviatedFromRoute])
                {
                    [[routingHelper getVoiceRouter] announceCurrentDirection:nil];
                }

            };
        }
    }
    return self;
}

- (void) setTurnDrawable:(OATurnDrawable *)turnDrawable gone:(BOOL)gone
{
    if (turnDrawable)
    {
        [self setSubview:self.leftView subview:turnDrawable];
        self.leftView.hidden = NO;
        [self setImageHidden:NO];
    }
    else
    {
        self.leftView.hidden = gone;
        [self setImageHidden:gone];
    }
}

- (void) setTopTurnDrawable:(OATurnDrawable *)turnDrawable
{
    if (turnDrawable)
    {
        [self setSubview:self.topView subview:turnDrawable];
        self.topView.hidden = NO;
    }
    else
    {
        self.topView.hidden = YES;
    }
}

- (void) setSubview:(UIView *)view subview:(UIView *)subview
{
    for (UIView *v in view.subviews)
        [v removeFromSuperview];
    
    subview.frame = view.bounds;
    [view addSubview:subview];
}

- (CGFloat) getWidgetHeight
{
    if (_horisontalMini)
        return kTextInfoWidgetHeight;
    else
        return kNextTurnInfoWidgetHeight;
}

- (BOOL) distChanged:(CLLocationDistance)oldDist dist:(CLLocationDistance)dist
{
    return oldDist == 0 || ABS(oldDist - dist) > 10;
}

- (std::shared_ptr<TurnType>) getTurnType
{
    return _turnDrawable.turnType;
}

- (void) setTurnType:(std::shared_ptr<TurnType>)turnType
{
    BOOL vis = [self updateVisibility:turnType != nullptr];
    if ([_turnDrawable setTurnType:turnType] || vis)
    {
        _turnDrawable.textFont = self.primaryFont;
        _turnDrawable.textColor = self.primaryColor;
        if (_horisontalMini)
            [self setTurnDrawable:_turnDrawable gone:false];
        else
            [self setTopTurnDrawable:_turnDrawable];
    }
}

- (void) setTurnImminent:(int)turnImminent deviatedFromRoute:(BOOL)deviatedFromRoute
{
    if (_turnDrawable.turnImminent != turnImminent || _turnDrawable.deviatedFromRoute != deviatedFromRoute)
    {
        [_turnDrawable setTurnImminent:turnImminent deviatedFromRoute:deviatedFromRoute];
    }
}

- (void) setDeviatePath:(int)deviatePath
{
    if ([self distChanged:deviatePath dist:_deviatedPath])
    {
        _deviatedPath = deviatePath;
        [self updateDistance];
    }
}

- (void) setTurnDistance:(int)nextTurnDistance
{
    if ([self distChanged:nextTurnDistance dist:_nextTurnDistance])
    {
        _nextTurnDistance = nextTurnDistance;
        [self updateDistance];
    }
}

- (void) updateDistance
{
    int deviatePath = _turnDrawable.deviatedFromRoute ? _deviatedPath : _nextTurnDistance;
    NSString *ds = [OAOsmAndFormatter getFormattedDistance:deviatePath];
    
    if (ds)
    {
        auto turnType = [self getTurnType];
        OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
        if (turnType && routingHelper)
            [self setContentDescription:[NSString stringWithFormat:@"%@ %@", ds, [OARouteCalculationResult toString:turnType shortName:NO]]];
        else
            [self setContentDescription:ds];
    }
    
    int ls = [ds indexOf:@" "];
    if (ls == -1)
        [self setTextNoUpdateVisibility:ds subtext:nil];
    else
        [self setTextNoUpdateVisibility:[ds substringToIndex:ls] subtext:[ds substringFromIndex:ls + 1]];
}

- (BOOL) updateInfo
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    OAAppSettings *settings = [OAAppSettings sharedManager];
    BOOL followingMode = [routingHelper isFollowingMode]/* || app.getLocationProvider().getLocationSimulation().isRouteAnimating()*/;
    std::shared_ptr<TurnType> turnType = nullptr;
    BOOL deviatedFromRoute = false;
    int turnImminent = 0;
    int nextTurnDistance = 0;
    if (routingHelper && [routingHelper isRouteCalculated] && followingMode)
    {
        deviatedFromRoute = [OARoutingHelper isDeviatedFromRoute];
        if (!_nextNext)
        {
            if (deviatedFromRoute)
            {
                turnImminent = 0;
                turnType = TurnType::ptrValueOf(TurnType::OFFR, [OADrivingRegion isLeftHandDriving:[settings.drivingRegion get]]);
                [self setDeviatePath:(int) [routingHelper getRouteDeviation]];
            }
            else
            {
                OANextDirectionInfo *r = [routingHelper getNextRouteDirectionInfo:_calc1 toSpeak:true];
                if (r && r.distanceTo > 0 && r.directionInfo)
                {
                    turnType = r.directionInfo.turnType;
                    nextTurnDistance = r.distanceTo;
                    turnImminent = r.imminent;
                }
            }
        }
        else
        {
            OANextDirectionInfo *r = [routingHelper getNextRouteDirectionInfo:_calc1 toSpeak:true];
            if (!deviatedFromRoute)
            {
                if (r)
                    r = [routingHelper getNextRouteDirectionInfoAfter:r to:_calc1 toSpeak:true];
            }
            if (r && r.distanceTo > 0 && r.directionInfo)
            {
                turnType = r.directionInfo.turnType;
                nextTurnDistance = r.distanceTo;
                turnImminent = r.imminent;
            }
        }
    }
    [self setTurnType:turnType];
    [self setTurnImminent:turnImminent deviatedFromRoute:deviatedFromRoute];
    [self setTurnDistance:nextTurnDistance];

    return YES;
}

@end
