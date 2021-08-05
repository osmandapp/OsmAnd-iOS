//
//  OAUrlImageCard.m
//  OsmAnd
//
//  Created by Paul on 5/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAUrlImageCard.h"
#import "OAWebViewController.h"
#import "OAMapPanelViewController.h"

@implementation OAUrlImageCard

- (void) onCardPressed:(OAMapPanelViewController *) mapPanel
{
    NSString *cardUrl = [self getSuitableUrl];
    OAWebViewController *viewController = [[OAWebViewController alloc] initWithUrlAndTitle:cardUrl title:mapPanel.getCurrentTargetPoint.title];
    [mapPanel.navigationController pushViewController:viewController animated:YES];
}

@end
