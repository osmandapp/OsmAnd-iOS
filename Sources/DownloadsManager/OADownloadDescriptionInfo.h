//
//  OADownloadDescriptionInfo.h
//  OsmAnd Maps
//
//  Created by Paul on 20.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define DOWNLOAD_BUTTON_ACTION @"download"

@interface OADownloadActionButton : NSObject

@property (nonatomic, readonly) NSString *actionType;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *url;

@end

@interface OADownloadDescriptionInfo : NSObject

@property (nonatomic, readonly) NSArray<NSString *> *imageUrls;

+ (instancetype) fromJson:(NSDictionary *)json;
- (NSDictionary *) toJson;

- (NSString *) getLocalizedDescription;
- (NSArray<OADownloadActionButton *> *) getActionButtons;

@end

NS_ASSUME_NONNULL_END
