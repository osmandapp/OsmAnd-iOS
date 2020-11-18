//
//  OAChoosePlanMapControllers.m
//  OsmAnd
//
//  Created by Alexey on 23/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanMapControllers.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "Localization.h"
#import "OAResourcesUIHelper.h"

@interface OAChoosePlanAllMapsViewController ()

@property (nonatomic) NSArray<OAFeature *> *osmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedOsmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedPlanTypeFeatures;

@end

@implementation OAChoosePlanAllMapsViewController

@synthesize osmLiveFeatures = _osmLiveFeatures, planTypeFeatures = _planTypeFeatures;
@synthesize selectedOsmLiveFeatures = _selectedOsmLiveFeatures, selectedPlanTypeFeatures = _selectedPlanTypeFeatures;

- (void) commonInit
{
    [super commonInit];
    
    self.osmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                             [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads],
                             [[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline],
                             [[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps],
                             [[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]];
//                             [[OAFeature alloc] initWithFeature:EOAFeatureUnlockAllFeatures]];
                             //[[OAFeature alloc] initWithFeature:EOAFeatureNautical],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureSkiMap],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureParking],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureTripRecording]];
    
    self.selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                                     [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads]];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads],
                              [[OAFeature alloc] initWithFeature:EOAFeatureMonthlyMapUpdates]];
    
    self.selectedPlanTypeFeatures = @[];
}

- (NSString *) getPlanTypeTopText
{
    if (![OAResourcesUIHelper checkIfDownloadAvailable])
        return OALocalizedString(@"res_free_exp");
    else
        return nil;
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_allworld");
}

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_allworld");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].allWorld;
}

@end

@implementation OAChoosePlanAfricaMapsViewController

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

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_africa_short");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].africa;
}

@end

@implementation OAChoosePlanAsiaMapsViewController

- (void) commonInit
{
    [super commonInit];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureRegionAsia],
                              [[OAFeature alloc] initWithFeature:EOAFeatureMonthlyMapUpdates]];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_asia");
}

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_asia_short");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].asia;
}

@end

@implementation OAChoosePlanRussiaMapsViewController

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

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_russia_short");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].russia;
}

@end

@implementation OAChoosePlanEuropeMapsViewController

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

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_europe_short");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].europe;
}

@end

@implementation OAChoosePlanAustraliaMapsViewController

- (void) commonInit
{
    [super commonInit];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureRegionAustralia],
                              [[OAFeature alloc] initWithFeature:EOAFeatureMonthlyMapUpdates]];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_australia");
}

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_australia_short");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].australia;
}

@end

@implementation OAChoosePlanNorthAmericaMapsViewController

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

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_northamerica_short");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].northAmerica;
}

@end

@implementation OAChoosePlanCentralAmericaMapsViewController

- (void) commonInit
{
    [super commonInit];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureRegionCentralAmerica],
                              [[OAFeature alloc] initWithFeature:EOAFeatureMonthlyMapUpdates]];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_centralamerica");
}

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_centralamerica_short");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].centralAmerica;
}

@end

@implementation OAChoosePlanSouthAmericaMapsViewController

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

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_southamerica_short");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].southAmerica;
}

@end
