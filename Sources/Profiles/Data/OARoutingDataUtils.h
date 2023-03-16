//
//  OARoutingDataUtils.h
//  OsmAnd
//
//  Created by Skalii on 16.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAProfilesGroup, OARoutingProfilesHolder;

@interface OARoutingDataUtils : NSObject

+ (NSArray<OAProfilesGroup *> *)getOfflineProfiles;
+ (OARoutingProfilesHolder *)getRoutingProfiles;

@end
