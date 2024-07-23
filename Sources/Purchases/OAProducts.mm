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
#import "OAIAPHelper.h"
#import "OAChoosePlanHelper.h"
#import "OALinks.h"
#import "OAObservable.h"
#import "OAAppSettings.h"

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

@interface OAProductSubscriptionPeriod()

@property (nonatomic) NSUInteger numberOfUnits;
@property (nonatomic) OAProductPeriodUnit unit;

@end

@implementation OAProductSubscriptionPeriod

- (instancetype) initTest
{
    self = [super init];
    if (self)
    {
        self.numberOfUnits = 1;
        self.unit = OAProductPeriodUnitYear;
    }
    return self;
}

- (instancetype) initWithSkSubscriptionPeriod:(SKProductSubscriptionPeriod * _Nonnull)skSubscriptionPeriod API_AVAILABLE(ios(11.2))
{
    self = [super init];
    if (self)
    {
        self.numberOfUnits = skSubscriptionPeriod.numberOfUnits;
        switch (skSubscriptionPeriod.unit)
        {
            case SKProductPeriodUnitDay:
                self.unit = OAProductPeriodUnitDay;
                break;
            case SKProductPeriodUnitWeek:
                self.unit = OAProductPeriodUnitWeek;
                break;
            case SKProductPeriodUnitMonth:
                self.unit = OAProductPeriodUnitMonth;
                break;
            case SKProductPeriodUnitYear:
                self.unit = OAProductPeriodUnitYear;
                break;
                
            default:
                break;
        }
    }
    return self;
}

@end

@interface OAProductDiscount()

@property (nonatomic, copy) NSDecimalNumber *price;
@property (nonatomic, copy) NSLocale *priceLocale;
@property (nonatomic, copy, nullable) NSString *identifier;
@property (nonatomic) OAProductSubscriptionPeriod *subscriptionPeriod;
@property (nonatomic) NSUInteger numberOfPeriods;
@property (nonatomic) OAProductDiscountPaymentMode paymentMode;
@property (nonatomic) OAProductDiscountType type;
@property (nonatomic, copy) NSDecimalNumber *originalPrice;
@property (nonatomic, copy) NSLocale *originalPriceLocale;
@property (nonatomic, nullable) OAProductSubscriptionPeriod *originalSubscriptionPeriod;

@end

@implementation OAProductDiscount

- (instancetype) initTest
{
    self = [super init];
    if (self)
    {
        self.price = [NSDecimalNumber numberWithDouble:2.];
        self.priceLocale = NSLocale.currentLocale;
        self.subscriptionPeriod = [[OAProductSubscriptionPeriod alloc] initTest];
        self.numberOfPeriods = 1;
        self.paymentMode = OAProductDiscountPaymentModePayUpFront;
        self.originalPrice = [NSDecimalNumber numberWithDouble:20.];
        self.originalSubscriptionPeriod = self.subscriptionPeriod;
        self.type = OAProductDiscountTypeSubscription;
    }
    return self;
}

- (instancetype) initWithSkDiscount:(SKProductDiscount * _Nonnull)skDiscount skProduct:(SKProduct *)skProduct API_AVAILABLE(ios(11.2))
{
    self = [super init];
    if (self)
    {
        self.price = skDiscount.price;
        self.priceLocale = skDiscount.priceLocale;
        self.subscriptionPeriod = [[OAProductSubscriptionPeriod alloc] initWithSkSubscriptionPeriod:skDiscount.subscriptionPeriod];
        self.numberOfPeriods = skDiscount.numberOfPeriods;
        switch (skDiscount.paymentMode)
        {
            case SKProductDiscountPaymentModePayAsYouGo:
                self.paymentMode = OAProductDiscountPaymentModePayAsYouGo;
                break;
            case SKProductDiscountPaymentModePayUpFront:
                self.paymentMode = OAProductDiscountPaymentModePayUpFront;
                break;
            case SKProductDiscountPaymentModeFreeTrial:
                self.paymentMode = OAProductDiscountPaymentModeFreeTrial;
                break;
                
            default:
                self.paymentMode = OAProductDiscountPaymentModeUnknown;
                break;
        }
        self.originalPrice = skProduct.price;
        self.originalPriceLocale = skProduct.priceLocale;
        if (skProduct.subscriptionPeriod)
            self.originalSubscriptionPeriod = [[OAProductSubscriptionPeriod alloc] initWithSkSubscriptionPeriod:skProduct.subscriptionPeriod];
        
        self.identifier = skDiscount.identifier;
        switch (skDiscount.type)
        {
            case SKProductDiscountTypeIntroductory:
                self.type = OAProductDiscountTypeIntroductory;
                break;
            case SKProductDiscountTypeSubscription:
                self.type = OAProductDiscountTypeSubscription;
                break;
                
            default:
                self.type = OAProductDiscountTypeUnknown;
                break;
        }
    }
    return self;
}

- (double) getMonthlyPrice:(BOOL)original
{
    double monthlyPrice;
    double price = original ? [self.originalPrice doubleValue] : [self.price doubleValue];
    OAProductPeriodUnit unit = original && self.originalSubscriptionPeriod ? self.originalSubscriptionPeriod.unit : self.subscriptionPeriod.unit;
    NSUInteger numberOfUnits = original && self.originalSubscriptionPeriod ? self.originalSubscriptionPeriod.numberOfUnits : self.subscriptionPeriod.numberOfUnits;
    switch (unit)
    {
        case OAProductPeriodUnitDay:
            monthlyPrice = price * (30.0 / numberOfUnits);
            break;
        case OAProductPeriodUnitWeek:
            monthlyPrice = price * (4.0 / numberOfUnits);
            break;
        case OAProductPeriodUnitMonth:
            monthlyPrice = price * (1.0 / numberOfUnits);
            break;
        case OAProductPeriodUnitYear:
            monthlyPrice = price / (12.0 * numberOfUnits);
            break;
        default:
            monthlyPrice = price;
            break;
    }
    return monthlyPrice;
}

- (double) getMonthlyPrice
{
    return [self getMonthlyPrice:NO];
}

- (double) getOriginalMonthlyPrice
{
    return [self getMonthlyPrice:YES];
}

