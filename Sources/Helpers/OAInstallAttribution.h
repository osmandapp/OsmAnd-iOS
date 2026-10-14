//
//  OAInstallAttribution.h
//  OsmAnd
//
//  Created by OsmAnd on 14/10/2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Apple Ads campaign of the App Store install (AdServices), sent like the Android Google Play install referrer:
// utm_source=apple_ads, utm_campaign=<campaignId>, utm_content=<adGroupId>, utm_term=<keywordId>, ad_click=1.
// Read and sent only while sending anonymous app usage data (the same setting as aid) is enabled.
@interface OAInstallAttribution : NSObject

+ (void) readOnce;
+ (void) addParams:(NSMutableDictionary<NSString *, NSString *> *)params;
+ (NSString *) urlQuery;

@end

NS_ASSUME_NONNULL_END
