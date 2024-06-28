//
//  OANavigationIcon.h
//  OsmAnd
//
//  Created by Alexey on 29.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *NAVIGATION_ICON_DEFAULT = @"map_navigation_default";
static NSString *NAVIGATION_ICON_NAUTICAL = @"map_navigation_nautical";
static NSString *NAVIGATION_ICON_CAR = @"map_navigation_car";

@interface OANavigationIcon : NSObject

+ (instancetype) withIconName:(NSString *)iconName;
- (UIImage *) iconWithColor:(UIColor *)color;
- (UIImage *) getMapIcon:(UIColor *)color;

+ (UIImage *) getIcon:(NSString *)iconName color:(UIColor *)color;
+ (UIImage *) getModelPreviewDrawable:(NSString *)iconName;
+ (UIImage *) getPreviewIcon:(NSString *)iconName color:(UIColor *)color;

+ (BOOL) isModel:(NSString *)iconName;
- (BOOL) isModel;

@end

NS_ASSUME_NONNULL_END
