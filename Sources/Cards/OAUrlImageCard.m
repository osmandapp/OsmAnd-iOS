//
//  OAUrlImageCard.m
//  OsmAnd
//
//  Created by Paul on 5/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAUrlImageCard.h"

@implementation OAUrlImageCard

- (void) onCardPressed:(OAMapPanelViewController *) mapPanel
{
    NSString *cardUrl = [self getSuitableUrl];
    if (cardUrl && cardUrl.length > 0)
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cardUrl]];
}

@end
