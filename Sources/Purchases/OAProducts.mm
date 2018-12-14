//
//  OAInAppPurchases.m
//  OsmAnd
//
//  Created by Alexey on 11/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAProducts.h"
#import <StoreKit/StoreKit.h>
#import "OsmAndApp.h"
#import "Localization.h"

@interface OAFunctionalAddon()

@property (nonatomic, copy) NSString *addonId;
@property (nonatomic, copy) NSString *titleShort;
@property (nonatomic, copy) NSString *titleWide;
@property (nonatomic, copy) NSString *imageName;

@end

@implementation OAFunctionalAddon

- (instancetype) initWithAddonId:(NSString *)addonId titleShort:(NSString *)titleShort titleWide:(NSString *)titleWide imageName:(NSString *)imageName
{
    self = [super init];
    if (self)
    {
        self.addonId = addonId;
        self.titleShort = titleShort;
        self.titleWide = titleWide;
        self.imageName = imageName;
    }
    return self;
}

@end

@interface OAProduct()

@property (nonatomic, copy) NSString *productIdentifier;
@property (nonatomic, copy) NSString *localizedDescription;
@property (nonatomic, copy) NSString *localizedDescriptionExt;
@property (nonatomic, copy) NSString *localizedTitle;
@property (nonatomic) NSDecimalNumber *price;
@property (nonatomic) NSLocale *priceLocale;
@property (nonatomic) EOAPurchaseState purchaseState; // PSTATE_UNKNOWN
@property (nonatomic) BOOL free;
@property (nonatomic) BOOL disabled;

@end

@implementation OAProduct
{
    NSNumberFormatter *_numberFormatter;
}

- (instancetype) initWithSkProduct:(SKProduct *)skProduct;
{
    self = [super init];
    if (self)
    {
        self.skProduct = skProduct;
        self.purchaseState = PSTATE_UNKNOWN;
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithIdentifier:(NSString *)productIdentifier title:(NSString *)title desc:(NSString *)desc price:(NSDecimalNumber *)price priceLocale:(NSLocale *)priceLocale
{
    self = [super init];
    if (self)
    {
        self.productIdentifier = productIdentifier;
        self.localizedTitle = title;
        self.localizedDescription = desc;
        self.price = price;
        self.priceLocale = priceLocale;
        self.purchaseState = PSTATE_UNKNOWN;

        [self commonInit];
    }
    return self;
}

- (instancetype) initWithIdentifier:(NSString *)productIdentifier;
{
    self = [super init];
    if (self)
    {
        self.productIdentifier = productIdentifier;
        
        NSString *postfix = [[productIdentifier componentsSeparatedByString:@"."] lastObject];
        NSString *locTitleId = [@"product_title_" stringByAppendingString:postfix];
        NSString *locDescriptionId = [@"product_desc_" stringByAppendingString:postfix];
        NSString *locDescriptionExtId = [@"product_desc_ext_" stringByAppendingString:postfix];
        
        self.localizedTitle = OALocalizedString(locTitleId);
        self.localizedDescription = OALocalizedString(locDescriptionId);
        self.localizedDescriptionExt = OALocalizedString(locDescriptionExtId);
        
        self.purchaseState = PSTATE_UNKNOWN;

        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    if (self.free && ![self isAlreadyPurchased])
    {
        [self setPurchased];
        self.disabled = YES;
    }
}

- (void) setSkProduct:(SKProduct *)skProduct
{
    self.productIdentifier = skProduct.productIdentifier;
    self.localizedTitle = skProduct.localizedTitle;
    self.localizedDescription = skProduct.localizedDescription;
    self.price = skProduct.price;
    self.priceLocale = skProduct.priceLocale;
    
    NSString *postfix = [[_productIdentifier componentsSeparatedByString:@"."] lastObject];
    NSString *locDescriptionExtId = [@"product_desc_ext_" stringByAppendingString:postfix];
    self.localizedDescriptionExt = OALocalizedString(locDescriptionExtId);
    
    _skProduct = skProduct;
}

- (BOOL) isAlreadyPurchased
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:self.productIdentifier];
}

- (NSString *) getDisabledId
{
    return [self.productIdentifier stringByAppendingString:@"_disabled"];
}

- (BOOL) disabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:[self getDisabledId]] || ![self isPurchased];
}

