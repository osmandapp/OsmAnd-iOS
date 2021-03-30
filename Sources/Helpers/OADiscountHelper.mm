//
//  OADiscountHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/helpers/DiscountHelper.java
//  git revision f5f971874f8bffbb6471d905f699874519957f4f

#import "OADiscountHelper.h"
#import <Reachability.h>
#import "OAAppSettings.h"
#import "OADiscountToolbarViewController.h"
#import "OARootViewController.h"
#import "OAUtilities.h"
#import "OAPluginsViewController.h"
#import "OAPluginDetailsViewController.h"
#import "OAIAPHelper.h"
#import "OAManageResourcesViewController.h"
#import "OASearchUICore.h"
#import "OAQuickSearchHelper.h"
#import "OAQuickSearchListItem.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OAChoosePlanHelper.h"

const static NSString *URL = @"http://osmand.net/api/motd";

@implementation OAPurchaseCondition

@synthesize helper;

- (instancetype) initWithIAPHelper:(OAIAPHelper *)helper
{
    self = [super init];
    if (self)
    {
        self.helper = helper;
    }
    return self;
}

- (NSString *) getId
{
    return  @"";
}

- (BOOL) matches:(NSString *)value
{
    return NO;
}

@end


@implementation OANotPurchasedSubscriptionCondition

- (NSString *) getId
{
    return @"not_purchased_subscription";
}

- (BOOL) matches:(NSString *)value
{
    OASubscription *subscription = [self.helper.liveUpdates getSubscriptionByIdentifier:value];
    return !subscription || ![subscription isPurchased];
}

@end

@implementation OAPurchasedSubscriptionCondition

- (NSString *) getId
{
    return @"purchased_subscription";
}

- (BOOL) matches:(NSString *)value
{
    OASubscription *subscription = [self.helper.liveUpdates getSubscriptionByIdentifier:value];
    return subscription && [subscription isPurchased];
}

@end

@implementation OANotPurchasedPluginCondition

- (NSString *) getId
{
    return @"not_purchased_plugin";
}

- (BOOL) matches:(NSString *)value
{
    OAProduct *product = [self.helper product:value];
    return !product || ![product isPurchased];
}

@end

@implementation OAPurchasedPluginCondition

- (NSString *) getId
{
    return @"purchased_plugin";
}

- (BOOL) matches:(NSString *)value
{

    OAProduct *product = [self.helper product:value];
    return product && [product isPurchased];
}

@end

@implementation OANotPurchasedInAppPurchaseCondition

-(NSString *) getId
{
    return @"not_purchased_inapp";
}

- (BOOL) matches:(NSString *)value
{
    OAProduct *product = [self.helper product:value];
    return !product || ![product isPurchased];
}

@end

@implementation OAPurchasedInAppPurchaseCondition

- (NSString *) getId
{
    return @"purchased_inapp";
}

- (BOOL) matches:(NSString *)value
{
    OAProduct *product = [self.helper product:value];
    return product && [product isPurchased];
}

@end

@interface OADiscountHelper () <OADiscountToolbarViewControllerProtocol>

@end

@implementation OADiscountHelper
{
    NSTimeInterval _lastCheckTime;
    NSString *_title;
    NSString *_description;
    NSString *_textButtonTitle;
    NSString *_icon;
    NSString *_url;

    NSDictionary<NSString *, UIColor *> *_colors;
    
    OAProduct *_product;
    BOOL _bannerVisible;
    
    OADiscountToolbarViewController *_discountToolbar;
}

+ (OADiscountHelper *) instance
{
    static dispatch_once_t once;
    static OADiscountHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (BOOL) isVisible
{
    return _bannerVisible;
}

- (void) checkAndDisplay
{
    if (_bannerVisible)
        [self showDiscountBanner];
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if ([OAAppSettings sharedManager].settingDoNotShowPromotions || currentTime - _lastCheckTime < 60 * 60 * 24 || [Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable)
    {
        return;
    }
    _lastCheckTime = currentTime;
    
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSString *ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    int execCount = (int)[settings integerForKey:kAppExecCounter];
    double appInstalledTime = [settings doubleForKey:kAppInstalledDate];
    int appInstalledDays = (int)((currentTime - appInstalledTime) / (24 * 60 * 60));
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSDictionary *languageDictionary = [NSLocale componentsFromLocaleIdentifier:language];
    NSString *languageCode = [languageDictionary objectForKey:NSLocaleLanguageCode];
    NSURL *urlObj = [NSURL URLWithString:[NSString stringWithFormat:@"%@?os=ios&version=%@&nd=%d&ns=%d&lang=%@", URL, ver, appInstalledDays, execCount, languageCode]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlObj
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"OsmAndiOS" forHTTPHeaderField:@"User-Agent"];
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (response)
        {
            @try
            {
                [self processDiscountResponse:data];
            }
            @catch (NSException *e)
            {
                // ignore
            }
        }
    }];
    
    [downloadTask resume];
}

