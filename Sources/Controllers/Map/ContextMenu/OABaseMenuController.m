//
//  OABaseMenuController.m
//  OsmAnd
//
//  Created by Alexey on 26/06/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABaseMenuController.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAAppSettings.h"

const static CGFloat kLandscapeWidth = 320.0;

@interface OABaseMenuController ()

@property (nonatomic) BOOL portraitMode;
@property (nonatomic) BOOL nightMode;

@end

@implementation OABaseMenuController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.portraitMode = [OAUtilities isLeftSideLayout:CurrentInterfaceOrientation];
        [self updateNightMode];
    }
    return self;
}

- (BOOL) isLight
{
    return !self.nightMode;
}

- (void) updateNightMode
{
    self.nightMode = [[OAAppSettings sharedManager] nightMode];
}

- (BOOL) isLandscapeLayout
{
    return !self.portraitMode;
}

- (int) getLandscapeWidth
{
    return kLandscapeWidth;
}

- (float) getHalfScreenMaxHeightKoef
{
    return .75f;
}

- (EContextMenuAnimation) getSlideInAnimation
{
    if ([self isLandscapeLayout])
        return EContextMenuAnimationSlideInLeft;
    else
        return EContextMenuAnimationSlideInBottom;
}

- (EContextMenuAnimation) getSlideOutAnimation
{
    if ([self isLandscapeLayout])
        return EContextMenuAnimationSlideOutLeft;
    else
        return EContextMenuAnimationSlideOutBottom;
}

- (UIImage *) getIconOrig:(NSString *)iconId
{
    return [UIImage imageNamed:iconId];
}

- (UIImage *) getIcon:(NSString *)iconId
{
    UIColor *color = UIColorFromRGB([self isLight] ? color_icon_color : color_icon_color_light);
    return [self getIcon:iconId color:color];
}

- (UIImage *) getIcon:(NSString *)iconId color:(UIColor *)color
{
    UIImage *img = [UIImage imageNamed:iconId];
    if (img)
        return [OAUtilities tintImageWithColor:img color:color];
    else
        return nil;
}

- (UIImage *) getIcon:(NSString *)iconId colorLight:(UIColor *)colorLight colorDark:(UIColor *)colorDark
{
    UIColor *color = [self isLight] ? colorLight : colorDark;
    return [self getIcon:iconId color:color];
}

@end
