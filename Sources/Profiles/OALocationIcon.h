//
//  OALocationIcon.h
//  OsmAnd
//
//  Created by Alexey on 28.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOALocationIcon)
{
    LOCATION_ICON_DEFAULT = 0,
    LOCATION_ICON_CAR,
    LOCATION_ICON_BICYCLE
};

@interface OALocationIcon : NSObject

@property (nonatomic, readonly) EOALocationIcon locationIcon;

+ (instancetype) withLocationIcon:(EOALocationIcon)locationIcon;
- (UIImage *) iconWithColor:(UIColor *)color;
- (UIImage *) iconWithColor:(UIColor *)color scaleFactor:(CGFloat)currentScaleFactor;
- (UIImage *) headingIconWithColor:(UIColor *)color;

+ (NSArray<OALocationIcon *> *) values;

+ (UIImage *) getIcon:(EOALocationIcon)locationIcon color:(UIColor *)color;
+ (UIImage *) getMapIcon:(EOALocationIcon)locationIcon color:(UIColor *)color scaleFactor:(CGFloat)currentScaleFactor;
+ (UIImage *) getHeadingIcon:(EOALocationIcon)locationIcon color:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
