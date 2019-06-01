//
//  OAMapillaryLayer.h
//  OsmAnd
//
//  Created by Alexey on 19/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAContextMenuProvider.h"
#import "OARasterMapLayer.h"

@interface OAMapillaryLayer : OARasterMapLayer<OAContextMenuProvider>

- (void) clearCache;

@end
