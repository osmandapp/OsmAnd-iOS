//
//  OAProfileIconColor.h
//  OsmAnd
//
//  Created by Alexey on 29.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOAProfileIconColor)
{
    PROFILE_ICON_COLOR_DEFAULT = 0,
    PROFILE_ICON_COLOR_PURPLE,
    PROFILE_ICON_COLOR_GREEN,
    PROFILE_ICON_COLOR_BLUE,
    PROFILE_ICON_COLOR_RED,
    PROFILE_ICON_COLOR_DARK_YELLOW,
    PROFILE_ICON_COLOR_MAGENTA
};

@interface OAProfileIconColor : NSObject

@property (nonatomic, readonly) EOAProfileIconColor profileIconColor;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) int dayColor;
@property (nonatomic, readonly) int nightColor;

+ (instancetype) withProfileIconColor:(EOAProfileIconColor)profileIconColor;
- (int) getColor:(BOOL)nightMode;

+ (NSArray<OAProfileIconColor *> *) values;

+ (NSString *) getName:(EOAProfileIconColor)profileIconColor;
+ (int) getDayColor:(EOAProfileIconColor)profileIconColor;
+ (int) getNightColor:(EOAProfileIconColor)profileIconColor;

+ (int) getColor:(EOAProfileIconColor)profileIconColor nightMode:(BOOL)nightMode;
+ (int) getOutdatedLocationColor:(EOAProfileIconColor)profileIconColor nightMode:(BOOL)nightMode;

@end

NS_ASSUME_NONNULL_END
