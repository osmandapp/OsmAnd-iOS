//
//  OAChoosePlanPluginControllers.m
//  OsmAnd
//
//  Created by Alexey on 23/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanPluginControllers.h"

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
    
    self.osmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                             [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads],
                             [[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline],
                             [[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps],
                             [[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]];
                             //[[OAFeature alloc] initWithFeature:EOAFeatureNautical],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureSkiMap],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureParking],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureTripRecording]];
    
    self.selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps],
                                     [[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]];
    
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

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_srtm");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].srtm;
}

@end

@interface OAChoosePlanOsmLiveBannerViewController ()

@property (nonatomic) NSArray<OAFeature *> *osmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedOsmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedPlanTypeFeatures;

@end

@implementation OAChoosePlanOsmLiveBannerViewController

@synthesize osmLiveFeatures = _osmLiveFeatures, planTypeFeatures = _planTypeFeatures;
@synthesize selectedOsmLiveFeatures = _selectedOsmLiveFeatures, selectedPlanTypeFeatures = _selectedPlanTypeFeatures;

- (void) commonInit
{
    [super commonInit];
    
    self.planTypeFeatures = @[];
    self.selectedPlanTypeFeatures = @[];
}

@end

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
    
    self.osmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                             [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads],
                             [[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline],
                             [[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps],
                             [[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]];
                             //[[OAFeature alloc] initWithFeature:EOAFeatureNautical],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureSkiMap],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureParking],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureTripRecording]];
    
    self.selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps],
                                     [[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps]];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]];
    
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

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_sea_depth_contours");
}

+ (OAProduct *) getPlanTypeProduct
{
    return nil;//[OAIAPHelper sharedInstance].srtm; non implemented yet
}

@end

@interface OAChoosePlanWikipediaViewController ()

@property (nonatomic) NSArray<OAFeature *> *osmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedOsmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedPlanTypeFeatures;

@end

@implementation OAChoosePlanWikipediaViewController

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
                             //[[OAFeature alloc] initWithFeature:EOAFeatureNautical],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureSkiMap],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureParking],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureTripRecording]];
    
    self.selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline],
                                     [[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline]];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline]];
    
    self.selectedPlanTypeFeatures = @[];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_wiki");
}

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_wiki");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].wiki;
}

@end

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
    
    self.osmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureDailyMapUpdates],
                             [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedDownloads],
                             [[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline],
                             [[OAFeature alloc] initWithFeature:EOAFeatureContourLinesHillshadeMaps],
                             [[OAFeature alloc] initWithFeature:EOAFeatureSeaDepthMaps]];
                             //[[OAFeature alloc] initWithFeature:EOAFeatureNautical],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureSkiMap],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureParking],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureTripRecording]];
    
    self.selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline],
                                     [[OAFeature alloc] initWithFeature:EOAFeatureWikipediaOffline]];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline]];
    
    self.selectedPlanTypeFeatures = @[];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_wikivoyage");
}

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_wikivoyage");
}

+ (OAProduct *) getPlanTypeProduct
{
    return nil;//[OAIAPHelper sharedInstance].wikivoyage; non implemented yet
}

@end

@interface OAChoosePlanSkiMapViewController()

@property (nonatomic) NSArray<OAFeature *> *osmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedOsmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedPlanTypeFeatures;

@end

@implementation OAChoosePlanSkiMapViewController

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
                             //[[OAFeature alloc] initWithFeature:EOAFeatureNautical],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureParking],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureTripRecording]];
    
    self.selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureSkiMap],
                                     [[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline]];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureSkiMap]];
    
    self.selectedPlanTypeFeatures = @[];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_skimap");
}

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_skimap");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].skiMap;
}

@end

@interface OAChoosePlanNauticalViewController()

@property (nonatomic) NSArray<OAFeature *> *osmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedOsmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedPlanTypeFeatures;

@end

@implementation OAChoosePlanNauticalViewController

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
                             //[[OAFeature alloc] initWithFeature:EOAFeatureSkiMap],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureParking],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureTripRecording]];
    
    self.selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureNautical],
                                     [[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline]];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureNautical]];
    
    self.selectedPlanTypeFeatures = @[];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_nautical");
}

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_nautical");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].nautical;
}

@end

@interface OAChoosePlanTripRecordingViewController()

@property (nonatomic) NSArray<OAFeature *> *osmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedOsmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedPlanTypeFeatures;

@end

@implementation OAChoosePlanTripRecordingViewController

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
                             //[[OAFeature alloc] initWithFeature:EOAFeatureNautical],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureSkiMap],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureParking]];
    
    self.selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureTripRecording],
                                     [[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline]];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureTripRecording]];
    
    self.selectedPlanTypeFeatures = @[];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_track_recording");
}

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_track_recording");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].trackRecording;
}

@end


@interface OAChoosePlanParkingViewController()

@property (nonatomic) NSArray<OAFeature *> *osmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *planTypeFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedOsmLiveFeatures;
@property (nonatomic) NSArray<OAFeature *> *selectedPlanTypeFeatures;

@end

@implementation OAChoosePlanParkingViewController

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
                             //[[OAFeature alloc] initWithFeature:EOAFeatureNautical],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureSkiMap],
                             //[[OAFeature alloc] initWithFeature:EOAFeatureTripRecording]];
    
    self.selectedOsmLiveFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureParking],
                                     [[OAFeature alloc] initWithFeature:EOAFeatureWikivoyageOffline]];
    
    self.planTypeFeatures = @[[[OAFeature alloc] initWithFeature:EOAFeatureParking]];
    
    self.selectedPlanTypeFeatures = @[];
}

- (NSString *) getPlanTypeHeaderTitle
{
    return OALocalizedString(@"product_title_parking");
}

- (NSString *) getPlanTypeButtonHeaderText
{
    return OALocalizedString(@"product_desc_track_recording");
}

+ (OAProduct *) getPlanTypeProduct
{
    return [OAIAPHelper sharedInstance].parking;
}

@end