- (int) discountPercent
{
    double discount = 0.0;
    switch (self.paymentMode)
    {
        case OAProductDiscountPaymentModePayAsYouGo:
        case OAProductDiscountPaymentModePayUpFront:
            discount = 1.0 - [self getMonthlyPrice] / [self getOriginalMonthlyPrice];
            break;
        case OAProductDiscountPaymentModeFreeTrial:
            discount = 1.0;
            break;
        default:
            discount = 0.0;
            break;
    }
    return (int) (discount * 100.0);
}

- (NSNumberFormatter *) getNumberFormatter:(NSLocale *)locale
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];

    if (!locale)
        locale = [NSLocale localeWithLocaleIdentifier:@"en_BE"];
    
    [numberFormatter setLocale:locale];
    return numberFormatter;
}

- (NSUInteger) getTotalPeriods
{
    return self.numberOfPeriods * self.subscriptionPeriod.numberOfUnits;
}

- (NSString *) getTotalUnitsString:(BOOL)original
{
    NSString *unitStr = @"";
    OAProductPeriodUnit unit = original && self.originalSubscriptionPeriod ? self.originalSubscriptionPeriod.unit : self.subscriptionPeriod.unit;
    NSUInteger totalPeriods = original && self.originalSubscriptionPeriod ? self.originalSubscriptionPeriod.numberOfUnits : [self getTotalPeriods];
    switch (unit)
    {
        case OAProductPeriodUnitDay:
            if (totalPeriods == 1)
                unitStr = OALocalizedString(@"day");
            else if (totalPeriods < 5)
                unitStr = OALocalizedString(@"days_2_4");
            else
                unitStr = OALocalizedString(@"days_5");
            
            break;
            
        case OAProductPeriodUnitWeek:
            if (totalPeriods == 1)
                unitStr = OALocalizedString(@"week");
            else if (totalPeriods < 5)
                unitStr = OALocalizedString(@"weeks_2_4");
            else
                unitStr = OALocalizedString(@"weeks_5");
            
            break;
            
        case OAProductPeriodUnitMonth:
            if (totalPeriods == 1)
                unitStr = OALocalizedString(@"month");
            else if (totalPeriods < 5)
                unitStr = OALocalizedString(@"months_2_4");
            else
                unitStr = OALocalizedString(@"months_5");
            
            break;
            
        case OAProductPeriodUnitYear:
            unitStr = OALocalizedString(@"year");
            
            break;
            
        default:
            break;
    }
    return unitStr;
}

- (NSString *) getUnitString
{
    NSString *unitStr = @"";
    OAProductPeriodUnit unit = self.subscriptionPeriod.unit;
    switch (unit)
    {
        case OAProductPeriodUnitDay:
            unitStr = OALocalizedString(@"day");
            break;
        case OAProductPeriodUnitWeek:
            unitStr = OALocalizedString(@"week");
            break;
        case OAProductPeriodUnitMonth:
            unitStr = OALocalizedString(@"month");
            break;
        case OAProductPeriodUnitYear:
            unitStr = OALocalizedString(@"year");
            break;
        default:
            break;
    }
    return unitStr;
}

- (NSString *) getDescriptionTitle
{
    switch (self.paymentMode)
    {
        case OAProductDiscountPaymentModePayAsYouGo:
        case OAProductDiscountPaymentModePayUpFront:
            return [NSString stringWithFormat:@"-%d%%", (int) self.discountPercent];
        default:
            return @"";
    }
}

- (NSAttributedString *) getFormattedDescription
{
    NSUInteger totalPeriods = [self getTotalPeriods];
    NSString *singleUnitStr = [[self getUnitString] lowerCase];
    NSString *unitStr = [[self getTotalUnitsString:NO] lowerCase];
    NSUInteger numberOfUnits = self.subscriptionPeriod.numberOfUnits;
    NSUInteger originalNumberOfUnits = self.originalSubscriptionPeriod ? self.originalSubscriptionPeriod.numberOfUnits : 1;
    NSString *originalUnitsStr = [[self getTotalUnitsString:YES] lowerCase];
    NSString *originalPriceStr = [[self getNumberFormatter:self.originalPriceLocale] stringFromNumber:self.originalPrice];
    NSString *priceStr = [[self getNumberFormatter:self.priceLocale ? self.priceLocale : self.originalPriceLocale] stringFromNumber:self.price];
    
    NSString *pricePeriod;
    NSString *originalPricePeriod;
    if ([self isRTL])
    {
        pricePeriod = [NSString stringWithFormat:@"%@ / %@", singleUnitStr, priceStr];
        originalPricePeriod = [NSString stringWithFormat:@"%@ / %@", originalUnitsStr, originalPriceStr];
        if (numberOfUnits > 1)
            pricePeriod = [NSString stringWithFormat:@"%@ %d / %@", unitStr, (int) numberOfUnits, priceStr];
        if (originalNumberOfUnits == 3 && self.originalSubscriptionPeriod && self.originalSubscriptionPeriod.unit == OAProductPeriodUnitMonth)
            originalPricePeriod = [NSString stringWithFormat:@"%@ / %@", [OALocalizedString(@"months_3") lowerCase], originalPriceStr];
        else if (originalNumberOfUnits > 1)
            originalPricePeriod = [NSString stringWithFormat:@"%@ %d / %@", originalUnitsStr, (int) originalNumberOfUnits, originalPriceStr];
    }
    else
    {
        pricePeriod = [NSString stringWithFormat:@"%@ / %@", priceStr, singleUnitStr];
        originalPricePeriod = [NSString stringWithFormat:@"%@ / %@", originalPriceStr, originalUnitsStr];
        if (numberOfUnits > 1)
            pricePeriod = [NSString stringWithFormat:@"%@ / %d %@", priceStr, (int) numberOfUnits, unitStr];
        if (originalNumberOfUnits == 3 && self.originalSubscriptionPeriod && self.originalSubscriptionPeriod.unit == OAProductPeriodUnitMonth)
            originalPricePeriod = [NSString stringWithFormat:@"%@ / %@", originalPriceStr, [OALocalizedString(@"months_3") lowerCase]];
        else if (originalNumberOfUnits > 1)
            originalPricePeriod = [NSString stringWithFormat:@"%@ / %d %@", originalPriceStr, (int) originalNumberOfUnits, originalUnitsStr];
    }
    NSString *periodPriceStr = nil;
    if (self.paymentMode == OAProductDiscountPaymentModePayAsYouGo)
        periodPriceStr = self.numberOfPeriods == 1 ? priceStr : pricePeriod;
    else if (self.paymentMode == OAProductDiscountPaymentModePayUpFront)
        periodPriceStr = priceStr;
    else if (self.paymentMode == OAProductDiscountPaymentModeFreeTrial)
        periodPriceStr = OALocalizedString(@"price_free");
    
    if (!periodPriceStr)
        return [[NSAttributedString alloc] initWithString:@""];;
    BOOL isPlural = originalNumberOfUnits > 1 || self.numberOfPeriods > 1;
    NSString *mainPart = [NSString stringWithFormat:OALocalizedString(isPlural ? @"get_discount_first_few_parts" : @"get_discount_first_part"), periodPriceStr, [self getDisountPeriodString:unitStr totalPeriods:totalPeriods]];
    NSString *thenPart = [NSString stringWithFormat:OALocalizedString(@"get_discount_second_part"), originalPricePeriod];
    NSAttributedString *mainStrAttributed = [[NSAttributedString alloc] initWithString:mainPart attributes:@{ NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline] }];
    NSAttributedString *secondStrAttributed = [[NSAttributedString alloc] initWithString:thenPart attributes:@{ NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody] }];
    NSMutableAttributedString *res = [[NSMutableAttributedString alloc] initWithAttributedString:mainStrAttributed];
    [res appendAttributedString:[[NSAttributedString alloc] initWithString:self.paymentMode == OAProductDiscountPaymentModeFreeTrial ? @", " : @"\n"]];
    [res appendAttributedString:secondStrAttributed];
    return res;
}

