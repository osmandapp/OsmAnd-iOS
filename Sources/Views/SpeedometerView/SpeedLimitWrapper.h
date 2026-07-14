//
//  SpeedLimitWrapper.h
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 21.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface SpeedLimitData : NSObject

@property (nonatomic, readonly) int value;
@property (nullable, nonatomic, copy, readonly) NSString *text;

- (instancetype)initWithValue:(int)value text:(nullable NSString *)text;

@end

@interface SpeedLimitWrapper : NSObject

- (SpeedLimitData *)speedLimitData;

@end

NS_ASSUME_NONNULL_END
