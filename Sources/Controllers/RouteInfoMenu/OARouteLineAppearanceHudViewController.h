//
//  OARouteLineAppearanceHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 20.12.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseScrollableHudViewController.h"

@class OAApplicationMode;

@protocol OARouteLineAppearanceViewControllerDelegate <NSObject>

@required

-(void)onCloseAppearance;

@end

@interface OARouteLineAppearanceHudViewController : OABaseScrollableHudViewController

- (instancetype)initWithAppMode:(OAApplicationMode *)appMode;

@property (nonatomic) id<OARouteLineAppearanceViewControllerDelegate> delegate;

@end
