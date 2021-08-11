//
//  OADownloadedRegionsLayer.h
//  OsmAnd
//
//  Created by Alexey on 24.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"
#import "OAContextMenuProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class OAWorldRegion, OAResourceItem;

@interface OADownloadMapObject : NSObject

@property (nonatomic, readonly) OAWorldRegion *worldRegion;
@property (nonatomic, readonly) OAResourceItem *indexItem;

- (instancetype) initWithWorldRegion:(OAWorldRegion *)worldRegion indexItem:(OAResourceItem *)indexItem;

@end

@interface OADownloadedRegionsLayer : OASymbolMapLayer <OAContextMenuProvider>

- (void) highlightRegion:(OAWorldRegion *)region;
- (void) hideRegionHighlight;

@end

NS_ASSUME_NONNULL_END
