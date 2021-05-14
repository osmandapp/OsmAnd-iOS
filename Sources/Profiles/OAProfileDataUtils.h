//
//  OAProfileDataUtils.h
//  OsmAnd
//
//  Created by nnngrach on 28.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
//  git revision 38a3e8c6fea11a4a01d4751f7804f2ea20553b95

#import <Foundation/Foundation.h>

@class OAProfileDataObject, OARoutingProfileDataObject, OAApplicationMode;

@interface OAProfileDataUtils : NSObject

+ (NSArray<OAProfileDataObject *> *) getDataObjects:(NSArray<OAApplicationMode *> *)appModes;
+ (NSArray<OARoutingProfileDataObject *> *) getSortedRoutingProfiles;
+ (NSDictionary<NSString *, OARoutingProfileDataObject *> *) getRoutingProfiles;

@end