- (NSString *) getDisountPeriodString:(NSString *) unitStr totalPeriods:(NSUInteger)totalPeriods
{
    if (totalPeriods == 1)
        return unitStr;
    if ([self isRTL])
        return [NSString stringWithFormat:@"%@ %lu", unitStr, totalPeriods];
    else
        return [NSString stringWithFormat:@"%lu %@", totalPeriods, unitStr];
}

- (NSString *) getDescription
{
    // not implemented yet
    /* Pay As You Go

     "get_discount_descr" = "Payment of %@ will be charged to your Apple ID account each %@ for %d %@. Subscription automatically renews for %@ per %@ after %d %@ unless it is cancelled at least 24 hours before the and of %d-%@ period.";

     */
    /* Pay Up Front
     
     "get_const_discount_descr" = "Payment of %@ will be charged to your Apple ID account once for %d %@. Subscription automatically renews for %@ per %@ after %d %@ unless it is cancelled at least 24 hours before the and of %d-%@ period.";
     
     */
    
    /* Free
     
     "get_free_discount_descr" = "After the %d %@ free trial this subscription automatically renews for %@ per %@ unless it is canceled at least 24 hours before the end of the trial period.";
     
     */
    return @"";
}

- (BOOL) isRTL
{
    return UIApplication.sharedApplication.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}

@end

@interface OAPaymentDiscount()

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *productIdentifier;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *keyIdentifier;
@property (nonatomic, copy) NSUUID *nonce;
@property (nonatomic, copy) NSString *signature;
@property (nonatomic, copy) NSNumber *timestamp;

@end

@implementation OAPaymentDiscount

- (instancetype) initWithIdentifier:(NSString *)identifier
                  productIdentifier:(NSString *)productIdentifier
                           username:(NSString *)username
                      keyIdentifier:(NSString *)keyIdentifier
                              nonce:(NSUUID *)nonce
                          signature:(NSString *)signature
                          timestamp:(NSNumber *)timestamp
{
    self = [super init];
    if (self)
    {
        self.identifier = identifier;
        self.productIdentifier = productIdentifier;
        self.username = username;
        self.keyIdentifier = keyIdentifier;
        self.nonce = nonce;
        self.signature = signature;
        self.timestamp = timestamp;
    }
    return self;
}

@end

@interface OAProduct()

@property (nonatomic, copy) NSString *productIdentifier;
@property (nonatomic, copy) NSString *localizedDescription;
@property (nonatomic, copy) NSString *localizedDescriptionExt;
@property (nonatomic, copy) NSString *localizedTitle;
@property (nonatomic, copy) NSDecimalNumber *price;
@property (nonatomic, copy) NSLocale *priceLocale;
@property (nonatomic) EOAPurchaseState purchaseState; // PSTATE_UNKNOWN
@property (nonatomic) BOOL free;
@property (nonatomic) BOOL disabled;

@property(nonatomic, nullable) OAProductSubscriptionPeriod *subscriptionPeriod;
@property(nonatomic, nullable) OAProductDiscount *introductoryPrice;
@property(nonatomic, copy, nullable) NSString *subscriptionGroupIdentifier;
@property(nonatomic) NSArray<OAProductDiscount *> *discounts;

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
    NSString *postfix = [[_productIdentifier componentsSeparatedByString:@"."] lastObject];
    NSString *locTitleId = [@"product_title_" stringByAppendingString:postfix];
    NSString *locDescriptionId = [@"product_desc_" stringByAppendingString:postfix];
    self.localizedTitle = OALocalizedString(locTitleId);
    self.localizedDescription = OALocalizedString(locDescriptionId);
    self.price = skProduct.price;
    self.priceLocale = skProduct.priceLocale;
    
    if (skProduct.subscriptionPeriod)
        self.subscriptionPeriod = [[OAProductSubscriptionPeriod alloc] initWithSkSubscriptionPeriod:skProduct.subscriptionPeriod];
    if (skProduct.introductoryPrice)
        self.introductoryPrice = [[OAProductDiscount alloc] initWithSkDiscount:skProduct.introductoryPrice skProduct:skProduct];
    if (skProduct.subscriptionGroupIdentifier)
        self.subscriptionGroupIdentifier = skProduct.subscriptionGroupIdentifier;
    NSMutableArray<OAProductDiscount *> *discounts = [NSMutableArray array];
    for (SKProductDiscount *skDiscount in skProduct.discounts)
        [discounts addObject:[[OAProductDiscount alloc] initWithSkDiscount:skDiscount skProduct:skProduct]];
    self.discounts = [NSArray arrayWithArray:discounts];

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
    return [[NSUserDefaults standardUserDefaults] objectForKey:[self getDisabledId]] ? [[NSUserDefaults standardUserDefaults] boolForKey:[self getDisabledId]] : YES;
}

