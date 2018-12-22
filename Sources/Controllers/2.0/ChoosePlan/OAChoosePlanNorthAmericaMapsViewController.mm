//
//  OAChoosePlanNorthAmericaMapsViewController.m
//  OsmAnd
//
//  Created by Alexey on 22/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanNorthAmericaMapsViewController.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "Localization.h"

@interface OAChoosePlanNorthAmericaMapsViewController ()

@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;

@end

@implementation OAChoosePlanNorthAmericaMapsViewController

@synthesize planTypeFeatures = _planTypeFeatures;

- (void) commonInit
{
    [super commonInit];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureRegionNorthAmerica],
                              [[OAFeature alloc] initWithFeature:EOAFeatureMonthlyMapUpdates]];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_northamerica");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].northAmerica;
}

@end
