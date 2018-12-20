//
//  OAChoosePlanFreeBannerViewController.m
//  OsmAnd
//
//  Created by Alexey on 20/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanAllMapsViewController.h"
#import "OsmAndApp.h"
#import "OAFirebaseHelper.h"
#import "OAIAPHelper.h"
#import "Localization.h"

@interface OAChoosePlanAllMapsViewController ()

@end

@implementation OAChoosePlanAllMapsViewController
{
    OAIAPHelper *_iapHelper;
    NSArray<OAFeature *> *_osmLiveFeatures;
    NSArray<OAFeature *> *_selectedOsmLiveFeatures;
    NSArray<OAFeature *> *_planTypeFeatures;
    NSArray<OAFeature *> *_selectedPlanTypeFeatures;

}

- (void) commonInit
{
    [super commonInit];
    
    _iapHelper = [OAIAPHelper sharedInstance];
    
    _osmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                         [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads],
                         [[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline],
                         //[[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline],
                         //[[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]
                         [[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps]];
    
    _selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                                 [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads]];
    
    _planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads],
                          [[OAFeature alloc] initWithFeature:EOAFeatureMonthlyMapUpdates]];
    
    _selectedPlanTypeFeatures = @[];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
}

- (NSArray<OAFeature *> *) getOsmLiveFeatures
{
    return _osmLiveFeatures;
}

- (NSArray<OAFeature *> *) getPlanTypeFeatures
{
    return _planTypeFeatures;
}

- (NSArray<OAFeature *> *) getSelectedOsmLiveFeatures
{
    return _selectedOsmLiveFeatures;
}

- (NSArray<OAFeature *> *) getSelectedPlanTypeFeatures
{
    return _selectedPlanTypeFeatures;
}

- (UIImage *)getPlanTypeHeaderImage
{
    return [UIImage imageNamed:@"img_logo_38dp_osmand"];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_allworld");
}

- (NSString *) getPlanTypeHeaderDescription
{
    return OALocalizedString(@"in_app_purchase");
}

- (NSString *) getPlanTypeButtonDescription
{
    return OALocalizedString(@"in_app_purchase_desc");
}

- (void) setPlanTypeButtonClickListener:(UIButton *)button
{
    [button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(onPlanTypeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction) onPlanTypeButtonClick:(id)sender
{
    [OAFirebaseHelper logEvent:@"in_app_purchase_redirect_from_banner"];
    [_iapHelper buyProduct:[self getPlanTypeProduct]];
}

- (OAProduct *) getPlanTypeProduct
{
    return _iapHelper.allWorld;
}

@end
