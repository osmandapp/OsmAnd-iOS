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
                    [targets reorderAllTargetPoints:alocs updateRoute:YES];
                
                if (onComplete)
                    onComplete();
            });
        }];
    });
}

@end