- (void) processDiscountResponse:(NSData *)data
{
    NSMutableDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    
    if (map)
    {
        int execCount = (int)[[NSUserDefaults standardUserDefaults] integerForKey:kAppExecCounter];

        NSString *message = [map objectForKey:@"message"];
        NSString *description = [map objectForKey:@"description"];
        NSString *icon = [map objectForKey:@"icon"];
        NSString *url = [map objectForKey:@"url"];
        NSString *inAppId = [map objectForKey:@"in_app"];
        NSArray *purchasedInApps = [map objectForKey:@"purchased_in_apps"];
        NSString *textButtonTitle = [map objectForKey:@"button_title"];
        
        NSMutableDictionary<NSString *, UIColor *> *mutableDictionary = [NSMutableDictionary new];
        NSString *bgColor = [map objectForKey:@"bg_color"];
        NSString *titleColor = [map objectForKey:@"title_color"];
        NSString *descrColor = [map objectForKey:@"description_color"];
        NSString *statusBarColor = [map objectForKey:@"status_bar_color"];
        NSString *buttonTitleColor = [map objectForKey:@"button_title_color"];

        if (bgColor)
            [mutableDictionary setObject:[OAUtilities colorFromString:bgColor] forKey:@"bg_color"];
        if (titleColor)
            [mutableDictionary setObject:[OAUtilities colorFromString:titleColor] forKey:@"title_color"];
        if (descrColor)
            [mutableDictionary setObject:[OAUtilities colorFromString:descrColor] forKey:@"description_color"];
        if (statusBarColor)
            [mutableDictionary setObject:[OAUtilities colorFromString:statusBarColor] forKey:@"status_bar_color"];
        if (buttonTitleColor)
            [mutableDictionary setObject:[OAUtilities colorFromString:buttonTitleColor] forKey:@"button_title_color"];
        
        _colors = [NSDictionary dictionaryWithDictionary:mutableDictionary];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"dd-MM-yyyy HH:mm"];
        NSDate *start = [df dateFromString:[map objectForKey:@"start"]];
        NSDate *end = [df dateFromString:[map objectForKey:@"end"]];
        
        int showStartFrequency = [[map objectForKey:@"show_start_frequency"] intValue];
        double showDayFrequency = [[map objectForKey:@"show_day_frequency"] doubleValue];
        int maxTotalShow = [[map objectForKey:@"max_total_show"] intValue];
        
        OAIAPHelper *helper = [OAIAPHelper sharedInstance];
        NSArray *conditions = [map objectForKey:@"oneOfConditions"];
        if (conditions)
        {
            BOOL oneOfConditionsMatch = NO;
            
            NSArray <id<OACondition>> *purchaseConditions = [NSArray arrayWithObjects:[[OAPurchasedPluginCondition alloc] initWithIAPHelper:helper],
                                                     [[OANotPurchasedPluginCondition alloc] initWithIAPHelper:helper],
                                                     [[OANotPurchasedSubscriptionCondition alloc] initWithIAPHelper:helper],
                                                     [[OAPurchasedSubscriptionCondition alloc] initWithIAPHelper:helper],
                                                     [[OANotPurchasedInAppPurchaseCondition alloc] initWithIAPHelper:helper],
                                                     [[OAPurchasedInAppPurchaseCondition alloc] initWithIAPHelper:helper], nil];
            for (NSDictionary *conditionDictionary in conditions)
            {
                NSArray *conditionsArray = [conditionDictionary valueForKey:@"condition"];
                if (conditionsArray && [conditionsArray count] > 0)
                {
                    BOOL conditionMatch = YES;
                    for (NSDictionary *condition in conditionsArray)
                    {
                        conditionMatch = [self matchesCondition:purchaseConditions condition:condition];
                        if (!conditionMatch)
                            break;
                    }
                    oneOfConditionsMatch |= conditionMatch;
                }
            }
            if (!oneOfConditionsMatch)
                return;
        }

        NSDate *date = [NSDate date];
        if ([date timeIntervalSinceDate:start] > 0 && [date timeIntervalSinceDate:end] < 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                OAAppSettings *settings = [OAAppSettings sharedManager];
                int discountId = [self getDiscountId:message description:description start:start end:end];
                BOOL discountChanged = settings.discountId != discountId;
                if (discountChanged)
                    settings.discountTotalShow = 0;
                
                if (discountChanged
                    || execCount - settings.discountShowNumberOfStarts >= showStartFrequency
                    || [date timeIntervalSince1970] - settings.discountShowDatetime > 60 * 60 * 24 * showDayFrequency)
                {
                    if (settings.discountTotalShow < maxTotalShow)
                    {
                        settings.discountId = discountId;
                        settings.discountTotalShow = settings.discountTotalShow + 1;
                        settings.discountShowNumberOfStarts = execCount;
                        settings.discountShowDatetime = [date timeIntervalSince1970];
                        
                        _title = message ? message : @"";
                        _description = description ? description : @"";
                        _icon = icon;
                        _url = url ? url : @"";
                        _product = nil;
                        _textButtonTitle = textButtonTitle ? textButtonTitle : @"";
                        
                        NSArray<OAProduct *> *inApps = helper.inApps;
                        OAProduct *product = nil;
                        for (OAProduct *p in inApps)
                        {
                            NSString *identifier = p.productIdentifier;
                            if (!product && inAppId && [identifier hasSuffix:inAppId])
                            {
                                product = p;
#if !defined(OSMAND_IOS_DEV)
                                if ([p isPurchased])
                                    return;
#endif
                            }
                            
#if !defined(OSMAND_IOS_DEV)
                            if (purchasedInApps)
                                for (NSString *purchased in purchasedInApps)
                                    if ([identifier hasSuffix:purchased] && [p isPurchased])
                                        return;
#endif
                        }
                        _product = product;
                        
                        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
                        {
                            [helper requestProductsWithCompletionHandler:^(BOOL success) {
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self showDiscountBanner];
                                });
                            }];
                        }
                    }
                }
            });
        }
    }
}