- (void) setDisabled:(BOOL)disabled
{
    [[NSUserDefaults standardUserDefaults] setBool:disabled forKey:[self getDisabledId]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSNumberFormatter *) getNumberFormatter:(NSLocale *)locale
{
    if (!_numberFormatter)
    {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        _numberFormatter = numberFormatter;
    }
    if (!locale)
        locale = [NSLocale localeWithLocaleIdentifier:@"en_BE"];
    
    [_numberFormatter setLocale:locale];
    return _numberFormatter;
}

- (NSDecimalNumber *) price
{
    if (_price)
        return _price;
    else
        return [self getDefaultPrice];
}

- (NSString *) formattedPrice
{
    NSDecimalNumber *price;
    if (_price)
        price =_price;
    else
        price = [self getDefaultPrice];
    
    if (price)
    {
        NSNumberFormatter *numberFormatter = [self getNumberFormatter:self.priceLocale];
        return [numberFormatter stringFromNumber:price];
    }
    return nil;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return nil;
}

- (BOOL) isPurchased
{
    return self.purchaseState == PSTATE_PURCHASED || [self isAlreadyPurchased];
}

- (BOOL) isActive
{
    return [self isPurchased] && !self.disabled;
}

- (void) setPurchased
{
    self.purchaseState = PSTATE_PURCHASED;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:self.productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) fetchRequired
{
    return !self.free && self.purchaseState == PSTATE_UNKNOWN && ![self isPurchased];
}

- (NSAttributedString *) getTitle
{
    return [[NSAttributedString alloc] initWithString:@""];
}

- (NSAttributedString *) getDescription
{
    NSNumber *price = self.price;
    NSLocale *priceLocale = self.priceLocale;
    if (!price)
        price = [self getDefaultPrice];

    NSString *priceStr;
    if (price)
    {
        NSNumberFormatter *numberFormatter = [self getNumberFormatter:priceLocale];
        priceStr = [numberFormatter stringFromNumber:price];
    }
    else
    {
        priceStr = [OALocalizedString(@"shared_string_buy") upperCase];
    }
    return [[NSAttributedString alloc] initWithString:priceStr];
}

- (NSString *) productIconName
{
    return nil; // non implemented
}

- (NSString *) productScreenshotName
{
    return nil; // non implemented
}

- (BOOL) isEqual:(id)obj
{
    if (self == obj)
        return YES;
    
    if (!obj)
        return NO;
    
    if (![self isKindOfClass:[obj class]])
        return NO;
    
    OAProduct *other = (OAProduct *) obj;
    if (![self.productIdentifier isEqual:other.productIdentifier])
        return NO;

    return YES;
}

- (NSUInteger) hash
{
    return self.productIdentifier.hash;
}

@end

@interface OASubscription()

@property (nonatomic, copy) NSString *subscriptionPeriod;
@property (nonatomic) NSDecimalNumber *monthlyPrice;
@property (nonatomic) NSDecimalNumber *defaultMonthlyPrice;

@property (nonatomic) NSMapTable<NSString *, OASubscription *> *upgrades;
@property (nonatomic, copy) NSString *identifierNoVersion;
@property (nonatomic, assign) BOOL upgrade;

@end

@implementation OASubscription

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        self.upgrades = [NSMapTable strongToStrongObjectsMapTable];
        self.upgrade = NO;
    }
    return self;
}

- (instancetype) initWithIdentifierNoVersion:(NSString *)identifierNoVersion version:(int)version
{
    self = [super initWithIdentifier:[NSString stringWithFormat:@"%@_v%d", identifierNoVersion, version]];
    if (self)
    {
        self.identifierNoVersion = identifierNoVersion;
    }
    return self;
}

- (NSArray<OASubscription *> *) getUpgrades
{
    return _upgrades.objectEnumerator.allObjects;
}

