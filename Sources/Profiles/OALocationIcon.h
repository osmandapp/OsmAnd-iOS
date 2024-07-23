//
//  OALocationIcon.h
//  OsmAnd
//
//  Created by Alexey on 28.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OALocationIcon : NSObject

+ (instancetype) withModelName:(NSString *)modelName;
+ (instancetype) withName:(NSString *)name iconName:(NSString *)iconName headingIconName:(NSString *)headingIconName modelName:(NSString *)modelName;

+ (void) initialize;
+ (OALocationIcon *) locationIconWithName:(NSString *)name;

+ (OALocationIcon *) DEFAULT;
+ (OALocationIcon *) CAR;
+ (OALocationIcon *) BICYCLE;
+ (OALocationIcon *) MOVEMENT_DEFAULT;
+ (OALocationIcon *) MOVEMENT_NAUTICAL;
+ (OALocationIcon *) MOVEMENT_CAR;

+ (NSArray<OALocationIcon *> *) defaultIcons;
+ (NSArray<NSString *> *) defaultIconNames;
+ (NSArray<NSString *> *) defaultIconModels;

- (NSString *) name;
- (NSString *) iconName;
- (NSString *) headingIconName;
- (NSString *) modelName;

- (UIImage *) getMapIcon:(UIColor *)color;
- (UIImage *) getHeadingIconWithColor:(UIColor *)color;
- (UIImage *) getPreviewIconWithColor:(UIColor *)color;

+ (BOOL) isModel:(NSString *)modelName;
- (BOOL) isModel;
- (BOOL) shouldDisplayModel;

@end

NS_ASSUME_NONNULL_END
