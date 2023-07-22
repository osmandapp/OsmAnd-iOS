//
//  OAAppDelegate.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CarPlay/CarPlay.h>

#import "OARootViewController.h"

@interface OAAppDelegate : UIResponder <UIApplicationDelegate, CPApplicationDelegate>

@property(strong, readonly, nonatomic) OARootViewController* rootViewController;

@end