- (OASubscription *) upgradeSubscription:(NSString *)productIdentifier
{
    OASubscription *s = nil;
    if (!self.upgrade)
    {
        s = [self.productIdentifier isEqualToString:productIdentifier] ? self : [self.upgrades objectForKey:productIdentifier];
        if (!s)
        {
            s = [self newInstance:productIdentifier];
            if (s)
            {
                s.upgrade = true;
                [self.upgrades setObject:s forKey:productIdentifier];
            }
        }
    }
    return s;
}

- (BOOL) isAnyPurchased
{
    if ([self isPurchased])
    {
        return YES;
    }
    else
    {
        for (OASubscription *s in [self getUpgrades])
            if ([s isPurchased])
                return YES;
    }
    return NO;
}

- (NSAttributedString *) getDescription
{
    NSNumberFormatter *numberFormatter = [self getNumberFormatter:self.priceLocale];
    NSDecimalNumber *price = self.monthlyPrice;
    NSString *descr = nil;
    if (!price)
        price = self.defaultMonthlyPrice;
    
    if (price)
        descr = [NSString stringWithFormat:OALocalizedString(@"osm_live_payment_month_cost_descr"), [numberFormatter stringFromNumber:price]];
    else
        descr = @"";
    
    return [[NSAttributedString alloc] initWithString:descr];
}

- (NSAttributedString *) getRenewDescription
{
    return [[NSAttributedString alloc] initWithString:@""];
}

- (OASubscription *) newInstance:(NSString *)productIdentifier
{
    return nil; // non implemented
}

@end


@implementation OASkiMapProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_SkiMap];
    if (self)
    {
        self.free = YES;
    }
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Addon_SkiMap_Default_Price];
}

- (NSString *) productIconName
{
    return @"ic_plugin_skimap";
}

- (NSString *) productScreenshotName
{
    return @"img_plugin_skimap.jpg";
}

@end

@implementation OANauticalProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_Nautical];
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Addon_Nautical_Default_Price];
}

- (NSString *) productIconName
{
    return @"ic_plugin_nautical";
}

- (NSString *) productScreenshotName
{
    return @"img_plugin_nautical.jpg";
}

@end

@implementation OATrackRecordingProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_TrackRecording];
    if (self)
    {
        self.free = YES;
    }
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Addon_TrackRecording_Default_Price];
}

- (NSString *) productIconName
{
    return @"ic_plugin_tracrecording";
}

- (NSString *) productScreenshotName
{
    return @"img_plugin_trip_recording.jpg";
}

@end

@implementation OAParkingProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_Parking];
    if (self)
    {
        self.free = YES;
    }
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Addon_Parking_Default_Price];
}

- (NSString *) productIconName
{
    return @"ic_plugin_parking";
}

- (NSString *) productScreenshotName
{
    return @"img_plugin_parking.jpg";
}

@end

@implementation OAWikiProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_Wiki];
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Addon_Wiki_Default_Price];
}

- (NSString *) productIconName
{
    return @"ic_plugin_wikipedia";
}

- (NSString *) productScreenshotName
{
    return @"img_plugin_wikipedia.jpg";
}

@end

@implementation OASrtmProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_Srtm];
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Addon_Srtm_Default_Price]; 
}

- (NSString *) productIconName
{
    return @"ic_plugin_contourlines";
}

- (NSString *) productScreenshotName
{
    return @"img_plugin_contourlines.jpg";
}

@end

@implementation OATripPlanningProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_TripPlanning];
    if (self)
    {
        self.free = YES;
    }
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Addon_TripPlanning_Default_Price];
}

- (NSString *) productIconName
{
    return @"ic_plugin_trip_planning";
}

- (NSString *) productScreenshotName
{
    return @"img_plugin_trip_planning.jpg";
}

@end

@implementation OAAllWorldProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_All_World];
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Region_All_World_Default_Price];
}

@end

@implementation OARussiaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_Russia];
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Region_Russia_Default_Price];
}

@end

@implementation OAAfricaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_Africa];
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Region_Africa_Default_Price];
}

@end

@implementation OAAsiaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_Asia];
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Region_Asia_Default_Price];
}

@end

@implementation OAAustraliaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_Australia];
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Region_Australia_Default_Price];
}

@end

@implementation OAEuropeProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_Europe];
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Region_Europe_Default_Price];
}

