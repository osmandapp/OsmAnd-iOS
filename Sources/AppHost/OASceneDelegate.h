//
//  OASceneDelegate.h
//  OsmAnd Maps
//
//  Created by Maxim Kovalko on 7/18/23.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CarPlay/CarPlay.h>

#import "OARootViewController.h"

@interface OASceneDelegate: UIResponder <UIWindowSceneDelegate, CPTemplateApplicationSceneDelegate>

@property (strong, nonatomic) UIWindow * window;
@property(strong, readonly, nonatomic) OARootViewController* rootViewController;

@end
