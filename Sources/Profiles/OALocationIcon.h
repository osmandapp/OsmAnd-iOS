//
//  OALocationIcon.h
//  OsmAnd
//
//  Created by Alexey on 28.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *LOCATION_ICON_DEFAULT = @"DEFAULT";
static NSString *LOCATION_ICON_CAR = @"CAR";
static NSString *LOCATION_ICON_BICYCLE = @"BICYCLE";

@interface OALocationIcon : NSObject

+ (instancetype) withIconName:(NSString *)iconName;
- (NSString *) iconName;
- (UIImage *) iconWithColor:(UIColor *)color;
- (UIImage *) getMapIcon:(UIColor *)color;
- (UIImage *) headingIconWithColor:(UIColor *)color;

+ (UIImage *) getIcon:(NSString *)iconName color:(UIColor *)color;
+ (UIImage *) getPreviewIcon:(NSString *)iconName color:(UIColor *)color;

+ (BOOL) isModel:(NSString *)iconName;
- (BOOL) isModel;

+ (NSArray<NSString *> *) getIconNames;
+ (NSString *) getStandardIconModelName:(NSString *)iconName;

@end

NS_ASSUME_NONNULL_END
