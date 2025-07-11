//
//  OASymbolMapLayer+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 04/07/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

#import <OsmAndCore/TextRasterizer.h>

@interface OASymbolMapLayer(cpp)

@property (nonatomic, readonly) OsmAnd::TextRasterizer::Style captionStyle;

@end
