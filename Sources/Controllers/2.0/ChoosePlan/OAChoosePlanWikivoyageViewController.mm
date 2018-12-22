//
//  OAChoosePlanWikivoyageViewController.m
//  OsmAnd
//
//  Created by Alexey on 22/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanWikivoyageViewController.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "Localization.h"

@interface OAChoosePlanWikivoyageViewController ()

@property (nonatomic) NSArray<OAFeature *> *osmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedOsmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedPlanTypeFeatures;

@end

@implementation OAChoosePlanWikivoyageViewController

@synthesize osmLiveFeatures = _osmLiveFeatures, planTypeFeatures = _planTypeFeatures;
@synthesize selectedOsmLiveFeatures = _selectedOsmLiveFeatures, selectedPlanTypeFeatures = _selectedPlanTypeFeatures;

- (void) commonInit
{
    [super commonInit];
        
    self.osmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline],
                             [[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline],
                             [[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                             [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads],
                             [[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps]
                             //[[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]
                             ];
    
    self.selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline],
                                     [[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline]];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline]];
    
    self.selectedPlanTypeFeatures = @[];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_wikivoyage");
}

+ (OAProduct *) getPlanTypeProduct
{
    return nil;//[OAIAPHelper sharedInstance].wikivoyage; non implemented yet
}

@end