- (BOOL) matchesCondition:(NSArray<id<OACondition>> *)purchaseConditions condition:(NSDictionary *)condition
{
    for (id<OACondition> purchaseCondition : purchaseConditions)
    {
        NSString *value = [condition valueForKey:[purchaseCondition getId]];
        if (value && [value length] > 0)
            return [purchaseCondition matches:value];
    }
    return NO;
}

- (int) getDiscountId:(NSString *)message description:(NSString *)description start:(NSDate *)start end:(NSDate *)end
{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result = prime * result + (!message ? 0 : [message hash]);
    result = prime * result + (!start ? 0 : [start hash]);
    return (int)result;
}

- (void) showDiscountBanner
{
    if (!_discountToolbar)
    {
        _discountToolbar = [[OADiscountToolbarViewController alloc] initWithNibName:@"OADiscountToolbarViewController" bundle:nil];
        _discountToolbar.discountDelegate = self;
    }
    
    UIImage *icon = _icon ? [OAUtilities getTintableImageNamed:_icon] : nil;
    if (!icon)
        icon = [OAUtilities getTintableImageNamed:@"ic_action_gift"];
    
    [_discountToolbar setTitle:_title description:_description icon:icon buttonText:_textButtonTitle colors:_colors];
    
    _bannerVisible = YES;
    
    [[OARootViewController instance].mapPanel showToolbar:_discountToolbar];
}

