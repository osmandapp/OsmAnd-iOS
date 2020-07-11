//
//  OAMapStyleAction.h
//  OsmAnd
//
//  Created by Paul on 8/13/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OASwitchableAction.h"

NS_ASSUME_NONNULL_BEGIN

@class OAMapSource;

@interface OAMapStyleAction : OASwitchableAction

@property (nonatomic, readonly) NSDictionary<NSString *, OAMapSource *> *offlineMapSources;

- (NSArray<NSString *> *) getFilteredStyles;

@end

NS_ASSUME_NONNULL_END
