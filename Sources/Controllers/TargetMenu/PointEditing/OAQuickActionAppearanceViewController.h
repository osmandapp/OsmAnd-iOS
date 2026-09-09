//
//  OAQuickActionAppearanceViewController.h
//  OsmAnd Maps
//
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

#import "OAGroupEditorViewController.h"

NS_ASSUME_NONNULL_BEGIN

// Transient "pick a color/icon/shape" screen reusing the same editor used for
// Favorite folder "Change / Default appearance", without persisting anything to
// real storage - used to configure a Quick Action's predefined waypoint appearance.
@interface OAQuickActionAppearanceViewController : OAGroupEditorViewController

- (nullable instancetype)initWithColor:(UIColor *)color
                               iconName:(nullable NSString *)iconName
                     backgroundIconName:(nullable NSString *)backgroundIconName;

@end

NS_ASSUME_NONNULL_END
