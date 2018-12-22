//
//  OAChoosePlanHelper.m
//  OsmAnd
//
//  Created by Alexey on 22/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanHelper.h"
#import "OAChoosePlanAllMapsViewController.h"
#import "OAChoosePlanContourLinesHillshadeMapsViewController.h"
#import "OAChoosePlanOsmLiveBannerViewController.h"
#import "OAChoosePlanSeaDepthMapsViewController.h"
#import "OAChoosePlanWikipediaViewController.h"
#import "OAChoosePlanWikivoyageViewController.h"
#import "OAChoosePlanAfricaMapsViewController.h"
#import "OAChoosePlanAsiaMapsViewController.h"
#import "OAChoosePlanRussiaMapsViewController.h"
#import "OAChoosePlanEuropeMapsViewController.h"
#import "OAChoosePlanAustraliaMapsViewController.h"
#import "OAChoosePlanNorthAmericaMapsViewController.h"
#import "OAChoosePlanCentralAmericaMapsViewController.h"
#import "OAChoosePlanSouthAmericaMapsViewController.h"
#import "OAIAPHelper.h"

@implementation OAChoosePlanHelper

+ (void) showChoosePlanScreen:(OAProduct *)product navController:(UINavigationController *)navController
{
    if (!product)
        [OAChoosePlanHelper showImpl:[[OAChoosePlanOsmLiveBannerViewController alloc] init] navController:navController];
    else if ([product isEqual:[OAChoosePlanAllMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanAllMapsViewController alloc] init] navController:navController];
    else if ([product isEqual:[OAChoosePlanContourLinesHillshadeMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanContourLinesHillshadeMapsViewController alloc] init] navController:navController];
    else if ([product isEqual:[OAChoosePlanSeaDepthMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanSeaDepthMapsViewController alloc] init] navController:navController];
    else if ([product isEqual:[OAChoosePlanWikipediaViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanWikipediaViewController alloc] init] navController:navController];
    else if ([product isEqual:[OAChoosePlanWikivoyageViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanWikivoyageViewController alloc] init] navController:navController];
    else if ([product isEqual:[OAChoosePlanAfricaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanAfricaMapsViewController alloc] init] navController:navController];
    else if ([product isEqual:[OAChoosePlanAsiaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanAsiaMapsViewController alloc] init] navController:navController];
    else if ([product isEqual:[OAChoosePlanRussiaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanRussiaMapsViewController alloc] init] navController:navController];
    else if ([product isEqual:[OAChoosePlanEuropeMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanEuropeMapsViewController alloc] init] navController:navController];
    else if ([product isEqual:[OAChoosePlanAustraliaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanAustraliaMapsViewController alloc] init] navController:navController];
    else if ([product isEqual:[OAChoosePlanNorthAmericaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanNorthAmericaMapsViewController alloc] init] navController:navController];
    else if ([product isEqual:[OAChoosePlanCentralAmericaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanCentralAmericaMapsViewController alloc] init] navController:navController];
    else if ([product isEqual:[OAChoosePlanSouthAmericaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanSouthAmericaMapsViewController alloc] init] navController:navController];
}

+ (void) showImpl:(OAChoosePlanViewController *)viewController navController:(UINavigationController *)navController
{
    UINavigationController *modalController = [[UINavigationController alloc] initWithRootViewController:viewController];
    modalController.navigationBarHidden = YES;
    modalController.automaticallyAdjustsScrollViewInsets = NO;
    modalController.edgesForExtendedLayout = UIRectEdgeNone;
    [navController presentViewController:modalController animated:YES completion:nil];
}

@end
