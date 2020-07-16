//
//  OAAvoidRoadInfo.h
//  OsmAnd
//
//  Created by Alexey on 05.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAAvoidRoadInfo : NSObject

@property (nonatomic) unsigned long long roadId;
@property (nonatomic) CLLocation *location;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *appModeKey;

- (instancetype) initWithDict:(NSDictionary<NSString *, NSString *> *)dict;
- (NSDictionary<NSString *, NSString *> *) toDict;

@end

NS_ASSUME_NONNULL_END
