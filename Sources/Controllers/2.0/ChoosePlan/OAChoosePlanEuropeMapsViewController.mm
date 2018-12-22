//
//  OAChoosePlanEuropeMapsViewController.m
//  OsmAnd
//
//  Created by Alexey on 22/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanEuropeMapsViewController.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "Localization.h"

@interface OAChoosePlanEuropeMapsViewController ()

@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;

@end

@implementation OAChoosePlanEuropeMapsViewController

@synthesize planTypeFeatures = _planTypeFeatures;

- (void) commonInit
{
    [super commonInit];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureRegionEurope],
                              [[OAFeature alloc] initWithFeature:EOAFeatureMonthlyMapUpdates]];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_europe");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].europe;
}

@end
