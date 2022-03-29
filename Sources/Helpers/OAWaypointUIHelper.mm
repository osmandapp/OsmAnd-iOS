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
#import "OAMapLayers.h"
#import "OAPOILayer.h"
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
#import "OADestinationsHelper.h"
#import "OADestination.h"
#import "OAFavoriteItem.h"
#import "OADestinationItem.h"

#include <OsmAndCore/Map/FavoriteLocationsPresenter.h>

@implementation OAWaypointUIHelper

+ (void) showOnMap:(OALocationPointWrapper *)p
{
    id<OALocationPoint> point = p.point;
    
    double latitude = [point getLatitude];
    double longitude = [point getLongitude];

    OAMapViewController *mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OATargetPoint *targetPoint = [mapVC.mapLayers.contextMenuLayer getUnknownTargetPoint:latitude longitude:longitude];
    targetPoint.title = [point getPointDescription].name;
    targetPoint.centerMap = YES;
    targetPoint.minimized = YES;
    [[OARootViewController instance].mapPanel showContextMenu:targetPoint];
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
            if (lt.count == 0)
                return;

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
                start = lt[0];
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
