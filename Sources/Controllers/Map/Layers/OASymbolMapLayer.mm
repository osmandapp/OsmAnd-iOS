//
//  OASymbolMapLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"

@implementation OASymbolMapLayer

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder
{
    self = [super initWithMapViewController:mapViewController];
    if (self)
    {
        _baseOrder = baseOrder;
    }
    return self;
}

@end
