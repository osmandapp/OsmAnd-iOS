//
//  OAKml2Gpx.h
//  OsmAnd
//
//  Created by Paul on 7/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAKml2Gpx : NSObject

+ (NSString *) toGpx:(NSData *)inputData;

@end

NS_ASSUME_NONNULL_END
