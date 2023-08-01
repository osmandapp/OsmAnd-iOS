//
//  OAAppDelegate.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OARootViewController.h"
#import <CarPlay/CarPlay.h>

NS_ASSUME_NONNULL_BEGIN

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (strong, nonatomic) UIWindow * window;
@property (strong, nonatomic, readonly) OARootViewController* rootViewController;
@property (assign, nonatomic, readonly) BOOL appInitDone;
@property (assign, nonatomic, readonly) BOOL appInitializing;

- (BOOL)openURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
