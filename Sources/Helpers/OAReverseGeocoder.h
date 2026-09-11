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

- (void)lookupAddressAtLat:(double)lat
                       lon:(double)lon
                  objectId:(uint64_t)objectId
                completion:(void (^)(NSString *address))completion;

@end

NS_ASSUME_NONNULL_END
