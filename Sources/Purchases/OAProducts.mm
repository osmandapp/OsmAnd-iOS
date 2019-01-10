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

- (BOOL) isLiveUpdatesPurchased;

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

- (BOOL) isLiveUpdatesPurchased
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"liveUpdatesPurchasedKey"];
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
    return self.purchaseState == PSTATE_PURCHASED || [self isAlreadyPurchased] || [self isLiveUpdatesPurchased];
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

- (void) setExpired
{
    self.purchaseState = PSTATE_NOT_PURCHASED;
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:self.productIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) fetchRequired
{
    return !self.free && self.purchaseState == PSTATE_UNKNOWN && ![self isPurchased];
}

- (NSAttributedString *) getTitle:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:@""];
}

- (NSAttributedString *) getDescription:(CGFloat)fontSize
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

@property (nonatomic) NSMapTable<NSString *, OASubscription *> *upgrades;
@property (nonatomic, copy) NSString *identifierNoVersion;
@property (nonatomic, assign) BOOL upgrade;

@property (nonatomic, assign) BOOL donationSupported;

- (OASubscription *) newInstance:(NSString *)productIdentifier;
- (NSArray<OASubscription *> *) getUpgrades;

@end

@implementation OASubscription

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithIdentifierNoVersion:(NSString *)identifierNoVersion version:(int)version
{
    self = [super initWithIdentifier:[NSString stringWithFormat:@"%@_v%d", identifierNoVersion, version]];
    if (self)
    {
        self.identifierNoVersion = identifierNoVersion;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    self.upgrades = [NSMapTable strongToStrongObjectsMapTable];
    self.upgrade = NO;
}

- (BOOL) isLiveUpdatesPurchased
{
    return NO;
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
                s.upgrade = YES;
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

- (NSAttributedString *) getDescription:(CGFloat)fontSize
{
    NSNumberFormatter *numberFormatter = [self getNumberFormatter:self.priceLocale];
    NSDecimalNumber *price = self.monthlyPrice;
    NSString *descr = nil;
    if (!price)
        price = [self getDefaultMonthlyPrice];
    
    if (price)
        descr = [NSString stringWithFormat:OALocalizedString(@"osm_live_payment_month_cost_descr"), [numberFormatter stringFromNumber:price]];
    else
        descr = @"";
    
    return [[NSAttributedString alloc] initWithString:descr];
}

- (NSAttributedString *) getRenewDescription:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:@""];
}

- (OASubscription *) newInstance:(NSString *)productIdentifier
{
    return nil; // non implemented
}

- (NSDecimalNumber *) getDefaultMonthlyPrice
{
    return nil;
}

- (NSDecimalNumber *) monthlyPrice
{
    if (_monthlyPrice)
        return _monthlyPrice;
    else
        return [self getDefaultMonthlyPrice];
}

- (NSString *) formattedMonthlyPrice
{
    NSDecimalNumber *price;
    if (_monthlyPrice)
        price =_monthlyPrice;
    else
        price = [self getDefaultMonthlyPrice];
    
    if (price)
    {
        NSNumberFormatter *numberFormatter = [self getNumberFormatter:self.priceLocale];
        return [numberFormatter stringFromNumber:price];
    }
    return nil;
}

@end

@interface OASubscriptionList()

@property (nonatomic) NSArray<OASubscription *> *subscriptions;

@end

@implementation OASubscriptionList

- (instancetype) initWithSubscriptions:(NSArray<OASubscription *> *)subscriptions
{
    self = [super init];
    if (self)
    {
        self.subscriptions = subscriptions;
    }
    return self;
}

- (NSArray<OASubscription *> *) getAllSubscriptions
{
    NSMutableArray<OASubscription *> *res = [NSMutableArray array];
    for (OASubscription *s in self.subscriptions)
    {
        [res addObject:s];
        [res addObjectsFromArray:[s getUpgrades]];
    }
    return res;
}

- (OASubscription *) getPurchasedSubscription
{
    for (OASubscription *s in [self getAllSubscriptions])
        if ([s isPurchased])
            return s;

    return nil;
}

