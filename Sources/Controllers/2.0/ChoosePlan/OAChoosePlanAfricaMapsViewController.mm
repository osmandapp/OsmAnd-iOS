//
//  OAChoosePlanAfricaMapsViewController.m
//  OsmAnd
//
//  Created by Alexey on 22/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanAfricaMapsViewController.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "Localization.h"

@interface OAChoosePlanAfricaMapsViewController ()

@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;

@end

@implementation OAChoosePlanAfricaMapsViewController

@synthesize planTypeFeatures = _planTypeFeatures;

- (void) commonInit
{
    [super commonInit];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureRegionAfrica],
                              [[OAFeature alloc] initWithFeature:EOAFeatureMonthlyMapUpdates]];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_africa");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].africa;
}

@end
