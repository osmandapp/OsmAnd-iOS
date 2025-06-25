//
//  OASelectedMapObject.h
//  OsmAnd
//
//  Created by Max Kojin on 02/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAContextMenuProvider.h"

NS_ASSUME_NONNULL_BEGIN


@class OASGpxFile;

@interface OASelectedMapObject  : NSObject

- (instancetype)initWithMapObject:(id)object provider:(id<OAContextMenuProvider>)provider;
- (id<OAContextMenuProvider>)object;
- (id<OAContextMenuProvider>)provider;

@end


NS_ASSUME_NONNULL_END