- (NSArray<OASubscription *> *) getVisibleSubscriptions
{
    NSMutableArray<OASubscription *> *res = [NSMutableArray array];
    for (OASubscription *s in self.subscriptions)
    {
        BOOL added = NO;
        if ([s isPurchased])
        {
            [res addObject:s];
            added = YES;
        }
        else
        {
            for (OASubscription *upgrade in [s getUpgrades])
            {
                if ([upgrade isPurchased])
                {
                    [res addObject:upgrade];
                    added = YES;
                }
            }
        }
        if (!added)
        {
            for (OASubscription *upgrade in [s getUpgrades])
            {
                [res addObject:upgrade];
                added = YES;
            }
        }
        if (!added)
            [res addObject:s];
    }
    return res;
}

- (OASubscription * _Nullable) getSubscriptionByIdentifier:(NSString * _Nonnull)identifier
{
    for (OASubscription *s in [self getAllSubscriptions])
        if ([s.productIdentifier isEqualToString:identifier])
            return s;

    return nil;
}

- (BOOL) containsIdentifier:(NSString * _Nonnull)identifier
{
    return [self getSubscriptionByIdentifier:identifier] != nil;
}

- (OASubscription * _Nullable) upgradeSubscription:(NSString *)identifier
{
    NSArray<OASubscription *> *subscriptions = [self getAllSubscriptions];
    for (OASubscription *s in subscriptions)
    {
        OASubscription *upgrade = [s upgradeSubscription:identifier];
        if (upgrade)
            return upgrade;
    }
    return nil;
}

@end

@implementation OALiveUpdatesMonthly

- (instancetype) initWithVersion:(int)version
{
    self = [self initWithIdentifierNoVersion:kSubscriptionId_Osm_Live_Subscription_Monthly version:version];
    return self;
}

- (instancetype) initWithIdentifierNoVersion:(NSString *)identifierNoVersion version:(int)version
{
    self = [super initWithIdentifierNoVersion:identifierNoVersion version:version];
    if (self)
    {
        self.donationSupported = YES;
    }
    return self;
}

- (instancetype) initWithIdentifier:(NSString *)productIdentifier;
{
    self = [super initWithIdentifier:productIdentifier];
    if (self)
    {
        self.donationSupported = YES;
    }
    return self;
}

- (void) setPrice:(NSDecimalNumber *)price
{
    [super setPrice:price];
    self.monthlyPrice = price;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kSubscription_Osm_Live_Monthly_Price];
}

- (NSDecimalNumber *) getDefaultMonthlyPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kSubscription_Osm_Live_Monthly_Price];
}

- (NSAttributedString *) getTitle:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_monthly_title")];
}

- (NSAttributedString *) getDescription:(CGFloat)fontSize
{
    NSAttributedString *descr = [super getDescription:fontSize];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithAttributedString:descr];
    [text appendAttributedString:[[NSAttributedString alloc] initWithString:@". "]];
    NSMutableAttributedString *boldStr = [[NSMutableAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_contribute_descr")];
    UIFont *boldFont = [UIFont systemFontOfSize:fontSize weight:UIFontWeightBold];
    [boldStr addAttribute:NSFontAttributeName value:boldFont range:NSMakeRange(0, boldStr.length)];
    [text appendAttributedString:boldStr];
    return text;
}

- (NSAttributedString *) getRenewDescription:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_renews_monthly")];
}

- (OASubscription *) newInstance:(NSString *)productIdentifier
{
    return [productIdentifier hasPrefix:self.identifierNoVersion] ? [[OALiveUpdatesMonthly alloc] initWithIdentifier:productIdentifier] : nil;
}

@end

@implementation OALiveUpdates3Months

- (instancetype) initWithVersion:(int)version
{
    self = [super initWithIdentifierNoVersion:kSubscriptionId_Osm_Live_Subscription_3_Months version:version];
    return self;
}

- (void) setPrice:(NSDecimalNumber *)price
{
    [super setPrice:price];
    self.monthlyPrice = [[NSDecimalNumber alloc] initWithDouble:price.doubleValue / 3.0];
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kSubscription_Osm_Live_3_Months_Price];
}

- (NSDecimalNumber *) getDefaultMonthlyPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kSubscription_Osm_Live_3_Months_Monthly_Price];
}

