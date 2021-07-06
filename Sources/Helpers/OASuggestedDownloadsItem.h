//
//  OASuggestedDownloadsItem.h
//  OsmAnd
//
//  Created by nnngrach on 08.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASettingsItem.h"

NS_ASSUME_NONNULL_BEGIN

@class OAWorldRegion;

@interface OASuggestedDownloadsItem : OASettingsItem

@property (nonatomic, readonly) NSString *scopeId;
@property (nonatomic, readonly) NSString *searchType;
@property (nonatomic, readonly) NSArray<NSString *> *names;
@property (nonatomic, readonly) NSInteger limit;

@property (nonatomic, readonly) NSMutableArray *items;

- (OASuggestedDownloadsItem *) initWithScopeId:(NSString *)scopeId searchType:(NSString *)searchType names:(NSArray<NSString *> *)names limit:(NSInteger)limit;

@end

NS_ASSUME_NONNULL_END
