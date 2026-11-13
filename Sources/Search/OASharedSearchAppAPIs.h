//
//  OASharedSearchAppAPIs.h
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OsmAndSharedWrapper.h"

NS_ASSUME_NONNULL_BEGIN

// Data stays in the app's repositories; these sources publish it into the shared search.
@interface OASharedSearchAppAPI : OASSearchCoreFactorySearchBaseAPI
- (instancetype)init;
@end

@interface OASharedSearchFavoritesAPI : OASharedSearchAppAPI
@end

@interface OASharedSearchFavoritesCategoryAPI : OASharedSearchAppAPI
@end

@interface OASharedSearchGpxAPI : OASharedSearchAppAPI
@end

@interface OASharedSearchWptAPI : OASharedSearchAppAPI
@end

@interface OASharedSearchHistoryAPI : OASharedSearchAppAPI
@end

@interface OASharedSearchIndexItemAPI : OASharedSearchAppAPI
@end

@interface OASharedSearchAppAPIs : NSObject
+ (nullable Class)sharedClassForAppClass:(Class)appClass;
@end

NS_ASSUME_NONNULL_END
