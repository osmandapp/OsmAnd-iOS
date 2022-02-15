//
//  OACurrentStreetName.h
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <turnType.h>
#include <binaryRead.h>

NS_ASSUME_NONNULL_BEGIN

@class OANextDirectionInfo;

@interface OACurrentStreetName : NSObject

@property (nonatomic) NSString *text;
@property (nonatomic) std::shared_ptr<TurnType> turnType;
@property (nonatomic, assign) BOOL showMarker; // turn type has priority over showMarker
@property (nonatomic) std::shared_ptr<RouteDataObject> shieldObject;
@property (nonatomic) NSString *exitRef;

+ (OACurrentStreetName *) getCurrentName:(OANextDirectionInfo *)n;

@end

NS_ASSUME_NONNULL_END
