//
//  OAGPXMutableDocument+cpp.h
//  OsmAnd
//
//  Created by Skalii on 30.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAGPXMutableDocument.h"

#include <OsmAndCore/GpxDocument.h>

@interface OAGPXMutableDocument(cpp)

- (const std::shared_ptr<OsmAnd::GpxDocument>&) getDocument;

@end
