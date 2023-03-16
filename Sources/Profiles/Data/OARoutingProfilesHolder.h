//
//  OARoutingProfilesHolder.h
//  OsmAnd
//
//  Created by Skalii on 16.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OARoutingDataObject;

@interface OARoutingProfilesHolder : NSObject

- (OARoutingDataObject *)get:(NSString *)routingProfileKey derivedProfile:(NSString *)derivedProfile;
- (void)add:(OARoutingDataObject *)profile;
- (void)setSelected:(OARoutingDataObject *)selected;
- (NSString *)createFullKey:(NSString *)routingProfileKey derivedProfile:(NSString *)derivedProfile;

@end