- (NSAttributedString *) getTitle:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_3_months_title")];
}

- (NSAttributedString *) getRenewDescription:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_renews_quarterly")];
}

- (OASubscription *) newInstance:(NSString *)productIdentifier
{
    return [productIdentifier hasPrefix:self.identifierNoVersion] ? [[OALiveUpdates3Months alloc] initWithIdentifier:productIdentifier] : nil;
}

@end

@implementation OALiveUpdatesAnnual

- (instancetype) initWithVersion:(int)version
{
    self = [super initWithIdentifierNoVersion:kSubscriptionId_Osm_Live_Subscription_Annual version:version];
    return self;
}

- (void) setPrice:(NSDecimalNumber *)price
{
    [super setPrice:price];
    self.monthlyPrice = [[NSDecimalNumber alloc] initWithDouble:price.doubleValue / 12.0];
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kSubscription_Osm_Live_Annual_Price];
}

- (NSDecimalNumber *) getDefaultMonthlyPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kSubscription_Osm_Live_Annual_Monthly_Price];
}

- (NSAttributedString *) getTitle:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_annual_title")];
}

- (NSAttributedString *) getRenewDescription:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_renews_annually")];
}

- (OASubscription *) newInstance:(NSString *)productIdentifier
{
    return [productIdentifier hasPrefix:self.identifierNoVersion] ? [[OALiveUpdatesAnnual alloc] initWithIdentifier:productIdentifier] : nil;
}

@end


@implementation OASkiMapProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_SkiMap];
    if (self)
    {
        self.free = YES;
        [self commonInit];
    }
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Addon_SkiMap_Default_Price];
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
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Addon_Nautical_Default_Price];
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
        [self commonInit];
    }
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Addon_TrackRecording_Default_Price];
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
        [self commonInit];
    }
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Addon_Parking_Default_Price];
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
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Addon_Wiki_Default_Price];
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
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Addon_Srtm_Default_Price];
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
        [self commonInit];
    }
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Addon_TripPlanning_Default_Price];
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
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_All_World_Default_Price];
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
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_Russia_Default_Price];
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
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_Africa_Default_Price];
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
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_Asia_Default_Price];
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
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_Australia_Default_Price];
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
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_Europe_Default_Price];
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
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_Central_America_Default_Price];
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
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_North_America_Default_Price];
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
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_South_America_Default_Price];
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

        NSMutableArray<OAProduct *> *paidAddons = self.inAppAddons.mutableCopy;
        [paidAddons removeObjectsInArray:self.inAppsFree];
        self.inAppAddonsPaid = paidAddons;

        self.monthlyLiveUpdates = [[OALiveUpdatesMonthly alloc] initWithVersion:1];
        self.liveUpdates = [[OASubscriptionList alloc] initWithSubscriptions:@[self.monthlyLiveUpdates,
                                                                               [[OALiveUpdates3Months alloc] initWithVersion:1],
                                                                               [[OALiveUpdatesAnnual alloc] initWithVersion:1]]];

        [paid addObjectsFromArray:self.liveUpdates.subscriptions];
        self.inAppsPaid = paid;

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
    
    return [self.liveUpdates getSubscriptionByIdentifier:productIdentifier];
}

- (BOOL) updateProduct:(SKProduct *)skProduct
{
    OASubscription *s = [self.liveUpdates getSubscriptionByIdentifier:skProduct.productIdentifier];
    if (s)
    {
        s.skProduct = skProduct;
        return YES;
    }
    for (OAProduct *p in self.inApps)
        if ([p.productIdentifier isEqualToString:skProduct.productIdentifier])
        {
            p.skProduct = skProduct;
            return YES;
        }

    return NO;
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
    if (!product)
        product = [self.liveUpdates upgradeSubscription:productIdentifier];

    if (product)
    {
        [product setPurchased];
        [self buildFunctionalAddonsArray];
        return YES;
    }
    return NO;
}

- (BOOL) setExpired:(NSString * _Nonnull)productIdentifier
{
    OAProduct *product = [self getProduct:productIdentifier];
    if (!product)
        product = [self.liveUpdates upgradeSubscription:productIdentifier];
    
    if (product)
    {
        [product setExpired];
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
