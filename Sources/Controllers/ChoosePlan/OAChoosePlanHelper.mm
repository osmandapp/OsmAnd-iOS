//
//  OAChoosePlanHelper.m
//  OsmAnd
//
//  Created by Alexey on 22/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanHelper.h"
#import "OAChoosePlanPluginControllers.h"
#import "OAChooseOsmLivePlanViewController.h"
#import "OAIAPHelper.h"

@implementation OAChoosePlanHelper

+ (void) showChoosePlanScreenWithSuffix:(NSString *)productIdentifierSuffix navController:(UINavigationController *)navController
{
    if (productIdentifierSuffix.length == 0 || [productIdentifierSuffix isEqualToString:@"osmlive"])
    {
        [self.class showChoosePlanScreenWithProduct:nil navController:navController];
    }
    else
    {
        for (OAProduct *product in [OAIAPHelper sharedInstance].inApps)
            if ([product.productIdentifier hasSuffix:productIdentifierSuffix])
            {
                [self.class showChoosePlanScreenWithProduct:product navController:navController];
                break;
            }
    }
}

+ (void) showChoosePlanScreenWithProduct:(OAProduct * _Nullable)product navController:(UINavigationController *)navController
{
    [self.class showChoosePlanScreenWithProduct:product navController:navController purchasing:NO];
}

+ (void) showChoosePlanScreenWithProduct:(OAProduct * _Nullable)product navController:(UINavigationController *)navController purchasing:(BOOL)purchasing
{
    if (!product || [product isKindOfClass:[OASubscription class]] || [product isKindOfClass:[OAWeatherProduct class]])
        [OAChoosePlanHelper showImpl:[[OAChooseOsmLivePlanViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanAllMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanAllMapsViewController alloc] init] navController:navController purchasing:purchasing product:product];
    
    else if ([product isEqual:[OAChoosePlanContourLinesHillshadeMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanContourLinesHillshadeMapsViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanSeaDepthMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanSeaDepthMapsViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanWikipediaViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanWikipediaViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanWikivoyageViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanWikivoyageViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanSkiMapViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanSkiMapViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanNauticalViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanNauticalViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanTripRecordingViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanTripRecordingViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanParkingViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanParkingViewController alloc] init] navController:navController purchasing:purchasing product:product];

    else if ([product isEqual:[OAChoosePlanAfricaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanAfricaMapsViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanAsiaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanAsiaMapsViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanRussiaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanRussiaMapsViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanEuropeMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanEuropeMapsViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanAustraliaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanAustraliaMapsViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanNorthAmericaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanNorthAmericaMapsViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanCentralAmericaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanCentralAmericaMapsViewController alloc] init] navController:navController purchasing:purchasing product:product];
    else if ([product isEqual:[OAChoosePlanSouthAmericaMapsViewController getPlanTypeProduct]])
        [OAChoosePlanHelper showImpl:[[OAChoosePlanSouthAmericaMapsViewController alloc] init] navController:navController purchasing:purchasing product:product];
}

+ (void) showImpl:(OAChoosePlanViewController *)viewController navController:(UINavigationController *)navController purchasing:(BOOL)purchasing product:(OAProduct * _Nullable)product
{
    viewController.product = product;
    viewController.purchasing = purchasing;

    UINavigationController *modalController = [[UINavigationController alloc] initWithRootViewController:viewController];
    modalController.navigationBarHidden = YES;
    modalController.automaticallyAdjustsScrollViewInsets = NO;
    modalController.edgesForExtendedLayout = UIRectEdgeNone;
    [navController presentViewController:modalController animated:YES completion:nil];
}

@end