@end

@implementation OACentralAmericaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_Central_America];
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Region_Central_America_Default_Price];
}

@end

@implementation OANorthAmericaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_North_America];
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Region_North_America_Default_Price];
}

@end

@implementation OASouthAmericaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_South_America];
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInAppId_Region_South_America_Default_Price];
}

@end

@interface OAProducts()

@property (nonatomic) OAProduct *skiMap;
@property (nonatomic) OAProduct *nautical;
@property (nonatomic) OAProduct *trackRecording;
@property (nonatomic) OAProduct *parking;
@property (nonatomic) OAProduct *wiki;
@property (nonatomic) OAProduct *srtm;
@property (nonatomic) OAProduct *tripPlanning;

@property (nonatomic) OAProduct *allWorld;
@property (nonatomic) OAProduct *russia;
@property (nonatomic) OAProduct *africa;
@property (nonatomic) OAProduct *asia;
@property (nonatomic) OAProduct *australia;
@property (nonatomic) OAProduct *europe;
@property (nonatomic) OAProduct *centralAmerica;
@property (nonatomic) OAProduct *northAmerica;
@property (nonatomic) OAProduct *southAmerica;

@property (nonatomic) NSArray<OAProduct *> *inApps;
@property (nonatomic) NSArray<OAProduct *> *inAppMaps;
@property (nonatomic) NSArray<OAProduct *> *inAppAddons;

@property (nonatomic) NSArray<OAProduct *> *inAppsFree;
@property (nonatomic) NSArray<OAProduct *> *inAppsPaid;
@property (nonatomic) NSArray<OAProduct *> *inAppAddonsPaid;
@property (nonatomic) NSArray<OAProduct *> *inAppPurchased;
@property (nonatomic) NSArray<OAProduct *> *inAppAddonsPurchased;

@property (nonatomic) OASubscription *monthlyLiveUpdates;
@property (nonatomic) OASubscriptionList *liveUpdates;

@end

@implementation OAProducts

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        self.skiMap = [[OASkiMapProduct alloc] init];
        self.nautical = [[OANauticalProduct alloc] init];
        self.trackRecording = [[OATrackRecordingProduct alloc] init];
        self.parking = [[OAParkingProduct alloc] init];
        self.wiki = [[OAWikiProduct alloc] init];
        self.srtm = [[OASrtmProduct alloc] init];
        self.tripPlanning = [[OATripPlanningProduct alloc] init];
        
        self.allWorld = [[OAAllWorldProduct alloc] init];
        self.russia = [[OARussiaProduct alloc] init];
        self.africa = [[OAAfricaProduct alloc] init];
        self.asia = [[OAAsiaProduct alloc] init];
        self.australia = [[OAAustraliaProduct alloc] init];
        self.europe = [[OAEuropeProduct alloc] init];
        self.centralAmerica = [[OACentralAmericaProduct alloc] init];
        self.northAmerica = [[OANorthAmericaProduct alloc] init];
        self.southAmerica = [[OASouthAmericaProduct alloc] init];
        
        self.inAppAddons = @[self.skiMap,
                             self.nautical,
                             self.trackRecording,
                             self.parking,
                             self.wiki,
                             self.srtm,
                             self.tripPlanning];
        
        self.inAppMaps = @[self.allWorld,
                           self.russia,
                           self.africa,
                           self.asia,
                           self.australia,
                           self.europe,
                           self.centralAmerica,
                           self.northAmerica,
                           self.southAmerica];
        
        self.inApps = [self.inAppAddons arrayByAddingObjectsFromArray:self.inAppMaps];
        
        NSMutableArray<OAProduct *> *free = [NSMutableArray array];
        for (OAProduct *p in self.inApps)
            if (p.free)
                [free addObject:p];
        
        self.inAppsFree = free;

        self.inAppsFree = @[self.skiMap,
                            self.trackRecording,
                            self.parking,
                            self.tripPlanning];
        
        NSMutableArray<OAProduct *> *paid = self.inApps.mutableCopy;
        [paid removeObjectsInArray:self.inAppsFree];
        self.inAppsPaid = paid;

        NSMutableArray<OAProduct *> *paidAddons = self.inAppAddons.mutableCopy;
        [paidAddons removeObjectsInArray:self.inAppsFree];
        self.inAppAddonsPaid = paidAddons;

        [self buildFunctionalAddonsArray];
    }
    return self;
}

