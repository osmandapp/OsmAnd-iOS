//
//  OABaseSettingsViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
#import "OABaseNavbarViewController.h"

@class OAApplicationMode;

@protocol OASettingsDataDelegate <NSObject>

- (void) onSettingsChanged;
- (void) closeSettingsScreenWithRouteInfo;
- (void) openNavigationSettings;

@end

@interface OABaseSettingsViewController : OABaseNavbarViewController <OASettingsDataDelegate>

@property (weak, nonatomic) id<OASettingsDataDelegate> delegate;
@property (nonatomic) OAApplicationMode *appMode;

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode;

- (CGFloat) heightForLabel:(NSString *)text;
- (CGFloat) fontSizeForLabel;
- (void) setupTableHeaderViewWithText:(NSString *)text;

@end
