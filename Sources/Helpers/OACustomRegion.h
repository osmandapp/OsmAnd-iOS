//
//  OACustomRegion.h
//  OsmAnd Maps
//
//  Created by Paul on 17.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAWorldRegion.h"

NS_ASSUME_NONNULL_BEGIN

@class OAResourceItem;

@interface OADynamicDownloadItems : NSObject

@property (nonatomic, readonly) NSString *url;
@property (nonatomic, readonly) NSString *format;
@property (nonatomic, readonly) NSString *itemsPath;
@property (nonatomic, readonly) NSDictionary *mapping;

+ (instancetype) fromJson:(NSDictionary *)object;

- (NSDictionary *) toJson;

@end


@interface OACustomRegion : OAWorldRegion

@property (nonatomic, readonly) NSString *path;
@property (nonatomic,readonly) NSString *parentPath;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *subfolder;

- (instancetype) initWithScopeId:(NSString *)scopeId path:(NSString *)path type:(NSString *)type;

+ (instancetype) fromJson:(NSDictionary *)json;
- (NSDictionary *) toJson;

- (void) loadDynamicIndexItems;

- (NSArray<OAResourceItem *> *) loadIndexItems;

@end

NS_ASSUME_NONNULL_END
