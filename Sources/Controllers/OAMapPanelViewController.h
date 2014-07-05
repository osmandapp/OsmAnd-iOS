//
//  OAMapPanelViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OAMapViewController.h"

@interface OAMapPanelViewController : UIViewController

@property (nonatomic, strong, readonly) OAMapViewController* rendererViewController;

@end
