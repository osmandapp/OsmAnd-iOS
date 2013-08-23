//
//  OAMapHudViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAMapHudViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;
- (IBAction)showLeftPanel:(id)sender;

@end
