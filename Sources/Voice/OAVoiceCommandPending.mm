//
//  OAVoiceCommandPending.m
//  OsmAnd
//
//  Created by Alexey Kulish on 25/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAVoiceCommandPending.h"
#import "OACommandBuilder.h"
#import "OAVoiceRouter.h"
#import "OARoutingHelper.h"

@implementation OAVoiceCommandPending
{
    int _type;
    OAVoiceRouter *_voiceRouter;
    OARoutingHelper *_routingHelper;
}

- (instancetype)initWithType:(int)type voiceRouter:(OAVoiceRouter *)voiceRouter
{
    self = [super init];
    if (self)
    {
        _type = type;
        _voiceRouter = voiceRouter;
        _routingHelper = [OARoutingHelper sharedInstance];
    }
    return self;
}

- (void) play:(OACommandBuilder *)command
{
    int left = [_routingHelper getLeftDistance];
    long time = [_routingHelper getLeftTime];
    if (left > 0)
    {
        if (_type == ROUTE_CALCULATED)
        {
            [_voiceRouter notifyOnVoiceMessage];
            [[command newRouteCalculated:left time:time] play];
        }
        else if (_type == ROUTE_RECALCULATED)
        {
            [_voiceRouter notifyOnVoiceMessage];
            [[command routeRecalculated:left time:time] play];
        }
    }
}

@end