- (void) setDisabled:(BOOL)disabled
{
    [[NSUserDefaults standardUserDefaults] setBool:disabled forKey:[self getDisabledId]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *) getCancelledTimeId
{
    return [NSString stringWithFormat:@"%@_cancell_time", self.productIdentifier];
}

- (NSTimeInterval) purchaseCancelledTime
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:[self getCancelledTimeId]];
}

- (void)setPurchaseCancelledTime:(NSTimeInterval)purchaseCancelledTime
{
    [[NSUserDefaults standardUserDefaults] setDouble:purchaseCancelledTime forKey:[self getCancelledTimeId]];
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

- (NSAttributedString *) formattedPriceAttributed
{
    NSString *price = self.formattedPrice;
    return price ? [[NSAttributedString alloc] initWithString:price] : nil;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return nil;
}

- (BOOL) isPurchased
{
    BOOL purchased = self.purchaseState == PSTATE_PURCHASED || [self isAlreadyPurchased];
    if (!purchased)
    {
        if ([self isKindOfClass:OASubscription.class])
        {
            return NO;
        }
        else if ([OAIAPHelper isFullVersion:self])
        {
            purchased = [OAIAPHelper isFullVersionPurchased];
        }
        else
        {
            if ([self.productIdentifier isEqualToString:kInAppId_Addon_Nautical])
                purchased = [OAIAPHelper isDepthContoursPurchased];
            else if ([self.productIdentifier isEqualToString:kInAppId_Addon_Srtm])
                purchased = [OAIAPHelper isContourLinesPurchased];
            else if ([self.productIdentifier isEqualToString:kInAppId_Addon_Wiki])
                purchased = [OAIAPHelper isWikipediaPurchased];
            else if ([self.productIdentifier isEqualToString:kInAppId_Addon_External_Sensors])
                purchased = [OAIAPHelper isSensorPurchased];

            if (!purchased && self.feature)
            {
                if ([OAIAPHelper isSubscribedToLiveUpdates])
                {
                    NSMutableArray<OAFeature *> *allFeatures = [NSMutableArray arrayWithArray:OAFeature.MAPS_PLUS_FEATURES];
                    [allFeatures addObject:OAFeature.HOURLY_MAP_UPDATES];
                    purchased = [allFeatures containsObject:self.feature];
                }
                if (!purchased && [OAIAPHelper isOsmAndProAvailable])
                    purchased = [self.feature isAvailableInOsmAndPro];
                if (!purchased && ([OAIAPHelper isSubscribedToMaps] || [OAIAPHelper isFullVersionPurchased]))
                    purchased = [self.feature isAvailableInMapsPlus];
            }
        }
    }
    return purchased;
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

- (NSString *) getExpirationDateId
{
    return [self.productIdentifier stringByAppendingString:@"_expiration_date"];
}

- (NSDate *) expirationDate
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:[self getExpirationDateId]];
}

- (void) setExpirationDate:(NSDate * _Nullable)expirationDate
{
    NSString *expId = [self getExpirationDateId];
    if (expirationDate)
        [[NSUserDefaults standardUserDefaults] setObject:expirationDate forKey:expId];
    else
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:expId];

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
    return nil;
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

- (NSString *) getOrderId
{
    NSData *data = [OAAppSettings.sharedManager.purchasedIdentifiers.get dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (!error)
    {
        return result[self.productIdentifier];
    }
    return nil;
}

- (NSAttributedString *) getDescription:(CGFloat)fontSize
{
    if (self == [OAIAPHelper sharedInstance].mapsAnnually)
        return nil;
    OASubscription *monthlyPro = [OAIAPHelper sharedInstance].proMonthly;
    double regularMonthlyPrice = monthlyPro.price.doubleValue;
    double monthlyPrice = self.monthlyPrice ? self.monthlyPrice.doubleValue : 0.0;
    NSString *discountStr;
    BOOL showDiscount = NO;
    if (regularMonthlyPrice > 0 && monthlyPrice > 0 && monthlyPrice < regularMonthlyPrice)
    {
        int discount = (int) ((1 - monthlyPrice / regularMonthlyPrice) * 100.0);
        discountStr = [NSString stringWithFormat:@"-%d%%", discount];
        if (discount > 0)
        {
            discountStr = [NSString stringWithFormat:OALocalizedString(@"osm_live_payment_discount_descr"), discountStr];
            showDiscount = YES;
        }
    }
    NSAttributedString *resStr = [[NSAttributedString alloc] initWithString:@""];
    if (showDiscount && discountStr.length > 0)
    {
        resStr = [[NSAttributedString alloc] initWithString:discountStr attributes:@{ NSFontAttributeName : [UIFont scaledSystemFontOfSize:fontSize weight:UIFontWeightSemibold]}];
    }
    return resStr;
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

- (NSString *) formattedPrice
{
    NSDecimalNumber *price;
    if (self.price)
        price = self.price;
    else
        price = [self getDefaultPrice];

    if (price)
    {
        NSNumberFormatter *numberFormatter = [self getNumberFormatter:self.priceLocale];
        return [numberFormatter stringFromNumber:price];
    }
    return nil;
}

- (NSAttributedString *) formattedPriceAttributed
{
    NSString *formattedPrice = [self formattedPrice];
    if (formattedPrice && formattedPrice.length > 0)
    {
        NSString *price = [super formattedPrice];
        NSMutableAttributedString *priceAttributed =
                [[NSMutableAttributedString alloc] initWithString:formattedPrice
                                                       attributes:@{ NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] }];
        [priceAttributed addAttribute:NSFontAttributeName
                                value:[UIFont scaledSystemFontOfSize:15 weight:UIFontWeightSemibold]
                                range:NSMakeRange(0, price.length)];
        return priceAttributed;
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

- (NSArray<OASubscription *> *) getPurchasedSubscriptions
{
    NSMutableArray<OASubscription *> *res = [NSMutableArray array];
    for (OASubscription *s in [self getAllSubscriptions])
        if ([s isPurchased])
            [res addObject:s];

    return res;
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

- (OAFeature *) feature
{
    return OAFeature.HOURLY_MAP_UPDATES;
}

- (NSString *) productIconName
{
    return @"ic_action_osmand_logo_banner";
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"osmand_live");
}

- (void) setPrice:(NSDecimalNumber *)price
{
    [super setPrice:price];
    self.monthlyPrice = price;
}

- (NSString *) formattedPrice
{
    NSString *price = [super formattedPrice];
    
    if (price && price.length > 0)
        return [NSString stringWithFormat:@"%@ / %@", price, [OALocalizedString(@"month") lowerCase]];

    return nil;
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
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"monthly_subscription")];
}

- (NSAttributedString *) getDescription:(CGFloat)fontSize
{
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] init];
    [text addAttribute:NSFontAttributeName value:[UIFont scaledSystemFontOfSize:fontSize] range:NSMakeRange(0, text.length)];
    NSMutableAttributedString *boldStr = [[NSMutableAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_contribute_descr")];
    UIFont *boldFont = [UIFont scaledSystemFontOfSize:fontSize];
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

- (OAFeature *) feature
{
    return OAFeature.HOURLY_MAP_UPDATES;
}

- (NSString *) productIconName
{
    return @"ic_action_osmand_logo_banner";
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"osmand_live");
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

- (NSString *) formattedPrice
{
    NSString *price = [super formattedPrice];
    
    if (price && price.length > 0)
        return [NSString stringWithFormat:@"%@ / %@", price, [OALocalizedString(@"months_3") lowerCase]];
    
    return nil;
}

- (NSAttributedString *) getTitle:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"quarterly_subscription")];
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

