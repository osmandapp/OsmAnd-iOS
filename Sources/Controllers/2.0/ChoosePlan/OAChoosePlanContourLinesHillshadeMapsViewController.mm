//
//  OAChoosePlanContourLinesHillshadeMapsViewController.m
//  OsmAnd
//
//  Created by Alexey on 22/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanContourLinesHillshadeMapsViewController.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "Localization.h"

@interface OAChoosePlanContourLinesHillshadeMapsViewController ()

@property (nonatomic) NSArray<OAFeature *> *osmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedOsmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedPlanTypeFeatures;

@end

@implementation OAChoosePlanContourLinesHillshadeMapsViewController

@synthesize osmLiveFeatures = _osmLiveFeatures, planTypeFeatures = _planTypeFeatures;
@synthesize selectedOsmLiveFeatures = _selectedOsmLiveFeatures, selectedPlanTypeFeatures = _selectedPlanTypeFeatures;

- (void) commonInit
{
    [super commonInit];
    
    self.osmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps],
                             [[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                             [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads],
                             [[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline]
                             //[[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline]
                             ];
    
    self.selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps]
                                     //[[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]
                                     ];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps]];
    
    self.selectedPlanTypeFeatures = @[];
}

- (UIImage *) getPlanTypeHeaderImage
{
    return [UIImage imageNamed:@"img_logo_38dp_contour_lines"];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_srtm");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].srtm;
}

@end
