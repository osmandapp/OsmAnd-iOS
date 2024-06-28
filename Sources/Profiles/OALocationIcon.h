//
//  OALocationIcon.h
//  OsmAnd
//
//  Created by Alexey on 28.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *LOCATION_ICON_DEFAULT = @"map_location_default";
static NSString *LOCATION_ICON_CAR = @"map_location_car";
static NSString *LOCATION_ICON_BICYCLE = @"map_location_bicycle";

@interface OALocationIcon : NSObject

+ (instancetype) withIconName:(NSString *)iconName;
- (UIImage *) iconWithColor:(UIColor *)color;
- (UIImage *) getMapIcon:(UIColor *)color;
- (UIImage *) headingIconWithColor:(UIColor *)color;

+ (UIImage *) getIcon:(NSString *)iconName color:(UIColor *)color;
+ (UIImage *) getPreviewIcon:(NSString *)iconName color:(UIColor *)color;

+ (BOOL) isModel:(NSString *)iconName;
- (BOOL) isModel;

@end

NS_ASSUME_NONNULL_END
