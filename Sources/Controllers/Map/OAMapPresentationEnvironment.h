//
//  OAMapPresentationEnvironment.h
//  OsmAnd Maps
//
//  Created by Paul on 15.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore/Map/MapPresentationEnvironment.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAMapPresentationEnvironment : NSObject

@property (nonatomic) std::shared_ptr<OsmAnd::MapPresentationEnvironment> mapPresentationEnvironment;

- (instancetype) initWithEnvironment:(const std::shared_ptr<OsmAnd::MapPresentationEnvironment> &)env;

@end

NS_ASSUME_NONNULL_END
