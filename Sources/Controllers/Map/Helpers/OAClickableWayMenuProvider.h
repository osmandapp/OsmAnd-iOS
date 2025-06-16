//
//  OAClickableWayMenuProvider.h
//  OsmAnd
//
//  Created by Max Kojin on 11/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAContextMenuProvider.h"

@interface OAClickableWayMenuProvider : OASymbolMapLayer <OAContextMenuProvider>

- (instancetype)init:(id)readHeightData openAsGpxFile:(id)openAsGpxFile;

@end
