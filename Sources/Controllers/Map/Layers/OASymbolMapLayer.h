//
//  OASymbolMapLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapLayer.h"

@interface OASymbolMapLayer : OAMapLayer

@property (nonatomic, readonly) int baseOrder;

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController baseOrder:(int)baseOrder;

@end