- (NSArray<OAProduct *> *) inAppsPurchased
{
    NSMutableArray<OAProduct *> *purchased = [NSMutableArray array];
    for (OAProduct *p in self.inAppsPaid)
        if ([p isPurchased])
            [purchased addObject:p];
    
    return purchased;
}

- (NSArray<OAProduct *> *) inAppAddonsPurchased
{
    NSMutableArray<OAProduct *> *purchased = [NSMutableArray array];
    for (OAProduct *p in self.inAppAddonsPaid)
        if ([p isPurchased])
            [purchased addObject:p];
    
    return purchased;
}

+ (NSSet<NSString *> *) getProductIdentifiers:(NSArray<OAProduct *> *)products
{
    NSMutableSet<NSString *> *identifiers = [NSMutableSet set];
    for (OAProduct *p in products)
        [identifiers addObject:p.productIdentifier];
    
    return identifiers;
}

- (OAProduct *) getProduct:(NSString *)productIdentifier
{
    for (OAProduct *p in self.inApps)
        if ([p.productIdentifier isEqualToString:productIdentifier])
            return p;
    
    return nil;
}

- (BOOL) updateProduct:(SKProduct *)skProduct
{
    BOOL res = NO;
    for (OAProduct *p in self.inApps)
        if ([p.productIdentifier isEqualToString:skProduct.productIdentifier])
        {
            p.skProduct = skProduct;
            res = YES;
            break;
        }
    
    return res;
}

- (BOOL) anyMapPurchased
{
    for (OAProduct *p in self.inAppMaps)
        if ([p isPurchased])
            return YES;
    
    return NO;
}

- (BOOL) setPurchased:(NSString * _Nonnull)productIdentifier
{
    OAProduct *product = [self getProduct:productIdentifier];
    if (product)
    {
        [product setPurchased];
        [self buildFunctionalAddonsArray];
        return YES;
    }
    return NO;
}

- (void) disableProduct:(OAProduct *)product
{
    product.disabled = YES;
    [self buildFunctionalAddonsArray];
    [[[OsmAndApp instance] addonsSwitchObservable] notifyEventWithKey:product.productIdentifier andValue:@NO];
}

- (void) enableProduct:(OAProduct *)product
{
    product.disabled = NO;
    [self buildFunctionalAddonsArray];
    [[[OsmAndApp instance] addonsSwitchObservable] notifyEventWithKey:product.productIdentifier andValue:@YES];
}

- (void) buildFunctionalAddonsArray
{
    NSMutableArray *arr = [NSMutableArray array];
    
    if ([self.parking isPurchased])
    {
        OAFunctionalAddon *addon = [[OAFunctionalAddon alloc] initWithAddonId:kId_Addon_Parking_Set titleShort:OALocalizedString(@"add_parking_short") titleWide:OALocalizedString(@"add_parking") imageName:@"parking_position.png"];
        addon.sortIndex = 0;
        [arr addObject:addon];
    }
    
    if ([self.trackRecording isPurchased])
    {
        OAFunctionalAddon *addon = [[OAFunctionalAddon alloc] initWithAddonId:kId_Addon_TrackRecording_Add_Waypoint titleShort:OALocalizedString(@"add_waypoint_short") titleWide:OALocalizedString(@"add_waypoint") imageName:@"add_waypoint_to_track.png"];
        addon.sortIndex = 1;
        [arr addObject:addon];
    }
    
    [arr sortUsingComparator:^NSComparisonResult(OAFunctionalAddon *obj1, OAFunctionalAddon *obj2) {
        return obj1.sortIndex < obj2.sortIndex ? NSOrderedAscending : NSOrderedDescending;
    }];
    
    if (arr.count == 1)
        _singleAddon = arr[0];
    else
        _singleAddon = nil;
    
    _functionalAddons = [NSArray arrayWithArray:arr];
}

@end
