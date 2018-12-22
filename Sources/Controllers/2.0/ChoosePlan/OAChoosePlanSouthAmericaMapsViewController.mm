//
//  OAChoosePlanSouthAmericaMapsViewController.m
//  OsmAnd
//
//  Created by Alexey on 22/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanSouthAmericaMapsViewController.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "Localization.h"

@interface OAChoosePlanSouthAmericaMapsViewController ()

@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;

@end

@implementation OAChoosePlanSouthAmericaMapsViewController

@synthesize planTypeFeatures = _planTypeFeatures;

- (void) commonInit
{
    [super commonInit];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureRegionSouthAmerica],
                              [[OAFeature alloc] initWithFeature:EOAFeatureMonthlyMapUpdates]];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_southamerica");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].southAmerica;
}

@end