- (OAFeature *) feature
{
    return OAFeature.HOURLY_MAP_UPDATES;
}

- (NSString *) productIconName
{
    return @"ic_action_osmand_logo_banner";
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"osmand_live");
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

- (NSString *) formattedPrice
{
    NSString *price = [super formattedPrice];
    
    if (price && price.length > 0)
        return [NSString stringWithFormat:@"%@ / %@", price, [OALocalizedString(@"year") lowerCase]];
    
    return nil;
}

- (NSAttributedString *) getTitle:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"annual_subscription")];
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

@implementation OAProSubscriptionMonthly

- (instancetype) initWithVersion:(int)version
{
    self = [self initWithIdentifierNoVersion:kSubscriptionId_Pro_Subscription_Monthly version:version];
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

- (OAFeature *) feature
{
    return OAFeature.HOURLY_MAP_UPDATES;
}

- (NSString *) productIconName
{
    return @"ic_custom_osmand_pro_logo_colored";
}

- (NSString *)localizedTitle
{
    return OALocalizedString(@"product_title_pro");
}

- (NSString *)localizedDescription
{
    return OALocalizedString(@"osmand_pro_tagline");
}

- (void) setPrice:(NSDecimalNumber *)price
{
    [super setPrice:price];
    self.monthlyPrice = price;
}

- (NSString *) formattedPrice
{
    NSString *price = [super formattedPrice];

    if (price && price.length > 0)
        return [NSString stringWithFormat:@"%@ / %@", price, [OALocalizedString(@"month") lowerCase]];

    return nil;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kSubscription_Pro_Monthly_Price];
}

- (NSDecimalNumber *) getDefaultMonthlyPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kSubscription_Pro_Monthly_Price];
}

- (NSAttributedString *) getTitle:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"monthly_subscription")];
}

- (NSAttributedString *) getRenewDescription:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_renews_monthly")];
}

- (OASubscription *) newInstance:(NSString *)productIdentifier
{
    return [productIdentifier hasPrefix:self.identifierNoVersion] ? [[OAProSubscriptionMonthly alloc] initWithIdentifier:productIdentifier] : nil;
}

@end

@implementation OAProSubscriptionAnnual

- (instancetype) initWithVersion:(int)version
{
    self = [super initWithIdentifierNoVersion:kSubscriptionId_Pro_Subscription_Annual version:version];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.HOURLY_MAP_UPDATES;
}

- (NSString *) productIconName
{
    return @"ic_custom_osmand_pro_logo_colored";
}

- (NSString *)localizedTitle
{
    return OALocalizedString(@"product_title_pro");
}

- (NSString *)localizedDescription
{
    return OALocalizedString(@"osmand_pro_tagline");
}

- (void) setPrice:(NSDecimalNumber *)price
{
    [super setPrice:price];
    self.monthlyPrice = [[NSDecimalNumber alloc] initWithDouble:price.doubleValue / 12.0];
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kSubscription_Pro_Annual_Price];
}

- (NSDecimalNumber *) getDefaultMonthlyPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kSubscription_Pro_Monthly_Price];
}

- (NSString *) formattedPrice
{
    NSString *price = [super formattedPrice];

    if (price && price.length > 0)
        return [NSString stringWithFormat:@"%@ / %@", price, [OALocalizedString(@"year") lowerCase]];

    return nil;
}

- (NSAttributedString *) getTitle:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"annual_subscription")];
}

- (NSAttributedString *) getRenewDescription:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_renews_annually")];
}

- (OASubscription *) newInstance:(NSString *)productIdentifier
{
    return [productIdentifier hasPrefix:self.identifierNoVersion] ? [[OAProSubscriptionAnnual alloc] initWithIdentifier:productIdentifier] : nil;
}

@end

@implementation OAMapsSubscriptionAnnual

- (instancetype) initWithVersion:(int)version
{
    self = [super initWithIdentifierNoVersion:kSubscriptionId_Maps_Subscription_Annual version:version];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.MONTHLY_MAP_UPDATES;
}

- (NSString *) productIconName
{
    return @"ic_custom_osmand_maps_plus";
}

- (NSString *)localizedTitle
{
    return OALocalizedString(@"product_title_plus");
}

- (NSString *)localizedDescription
{
    return OALocalizedString(@"osmand_maps_plus_tagline");
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kSubscription_Maps_Annual_Price];
}

