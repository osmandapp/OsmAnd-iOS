//
//  OADestinationsListViewController+cpp.h
//  OsmAnd
//
//  Created by Skalii on 07.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OATableDataModel.h"

@class OADestinationItem;

@interface OADistanceAndDirectionsUpdater : NSObject

+ (void)updateDistanceAndDirections:(OATableDataModel *)data
                         indexPaths:(NSArray<NSIndexPath *> *)indexPaths
                            itemKey:(NSString *)itemKey;

@end
