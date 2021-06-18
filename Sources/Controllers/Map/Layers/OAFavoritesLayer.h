//
//  OAFavoritesLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAContextMenuProvider.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

@interface OAFavoritesLayer : OASymbolMapLayer<OAContextMenuProvider, OAMoveObjectProvider>

+ (UIImage *) getImageWithColor:(UIColor *)color background:(NSString *)background icon:(NSString *)icon;

@end
