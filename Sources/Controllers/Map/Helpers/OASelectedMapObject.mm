//
//  OASelectedMapObject.mm
//  OsmAnd
//
//  Created by Max Kojin on 02/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OASelectedMapObject.h"

@implementation OASelectedMapObject
{
    id _object;
    id<OAContextMenuProvider> _provider;
}

- (instancetype) initWithMapObject:(id)object provider:(id<OAContextMenuProvider>)provider
{
    self = [super init];
    if (self)
    {
        _object = object;
        _provider = provider;
    }
    return self;
}

- (id) object
{
    return _object;
}

- (id<OAContextMenuProvider>) provider
{
    return _provider;
}

@end
