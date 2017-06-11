//
//  OARasterMapLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapLayer.h"

@interface OARasterMapLayer : OAMapLayer

// NOTE: layerIndex = zOrder, but two layers cannot have same layerIndex value
@property (nonatomic, readonly) int layerIndex;

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController layerIndex:(int)layerIndex;

@end
