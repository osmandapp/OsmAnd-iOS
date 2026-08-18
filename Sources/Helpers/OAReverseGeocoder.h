//
//  OAGeocoder.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAReverseGeocoder : NSObject

+ (OAReverseGeocoder *)instance;

- (NSString *)lookupAddressAtLat:(double)lat lon:(double)lon;
- (NSString *)lookupAddressAtLat:(double)lat lon:(double)lon objectId:(uint64_t)objectId;
- (NSString *)lookupShortAddressAtLat:(double)lat lon:(double)lon;

@end

NS_ASSUME_NONNULL_END
