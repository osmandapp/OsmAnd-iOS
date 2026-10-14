//
//  OAInstallAttribution.m
//  OsmAnd
//
//  Created by OsmAnd on 14/10/2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAInstallAttribution.h"
#import "OAAppSettings.h"
#import <AdServices/AdServices.h>

static NSString * const kInstallAttribution = @"install_attribution";
static NSString * const kInstallAttributionChecked = @"install_attribution_checked";
static NSString * const kAttributionUrl = @"https://api-adservices.apple.com/api/v1/";
static const int kMaxAttempts = 3;
static const NSTimeInterval kRetryDelay = 5.0;

@implementation OAInstallAttribution

+ (BOOL) isAllowed
{
    return [[OAAppSettings sharedManager].sendAnonymousAppUsageData get];
}

+ (void) readOnce
{
    if (![self isAllowed] || [NSUserDefaults.standardUserDefaults boolForKey:kInstallAttributionChecked])
        return;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSString *token = [AAAttribution attributionTokenWithError:&error];
        if (token.length == 0)
        {
            [self markChecked:nil];
            return;
        }
        [self requestAttribution:token attempt:1];
    });
}

+ (void) requestAttribution:(NSString *)token attempt:(int)attempt
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kAttributionUrl]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:30.0];
    request.HTTPMethod = @"POST";
    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [token dataUsingEncoding:NSUTF8StringEncoding];
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger status = [response isKindOfClass:NSHTTPURLResponse.class] ? ((NSHTTPURLResponse *) response).statusCode : 0;
        if (status == 200 && data)
        {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            [self markChecked:[json isKindOfClass:NSDictionary.class] ? [self campaignParams:json] : nil];
        }
        else if (status == 400)
        {
            // invalid token, it will not become valid
            [self markChecked:nil];
        }
        else if (attempt < kMaxAttempts)
        {
            // 404: attribution is not ready yet; network errors: try again, otherwise on the next start
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (kRetryDelay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                [self requestAttribution:token attempt:attempt + 1];
            });
        }
    }] resume];
}

+ (nullable NSDictionary<NSString *, NSString *> *) campaignParams:(NSDictionary *)json
{
    if (![json[@"attribution"] boolValue])
        return nil;

    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    params[@"utm_source"] = @"apple_ads";
    NSDictionary<NSString *, NSString *> *keys = @{ @"campaignId" : @"utm_campaign", @"adGroupId" : @"utm_content", @"keywordId" : @"utm_term" };
    [keys enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *param, BOOL *stop) {
        id value = json[key];
        if ([value isKindOfClass:NSNumber.class] || [value isKindOfClass:NSString.class])
            params[param] = [NSString stringWithFormat:@"%@", value];
    }];
    if ([json[@"claimType"] isEqual:@"Click"])
        params[@"ad_click"] = @"1";
    return params;
}

+ (void) markChecked:(nullable NSDictionary<NSString *, NSString *> *)params
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (params.count > 0)
        [defaults setObject:params forKey:kInstallAttribution];
    [defaults setBool:YES forKey:kInstallAttributionChecked];
}

+ (void) addParams:(NSMutableDictionary<NSString *, NSString *> *)params
{
    if (![self isAllowed])
        return;
    NSDictionary *attribution = [NSUserDefaults.standardUserDefaults dictionaryForKey:kInstallAttribution];
    [attribution enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        if ([key isKindOfClass:NSString.class] && [value isKindOfClass:NSString.class])
            params[key] = value;
    }];
}

+ (NSString *) urlQuery
{
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    [self addParams:params];
    NSMutableString *query = [NSMutableString string];
    NSCharacterSet *allowed = NSCharacterSet.URLQueryAllowedCharacterSet;
    for (NSString *key in [params.allKeys sortedArrayUsingSelector:@selector(compare:)])
        [query appendFormat:@"&%@=%@", key, [params[key] stringByAddingPercentEncodingWithAllowedCharacters:allowed]];
    return query;
}

@end
