//
//  OAOverUnderlayBaseAction.h
//  OsmAnd
//
//  Created by Paul on 8/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OASwitchableAction.h"

NS_ASSUME_NONNULL_BEGIN

@class OAMapSource;

@interface OAOverUnderlayBaseAction : OASwitchableAction

@property (nonatomic, readonly) NSArray<OAMapSource *> *onlineMapSources;

- (void) commonInit;

@end

NS_ASSUME_NONNULL_END
