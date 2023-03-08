//
//  OADownloadMode.h
//  OsmAnd
//
//  Created by Skalii on 08.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OADownloadMode : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *iconName;

+ (OADownloadMode *) NONE;
+ (OADownloadMode *) WIFI_ONLY;
+ (OADownloadMode *) ANY_NETWORK;

+ (NSArray<OADownloadMode *> *) getDownloadModes;

- (BOOL) isDontDownload;
- (BOOL) isDownloadOnlyViaWifi;
- (BOOL) isDownloadViaAnyNetwork;

@end

