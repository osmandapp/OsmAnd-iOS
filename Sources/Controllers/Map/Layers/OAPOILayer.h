//
//  OAPOILayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAContextMenuProvider.h"

@class OASearchResult;

@interface OAPOILayer : OASymbolMapLayer<OAContextMenuProvider>

+ (OATargetPoint *)getTargetPoint:(id)obj;

- (void)setCustomSearchResults:(NSArray<OASearchResult *> *)results;
- (OASearchResult *)customAddressResultWithAmenityId:(uint64_t)amenityId;

@end
