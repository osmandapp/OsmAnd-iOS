//
//  OAMapPanelViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OAMapRendererViewController.h"

@interface OAMapPanelViewController : UIViewController

@property (nonatomic, strong, readonly) OAMapRendererViewController* rendererViewController;

@end
