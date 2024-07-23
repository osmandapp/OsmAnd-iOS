//
//  OADestinationsLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 09/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAContextMenuProvider.h"

@interface OADestinationsLayer : OASymbolMapLayer<OAContextMenuProvider, OAMoveObjectProvider>

- (void) addDestinationPin:(NSString *)markerResourceName color:(UIColor *)color latitude:(double)latitude longitude:(double)longitude description:(NSString *)description;
- (void) removeDestinationPin:(double)latitude longitude:(double)longitude;

@end
