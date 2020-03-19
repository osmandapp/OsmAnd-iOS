//
//  OATransportRouteResult.m
//  OsmAnd
//
//  Created by Paul on 17.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATransportRouteResult.h"
#import "OATransportStop.h"

@implementation OATransportRouteResult

- (double) getWalkingDistance
{
    double d = _finishWalkDist;
//    for (TransportRouteResultSegment s : segments) {
//        d += s.walkDist;
//    }
    return d;
}

- (double) getWalkingSpeed
{
    return /*_cfg->walkSpeed*/ 1.0;
}

- (NSInteger) getStops
{
    NSInteger stops = 0;
//    for(const auto& s : _segments)
//    {
//        stops += (s.end - s.start);
//    }
    return stops;
}

- (BOOL) isRouteStop:(std::shared_ptr<const OsmAnd::TransportStop>) stop
{
//    for(const auto& s : _segments)
//    {
//        if (s.getTravelStops().contains(stop)) {
//            return YES;
//        }
//    }
    return NO;
}

// Unused in Android
//public TransportRouteResultSegment getRouteStopSegment(TransportStop stop) {
//    for(TransportRouteResultSegment s : segments) {
//        if (s.getTravelStops().contains(stop)) {
//            return s;
//        }
//    }
//    return null;
//}

- (double) getTravelDist
{
    double d = 0;
//    for (TransportRouteResultSegment s : segments) {
//        d += s.getTravelDist();
//    }
    return d;
}

- (double) getTravelTime
{
    double t = 0;
//    for (TransportRouteResultSegment s : segments) {
//        if (cfg.useSchedule) {
//            TransportSchedule sts = s.route.getSchedule();
//            for (int k = s.start; k < s.end; k++) {
//                t += sts.getAvgStopIntervals()[k] * 10;
//            }
//        } else {
//            t += cfg.getBoardingTime();
//            t += s.getTravelTime();
//        }
//    }
    return t;
}

- (double) getWalkTime
{
    return /*self.getWalkingDist / cfg.walkSpeed*/ 0.0;
}

- (double) getChangeTime
{
    return /*cfg.getChangeTime()*/ 0.0;
}

- (double) getBoardingTime
{
    return /*cfg.getBoardingTime()*/ 0.0;
}

- (NSInteger) getChanges
{
    return /*segments.size() - 1*/ 0;
}

- (NSString *) toNSString
{
    NSMutableString *str = [NSMutableString new];
    
    [str appendString:[NSString stringWithFormat:@"Route %ld stops, %ld changes, %.2f min: %.2f m (%.1f min) to walk, %.2f m (%.1f min) to travel\n", (long)[self getStops], [self getChanges], _routeTime / 60, [self getWalkingDistance], [self getWalkTime] / 60.0, [self getTravelDist], [self getTravelTime] / 60.0]];
    //        for(NSInteger i = 0; i < segments.count(); i++)
    //        {
    //            TransportRouteResultSegment s = segments.get(i);
    //            String time = "";
    //            String arriveTime = "";
    //            if(s.depTime != -1) {
    //                time = String.format("at %s", formatTransporTime(s.depTime));
    //            }
    //            int aTime = s.getArrivalTime();
    //            if(aTime != -1) {
    //                arriveTime = String.format("and arrive at %s", formatTransporTime(aTime));
    //            }
    //            bld.append(String.format(" %d. %s: walk %.1f m to '%s' and travel %s to '%s' by %s %d stops %s\n",
    //                    i + 1, s.route.getRef(), s.walkDist, s.getStart().getName(),
    //                     time, s.getEnd().getName(),s.route.getName(),  (s.end - s.start), arriveTime));
    //        }
    [str appendString:[NSString stringWithFormat:@" F. Walk %.1f m to reach your destination", _finishWalkDist]];
    return str;
}

@end
