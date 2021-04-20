//
//  OACustomPlugin.h
//  OsmAnd
//
//  Created by Paul on 15.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface OASuggestedDownloadItem : NSObject

@property (nonatomic, readonly) NSString *scopeId;
@property (nonatomic, readonly) NSString *searchType;
@property (nonatomic, readonly) NSArray<NSString *> *names;
@property (nonatomic, readonly) NSInteger limit;

@end

@interface OACustomPlugin : OAPlugin

@property (nonatomic, readonly) NSString *resourceDirName;
@property (nonatomic, readonly) NSArray<NSString *> *rendererNames;
@property (nonatomic, readonly) NSArray<NSString *> *routerNames;

- (instancetype) initWithJson:(NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END
