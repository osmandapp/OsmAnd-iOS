//
//  OARootViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <JASidePanelController.h>

#import "OAOptionsPanelViewController.h"
#import "OAMapPanelViewController.h"
#import "OAContextPanelViewController.h"

@interface OARootViewController : JASidePanelController

@property (nonatomic, weak, readonly) OAOptionsPanelViewController* optionsPanel;
@property (nonatomic, weak, readonly) OAMapPanelViewController* mapPanel;
@property (nonatomic, weak, readonly) OAContextPanelViewController* contextPanel;

@end
