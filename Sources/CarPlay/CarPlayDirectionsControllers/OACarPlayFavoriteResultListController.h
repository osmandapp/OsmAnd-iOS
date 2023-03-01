//
//  OACarPlayFavoriteResultListController.h
//  OsmAnd
//
//  Created by Skalii on 01.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayListController.h"

@class OAFavoriteItem;

@interface OACarPlayFavoriteResultListController : OABaseCarPlayListController

- (instancetype)initWithInterfaceController:(CPInterfaceController *)interfaceController
                                 folderName:(NSString *)folderName
                               favoriteList:(NSArray<OAFavoriteItem *> *)favoriteList;

@end