- (void) openUrl
{
    if (_url.length > 0)
    {
        if ([_url hasPrefix:@"in_app:"])
        {
            NSString *discountType = [_url substringFromIndex:7];
            if ([@"plugin" isEqualToString:discountType] && _product)
            {
                OAPluginDetailsViewController *pluginDetails = [[OAPluginDetailsViewController alloc] initWithProduct:_product];
                pluginDetails.openFromCustomPlace = YES;
                [[OARootViewController instance].navigationController pushViewController:pluginDetails animated:YES];

                //OAPluginsViewController *pluginsViewController = [[OAPluginsViewController alloc] init];
                //pluginsViewController.openFromCustomPlace = YES;
                //[[OARootViewController instance].navigationController pushViewController:pluginsViewController animated:YES];
            }
            else if ([@"map" isEqualToString:discountType])
            {
                OAManageResourcesViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
                resourcesViewController.displayBannerPurchaseAllMaps = YES;
                [[OARootViewController instance].navigationController pushViewController:resourcesViewController animated:YES];
            }
        }
        else if ([_url hasPrefix:@"osmand-search-query:"])
        {
            NSString *query = [_url substringFromIndex:[@"osmand-search-query:" length]];
            if ([query length] > 0)
            {
                OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
                [mapPanel openSearch:OAQuickSearchType::REGULAR location:nil tabIndex:1 searchQuery:query];
            }
        }
        else if ([_url hasPrefix:@"osmand-show-poi:"])
        {
            NSString *names = [_url substringFromIndex:[@"osmand-show-poi:" length]];
            if ([names length] > 0) {
                NSMutableArray *objects = [NSMutableArray array];
                for (NSString *type : [names componentsSeparatedByString:@","])
                {
                    OASearchResultCollection *res = [[[OAQuickSearchHelper instance] getCore] shallowSearch:[OASearchAmenityTypesAPI class] text:type matcher:nil];
                    if (res)
                    {
                        for (OASearchResult *sr in [res getCurrentSearchResults])
                        {
                            if ([[sr.localeName lowerCase] isEqualToString:type])
                                [objects addObject:sr.object];
                        }
                    }
                }
                OAPOIFiltersHelper *helper = [OAPOIFiltersHelper sharedInstance];
                OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
                [helper clearSelectedPoiFilters];
                for (NSObject *object in objects)
                {
                    if ([object isKindOfClass:[OAPOIUIFilter class]])
                    {
                        [helper addSelectedPoiFilter:(OAPOIUIFilter *) object];
                    }
                    else if ([object isKindOfClass:[OAPOIFilter class]])
                    {
                        OAPOIFilter *poiFilter = (OAPOIFilter *) object;
                        OAPOIUIFilter *uiFilter = [[OAPOIUIFilter alloc] initWithBasePoiType:poiFilter idSuffix:@""];
                        [helper addSelectedPoiFilter:uiFilter];
                    }
                    else if ([object isKindOfClass:[OAPOIType class]])
                    {
                        OAPOIType *poiType = (OAPOIType *) object;
                        OAPOIUIFilter *uiFilter = [[OAPOIUIFilter alloc] initWithBasePoiType:poiType idSuffix:@""];
                        [helper addSelectedPoiFilter:uiFilter];
                    }
                    else if ([object isKindOfClass:[OAPOICategory class]])
                    {
                        OAPOICategory *poiCategory = (OAPOICategory *) object;
                        OAPOIUIFilter *uiFilter = [[OAPOIUIFilter alloc] initWithBasePoiType:poiCategory idSuffix:@""];
                        [helper addSelectedPoiFilter:uiFilter];
                    }
                }
                [mapVC updatePoiLayer];
            }
        }
        else if ([_url hasPrefix:@"show-choose-plan:"])
        {
            OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
            NSString *productIdentifierSuffix = [_url substringFromIndex:[@"show-choose-plan:" length]];
            [OAChoosePlanHelper showChoosePlanScreenWithSuffix:productIdentifierSuffix navController:mapPanel.navigationController];
        }
        else
        {
            [OAUtilities callUrl:_url];
        }
    }
}

#pragma mark - OADiscountToolbarViewControllerProtocol

- (void) discountToolbarPress
{
    _bannerVisible = NO;
    [self openUrl];
    [[OARootViewController instance].mapPanel hideToolbar:_discountToolbar];
}

- (void) discountToolbarClose
{
    _bannerVisible = NO;
    [[OARootViewController instance].mapPanel hideToolbar:_discountToolbar];
}

@end
