//
//  OAChoosePlanSeaDepthMapsViewController.m
//  OsmAnd
//
//  Created by Alexey on 22/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanSeaDepthMapsViewController.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "Localization.h"

@interface OAChoosePlanSeaDepthMapsViewController ()

@property (nonatomic) NSArray<OAFeature *> *osmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedOsmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedPlanTypeFeatures;

@end

@implementation OAChoosePlanSeaDepthMapsViewController
{
    OAIAPHelper *_iapHelper;
}

@synthesize osmLiveFeatures = _osmLiveFeatures, planTypeFeatures = _planTypeFeatures;
@synthesize selectedOsmLiveFeatures = _selectedOsmLiveFeatures, selectedPlanTypeFeatures = _selectedPlanTypeFeatures;

- (void) commonInit
{
    [super commonInit];
    
    _iapHelper = [OAIAPHelper sharedInstance];
    
    self.osmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps],
                             [[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline],
                             [[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                             [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads]
                             ];
    
    self.selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps]
                                     //[[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]
                                     ];
    
    self.planTypeFeatures = @[
                              //[[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]
                              ];
    
    self.selectedPlanTypeFeatures = @[];
}

- (UIImage *) getPlanTypeHeaderImage
{
    return [UIImage imageNamed:@"img_logo_38dp_sea_depth"];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_sea_depth_contours");
}

+ (OAProduct *) getPlanTypeProduct
{
    return nil;//[OAIAPHelper sharedInstance].srtm; non implemented yet
}

@end