- (NSString *) formattedPrice
{
    NSString *price = [super formattedPrice];

    if (price && price.length > 0)
        return [NSString stringWithFormat:@"%@ / %@", price, [OALocalizedString(@"year") lowerCase]];

    return nil;
}

- (NSAttributedString *) getTitle:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"annual_subscription")];
}

- (NSAttributedString *) getRenewDescription:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"osm_live_payment_renews_annually")];
}

- (OASubscription *) newInstance:(NSString *)productIdentifier
{
    return [productIdentifier hasPrefix:self.identifierNoVersion] ? [[OAMapsSubscriptionAnnual alloc] initWithIdentifier:productIdentifier] : nil;
}

@end

@implementation OAMapsFullProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Maps_Full];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.MONTHLY_MAP_UPDATES;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Maps_Full_Price];
}

- (NSString *) productIconName
{
    return @"ic_custom_osmand_maps_plus";
}

- (NSString *)localizedTitle
{
    return OALocalizedString(@"product_title_plus");
}

- (NSString *)localizedDescription
{
    return OALocalizedString(@"osmand_maps_plus_tagline");
}

- (NSString *) formattedPrice
{
    NSString *price = [super formattedPrice];

    if (price && price.length > 0)
        return price;

    return nil;
}

- (NSAttributedString *) getTitle:(CGFloat)fontSize
{
    return [[NSAttributedString alloc] initWithString:OALocalizedString(@"in_app_purchase_desc")];
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

- (NSString *) localizedTitle
{
    return OALocalizedString(@"plugin_ski_name");
}

- (NSString *) localizedDescription
{
    return OALocalizedString(@"product_desc_skimap");
}

- (NSString *) localizedDescriptionExt
{
    return OALocalizedString(@"plugin_ski_descr");
}

@end

@implementation OANauticalProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_Nautical];
    if (self)
    {
        self.free = YES;
        [self commonInit];
    }
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.NAUTICAL;
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

- (NSString *) localizedTitle
{
    return OALocalizedString(@"plugin_nautical_name");
}

- (NSString *) localizedDescription
{
    return OALocalizedString(@"product_desc_nautical");
}

- (NSString *) localizedDescriptionExt
{
    return [NSString stringWithFormat:NSLocalizedString(@"plugin_nautical_descr", nil), k_docs_plugin_nautical];
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

- (NSString *) localizedTitle
{
    return OALocalizedString(@"record_plugin_name");
}

- (NSString *) localizedDescription
{
    return OALocalizedString(@"product_desc_track_recording");
}

- (NSString *) localizedDescriptionExt
{
    return [NSString stringWithFormat:NSLocalizedString(@"record_plugin_description", nil), k_docs_plugin_trip_recording];
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

- (NSString *) localizedTitle
{
    return OALocalizedString(@"osmand_parking_plugin_name");
}

- (NSString *) localizedDescription
{
    return OALocalizedString(@"product_desc_parking");
}

- (NSString *) localizedDescriptionExt
{
    return OALocalizedString(@"osmand_parking_plugin_description");
}

@end

@implementation OAWikiProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_Wiki];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.WIKIPEDIA;
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

- (NSString *) localizedTitle
{
    return OALocalizedString(@"download_wikipedia_maps");
}

- (NSString *) localizedDescription
{
    return OALocalizedString(@"product_desc_wiki");
}

- (NSString *) localizedDescriptionExt
{
    return OALocalizedString(@"purchases_feature_desc_wikipedia");
}

@end

@implementation OASrtmProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_Srtm];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.TERRAIN;
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

- (NSString *) localizedTitle
{
    return OALocalizedString(@"srtm_plugin_name");
}

- (NSString *) localizedDescription
{
    return OALocalizedString(@"product_desc_srtm");
}

- (NSString *) localizedDescriptionExt
{
    return [NSString stringWithFormat:NSLocalizedString(@"srtm_plugin_description", nil), k_docs_plugin_srtm];
//    return OALocalizedString(@"srtm_plugin_description");
}

@end

@implementation OAOsmEditingProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_OsmEditing];
    if (self)
    {
        self.free = YES;
        [self commonInit];
    }
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Addon_OsmEditing_Default_Price];
}

- (NSString *) productIconName
{
    return @"ic_plugin_osm_edit";
}

- (NSString *) productScreenshotName
{
    return @"img_plugin_osm_edits.jpg";
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"osm_editing_plugin_name");
}

- (NSString *) localizedDescription
{
    return OALocalizedString(@"product_desc_osm_editing");
}

- (NSString *) localizedDescriptionExt
{
    return [NSString stringWithFormat:NSLocalizedString(@"osm_editing_plugin_description", nil), k_docs_plugin_osm];
}

@end

@implementation OAMapillaryProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_Mapillary];
    if (self)
    {
        self.free = YES;
        [self commonInit];
    }
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Addon_Mapillary_Default_Price];
}

- (NSString *) productIconName
{
    return @"ic_custom_mapillary_symbol";
}

- (NSString *) productScreenshotName
{
    return @"img_plugin_mapillary.jpg";
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"mapillary");
}

- (NSString *) localizedDescription
{
    return OALocalizedString(@"product_desc_mapillary");
}

- (NSString *) localizedDescriptionExt
{
    return OALocalizedString(@"plugin_mapillary_descr");
}

@end


@implementation OAWeatherProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_Weather];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.WEATHER;
}

- (NSString *) productIconName
{
    return @"ic_custom_umbrella";
}

- (NSString *) productScreenshotName
{
    return @"img_plugin_weather.jpg";
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"shared_string_weather");
}

- (NSString *) localizedDescription
{
    return OALocalizedString(@"product_desc_weather");
}

- (NSString *) localizedDescriptionExt
{
    return [NSString stringWithFormat:NSLocalizedString(@"weather_plugin_description", nil), k_weather_global_forecast_system];
}

@end

@implementation OAExternalSensorsProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_External_Sensors];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.SENSORS;
}

- (NSString *) productScreenshotName
{
    return @"img_help_sensors_day";
}

- (NSString *) productIconName
{
    return @"ic_custom_sensor";
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"external_sensors_plugin_name");
}

