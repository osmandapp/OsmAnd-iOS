//
//  SceneDelegate.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OARootViewController;

NS_ASSUME_NONNULL_BEGIN

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) OARootViewController *rootViewController;
@property (strong, nonatomic, nullable) NSURL *loadedURL;

- (BOOL)openURL:(NSURL *)url;
- (UIInterfaceOrientation)getUIIntefaceOrientation;

@end

NS_ASSUME_NONNULL_END
