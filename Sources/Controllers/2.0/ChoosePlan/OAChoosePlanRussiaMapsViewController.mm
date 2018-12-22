//
//  OAChoosePlanRussiaMapsViewController.m
//  OsmAnd
//
//  Created by Alexey on 22/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanRussiaMapsViewController.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "Localization.h"

@interface OAChoosePlanRussiaMapsViewController ()

@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;

@end

@implementation OAChoosePlanRussiaMapsViewController

@synthesize planTypeFeatures = _planTypeFeatures;

- (void) commonInit
{
    [super commonInit];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureRegionRussia],
                              [[OAFeature alloc] initWithFeature:EOAFeatureMonthlyMapUpdates]];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_russia");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].russia;
}

@end
