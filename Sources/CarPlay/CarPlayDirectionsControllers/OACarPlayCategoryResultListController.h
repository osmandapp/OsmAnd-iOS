//
//  OACarPlayCategoryResultListController.h
//  OsmAnd Maps
//
//  Created by Paul on 18.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayListController.h"

NS_ASSUME_NONNULL_BEGIN

@class OASearchResult;

@interface OACarPlayCategoryResultListController : OABaseCarPlayListController

- (instancetype) initWithInterfaceController:(CPInterfaceController *)interfaceController searchResult:(OASearchResult *)sr;

@end

NS_ASSUME_NONNULL_END
