//
//  OAInAppPurchases.m
//  OsmAnd
//
//  Created by Alexey on 11/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAProducts.h"
#import <StoreKit/StoreKit.h>
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

@end

@implementation OAProduct
{
    NSNumberFormatter *_numberFormatter;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        self.purchaseState = PSTATE_UNKNOWN;
    }
    return self;
}

- (instancetype) initWithSkProduct:(SKProduct *)skProduct;
{
    self = [self init];
    if (self)
    {
        [self setSkProduct:skProduct];
    }
    return self;
}

- (instancetype) initWithIdentifier:(NSString *)productIdentifier title:(NSString *)title desc:(NSString *)desc price:(NSDecimalNumber *)price priceLocale:(NSLocale *)priceLocale
{
    self = [self init];
    if (self)
    {
        self.productIdentifier = productIdentifier;
        self.localizedTitle = title;
        self.localizedDescription = desc;
        self.price = price;
        self.priceLocale = priceLocale;
    }
    return self;
}

- (instancetype) initWithIdentifier:(NSString *)productIdentifier;
{
    self = [self init];
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
    }
    return self;
}

- (void) setSkProduct:(SKProduct *)skProduct;
{
    self.productIdentifier = skProduct.productIdentifier;
    self.localizedTitle = skProduct.localizedTitle;
    self.localizedDescription = skProduct.localizedDescription;
    self.price = skProduct.price;
    self.priceLocale = skProduct.priceLocale;

    NSString *postfix = [[_productIdentifier componentsSeparatedByString:@"."] lastObject];
    NSString *locDescriptionExtId = [@"product_desc_ext_" stringByAppendingString:postfix];
    self.localizedDescriptionExt = OALocalizedString(locDescriptionExtId);

    self.skProduct = skProduct;
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

- (NSDecimalNumber *) getDefaultPrice
{
    return nil;
}

- (BOOL) isPurchased
{
    return self.purchaseState == PSTATE_PURCHASED;
}

- (BOOL) fetchRequired
{
    return self.purchaseState == PSTATE_UNKNOWN;
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

@implementation OAProducts

@end
