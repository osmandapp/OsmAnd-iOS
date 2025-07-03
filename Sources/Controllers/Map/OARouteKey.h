//
//  OARouteKey.h
//  OsmAnd Maps
//
//  Created by Paul on 02.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OASGpxFile;

@interface OARouteKey : NSObject <NSCopying>

@property (nonatomic, readonly) NSString *localizedTitle;

+ (OARouteKey *) fromGpx:(OASGpxFile *)gpx;
- (NSString *) getActivityTypeTitle;

@end
