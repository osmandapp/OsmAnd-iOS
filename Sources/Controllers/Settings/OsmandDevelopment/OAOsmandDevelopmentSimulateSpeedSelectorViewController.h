//
//  OAOsmandDevelopmentSimulateSpeedSelectorViewController.h
//  OsmAnd
//
//  Created by nnngrach on 02.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

typedef NS_ENUM(NSInteger, EOASimulateNavigationSpeed) {
    EOASimulateNavigationSpeedOriginal = 0,
    EOASimulateNavigationSpeed2x = 1,
    EOASimulateNavigationSpeed3x = 2,
    EOASimulateNavigationSpeed4x = 3
};

@interface OASimulateNavigationSpeed : NSObject

+ (NSString *) toTitle:(EOASimulateNavigationSpeed)enumValue;
+ (NSString *) toDescription:(EOASimulateNavigationSpeed)enumValue;
+ (NSString *) toKey:(EOASimulateNavigationSpeed)enumValue;
+ (EOASimulateNavigationSpeed) fromKey:(NSString *)key;

@end


@protocol OAOsmandDevelopmentSimulateSpeedSelectorDelegate <NSObject>

- (void) onSpeedSelectorInformationUpdated:(EOASimulateNavigationSpeed)selectedSpeedMode;

@end


@interface OAOsmandDevelopmentSimulateSpeedSelectorViewController : OABaseSettingsViewController

@property (nonatomic, weak) id<OAOsmandDevelopmentSimulateSpeedSelectorDelegate> speedSelectorDelegate;

@end