- (NSString *) localizedDescription
{
    return OALocalizedString(@"external_sensors_plugin_description");
}

- (NSString *) localizedDescriptionExt
{
    return OALocalizedString(@"purchases_feature_desc_external_sensors");
}

@end


@implementation OACarPlayProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_CarPlay];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.CARPLAY;
}

- (NSString *) productIconName
{
    return @"ic_custom_carplay_colored";
}

@end

@implementation OAOsmandDevelopmentProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Addon_OsmandDevelopment];
    if (self)
    {
        self.free = YES;
        [self commonInit];
    }
    return self;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Addon_OsmandDevelopment_Default_Price];
}

- (NSString *) productScreenshotName
{
    return @"img_plugin_osmand_development.png";
}

- (NSString *) productIconName
{
    return @"ic_custom_laptop";
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"debugging_and_development");
}

- (NSString *) localizedDescription
{
    return OALocalizedString(@"product_desc_development");
}

- (NSString *) localizedDescriptionExt
{
    return OALocalizedString(@"osmand_development_plugin_description");
}

@end

@implementation OAAllWorldProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_All_World];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.UNLIMITED_MAP_DOWNLOADS;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_All_World_Default_Price];
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"worldwide_maps");
}

@end

@implementation OARussiaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_Russia];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.UNLIMITED_MAP_DOWNLOADS;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_Russia_Default_Price];
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"index_name_russia");
}

@end

@implementation OAAntarcticaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_Antarctica];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.UNLIMITED_MAP_DOWNLOADS;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_Antarctica_Default_Price];
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"index_name_antarctica");
}

@end

@implementation OAAfricaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_Africa];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.UNLIMITED_MAP_DOWNLOADS;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_Africa_Default_Price];
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"index_name_africa");
}

@end

@implementation OAAsiaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_Asia];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.UNLIMITED_MAP_DOWNLOADS;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_Asia_Default_Price];
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"index_name_asia");
}

@end

@implementation OAAustraliaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_Australia];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.UNLIMITED_MAP_DOWNLOADS;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_Australia_Default_Price];
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"index_name_oceania");
}

@end

@implementation OAEuropeProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_Europe];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.UNLIMITED_MAP_DOWNLOADS;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_Europe_Default_Price];
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"index_name_europe");
}

@end

@implementation OACentralAmericaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_Central_America];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.UNLIMITED_MAP_DOWNLOADS;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_Central_America_Default_Price];
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"index_name_central_america");
}

@end

@implementation OANorthAmericaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_North_America];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.UNLIMITED_MAP_DOWNLOADS;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_North_America_Default_Price];
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"index_name_north_america");
}

@end

@implementation OASouthAmericaProduct

- (instancetype) init
{
    self = [super initWithIdentifier:kInAppId_Region_South_America];
    return self;
}

- (OAFeature *) feature
{
    return OAFeature.UNLIMITED_MAP_DOWNLOADS;
}

- (NSDecimalNumber *) getDefaultPrice
{
    return [[NSDecimalNumber alloc] initWithDouble:kInApp_Region_South_America_Default_Price];
}

- (NSString *) localizedTitle
{
    return OALocalizedString(@"index_name_south_america");
}

@end

@interface OAProducts()

@property (nonatomic) OAProduct *skiMap;
@property (nonatomic) OAProduct *nautical;
@property (nonatomic) OAProduct *trackRecording;
@property (nonatomic) OAProduct *parking;
@property (nonatomic) OAProduct *wiki;
@property (nonatomic) OAProduct *srtm;
@property (nonatomic) OAProduct *osmEditing;
@property (nonatomic) OAProduct *mapillary;
@property (nonatomic) OAProduct *weather;
@property (nonatomic) OAProduct *sensors;
@property (nonatomic) OAProduct *carplay;
@property (nonatomic) OAProduct *osmandDevelopment;

@property (nonatomic) OAProduct *allWorld;
@property (nonatomic) OAProduct *russia;
@property (nonatomic) OAProduct *antarctica;
@property (nonatomic) OAProduct *africa;
@property (nonatomic) OAProduct *asia;
@property (nonatomic) OAProduct *australia;
@property (nonatomic) OAProduct *europe;
@property (nonatomic) OAProduct *centralAmerica;
@property (nonatomic) OAProduct *northAmerica;
@property (nonatomic) OAProduct *southAmerica;

@property (nonatomic) NSArray<OAProduct *> *inApps;
@property (nonatomic) NSArray<OAProduct *> *inAppsFree;
@property (nonatomic) NSArray<OAProduct *> *inAppsPaid;

@property (nonatomic) NSArray<OAProduct *> *inAppMaps;
@property (nonatomic) NSArray<OAProduct *> *inAppMapsPaid;

@property (nonatomic) NSArray<OAProduct *> *inAppAddons;
@property (nonatomic) NSArray<OAProduct *> *inAppAddonsPaid;

