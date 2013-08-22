//
//  UIViewController+OARootVC.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "UIViewController+OARootVC.h"

#import "UIViewController+JASidePanel.h"

@implementation UIViewController (OARootVC)

- (OARootViewController*)rootViewController
{
    return (OARootViewController*)self.sidePanelController;
}

@end
