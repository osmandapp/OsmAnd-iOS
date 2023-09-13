//
//  OADestinationsListViewController+cpp.h
//  OsmAnd
//
//  Created by Skalii on 07.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OADestinationItem;

@interface OADistanceAndDirectionsUpdater : NSObject

+ (void)updateDistanceAndDirections:(BOOL)focreUpdate items:(NSArray<OADestinationItem *> *)items;

@end