@property (nonatomic) OASubscription *proMonthly;
@property (nonatomic) OASubscription *proAnnually;
@property (nonatomic) OASubscription *mapsAnnually;
@property (nonatomic) OAProduct *mapsFull;
@property (nonatomic) OASubscription *monthlyLiveUpdates;
@property (nonatomic) OASubscriptionList *subscriptionList;

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
        self.osmEditing = [[OAOsmEditingProduct alloc] init];
        self.mapillary = [[OAMapillaryProduct alloc] init];
        self.weather = [[OAWeatherProduct alloc] init];
        self.sensors = [[OAExternalSensorsProduct alloc] init];
        self.carplay = [[OACarPlayProduct alloc] init];
        self.osmandDevelopment = [[OAOsmandDevelopmentProduct alloc] init];

        self.allWorld = [[OAAllWorldProduct alloc] init];
        self.russia = [[OARussiaProduct alloc] init];
        self.antarctica = [[OAAntarcticaProduct alloc] init];
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
                             self.osmEditing,
                             self.mapillary,
                             self.weather,
                             self.sensors,
                             self.osmandDevelopment
        ];

        self.inAppMaps = @[self.allWorld,
                           self.russia,
                           self.africa,
                           self.asia,
                           self.australia,
                           self.europe,
                           self.centralAmerica,
                           self.northAmerica,
                           self.southAmerica];

        self.mapsFull = [[OAMapsFullProduct alloc] init];

        NSMutableArray *inApps = [NSMutableArray arrayWithArray:self.inAppAddons];
        [inApps addObjectsFromArray:self.inAppMaps];
        [inApps addObject:self.mapsFull];
        self.inApps = inApps;

        NSMutableArray<OAProduct *> *free = [NSMutableArray array];
        for (OAProduct *p in self.inApps)
        {
            if (p.free)
                [free addObject:p];
        }
        self.inAppsFree = free;

        NSMutableArray<OAProduct *> *paidAddons = [NSMutableArray arrayWithArray:self.inAppAddons];
        [paidAddons removeObjectsInArray:self.inAppsFree];
        self.inAppAddonsPaid = paidAddons;

        NSMutableArray<OAProduct *> *paidMaps = [NSMutableArray arrayWithArray:self.inAppMaps];
        [paidMaps removeObjectsInArray:self.inAppsFree];
        self.inAppMapsPaid = paidMaps;

        self.monthlyLiveUpdates = [[OALiveUpdatesMonthly alloc] initWithVersion:1];
        self.proMonthly = [[OAProSubscriptionMonthly alloc] initWithVersion:1];
        self.proAnnually = [[OAProSubscriptionAnnual alloc] initWithVersion:1];
        self.mapsAnnually = [[OAMapsSubscriptionAnnual alloc] initWithVersion:1];

        self.subscriptionList = [[OASubscriptionList alloc] initWithSubscriptions:@[
                self.monthlyLiveUpdates,
                [[OALiveUpdates3Months alloc] initWithVersion:1],
                [[OALiveUpdatesAnnual alloc] initWithVersion:1],
                self.proMonthly,
                self.proAnnually,
                self.mapsAnnually
        ]];

        NSMutableArray<OAProduct *> *paid = [NSMutableArray arrayWithArray:self.inApps];
        [paid removeObjectsInArray:self.inAppsFree];
        [paid addObjectsFromArray:self.subscriptionList.subscriptions];
        self.inAppsPaid = paid;

        [self buildFunctionalAddonsArray];
    }
    return self;
}

- (NSArray<OAProduct *> *) inAppsPurchased
{
    NSMutableArray<OAProduct *> *purchased = [NSMutableArray array];
    for (OAProduct *p in self.inAppsPaid)
    {
        if ([p isPurchased])
            [purchased addObject:p];
    }
    if ([self.nautical isPurchased])
        [purchased addObject:self.nautical];
    return purchased;
}

- (NSArray<OAProduct *> *) inAppMapsPurchased
{
    NSMutableArray<OAProduct *> *purchased = [NSMutableArray array];
    for (OAProduct *p in self.inAppMapsPaid)
    {
        if ([p isPurchased])
            [purchased addObject:p];
    }
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
    {
        if ([p.productIdentifier isEqualToString:productIdentifier])
            return p;
    }

    return [self.subscriptionList getSubscriptionByIdentifier:productIdentifier];
}

- (BOOL) updateProduct:(SKProduct *)skProduct
{
    OASubscription *s = [self.subscriptionList getSubscriptionByIdentifier:skProduct.productIdentifier];
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

- (BOOL) setPurchased:(NSString * _Nonnull)productIdentifier
{
    OAProduct *product = [self getProduct:productIdentifier];
    if (!product)
        product = [self.subscriptionList upgradeSubscription:productIdentifier];

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
        product = [self.subscriptionList upgradeSubscription:productIdentifier];
    
    if (product)
    {
        [product setExpired];
        [self buildFunctionalAddonsArray];
        return YES;
    }
    return NO;
}

- (BOOL) setExpirationDate:(NSString * _Nonnull)productIdentifier expirationDate:(NSDate * _Nullable)expirationDate
{
    OAProduct *product = [self getProduct:productIdentifier];
    if (!product)
        product = [self.subscriptionList upgradeSubscription:productIdentifier];
    
    if (product)
    {
        [product setExpirationDate:expirationDate];
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
        OAFunctionalAddon *addonEdit = [[OAFunctionalAddon alloc] initWithAddonId:kId_Addon_TrackRecording_Edit_Waypoint titleShort:OALocalizedString(@"edit_waypoint_short") titleWide:OALocalizedString(@"context_menu_item_edit_waypoint") imageName:@"icon_edit"];
        addonEdit.sortIndex = 1;
        [arr addObject:addonEdit];

        OAFunctionalAddon *addonAdd = [[OAFunctionalAddon alloc] initWithAddonId:kId_Addon_TrackRecording_Add_Waypoint titleShort:OALocalizedString(@"add_waypoint_short") titleWide:OALocalizedString(@"add_waypoint") imageName:@"add_waypoint_to_track"];
        addonAdd.sortIndex = 1;
        [arr addObject:addonAdd];
    }
    
    if ([self.osmEditing isPurchased])
    {
        OAFunctionalAddon *addon = [[OAFunctionalAddon alloc] initWithAddonId:kId_Addon_OsmEditing_Edit_POI titleShort:OALocalizedString(@"poi_context_menu_modify") titleWide:OALocalizedString(@"modify_poi") imageName:@"ic_plugin_osm_edit"];
        addon.sortIndex = 2;
        [arr addObject:addon];
    }
    
    if ([self.mapillary isPurchased])
    {
        OAFunctionalAddon *addon = [[OAFunctionalAddon alloc] initWithAddonId:kInAppId_Addon_Mapillary titleShort:OALocalizedString(@"mapillary") titleWide:OALocalizedString(@"mapillary") imageName:@"ic_custom_mapillary_symbol"];
        addon.sortIndex = 3;
        [arr addObject:addon];
    }
    
    if ([self.osmandDevelopment isPurchased])
    {
        OAFunctionalAddon *addon = [[OAFunctionalAddon alloc] initWithAddonId:kInAppId_Addon_OsmandDevelopment titleShort:OALocalizedString(@"debugging_and_development") titleWide:OALocalizedString(@"debugging_and_development") imageName:@"ic_custom_laptop"];
        addon.sortIndex = 3;
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
