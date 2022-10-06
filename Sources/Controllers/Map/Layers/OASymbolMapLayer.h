//
//  OASymbolMapLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapLayer.h"

#import <OsmAndCore/TextRasterizer.h>

@interface OASymbolMapLayer : OAMapLayer

@property (nonatomic, readonly) BOOL showCaptions;
@property (nonatomic, readonly) OsmAnd::TextRasterizer::Style captionStyle;
@property (nonatomic, readonly) double captionTopSpace;

@end
