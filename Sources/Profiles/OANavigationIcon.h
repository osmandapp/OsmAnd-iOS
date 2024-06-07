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

typedef NS_ENUM(NSInteger, EOANavigationIcon)
{
    NAVIGATION_ICON_DEFAULT = 0,
    NAVIGATION_ICON_NAUTICAL,
    NAVIGATION_ICON_CAR
};

@interface OANavigationIcon : NSObject

@property (nonatomic, readonly) EOANavigationIcon navigationIcon;

+ (instancetype) withNavigationIcon:(EOANavigationIcon)navigationIcon;
- (UIImage *) iconWithColor:(UIColor *)color scaleFactor:(CGFloat)currentScaleFactor;

+ (NSArray<OANavigationIcon *> *) values;

+ (UIImage *) getIcon:(EOANavigationIcon)navigationIcon color:(UIColor *)color scaleFactor:(CGFloat)currentScaleFactor;

@end

NS_ASSUME_NONNULL_END
