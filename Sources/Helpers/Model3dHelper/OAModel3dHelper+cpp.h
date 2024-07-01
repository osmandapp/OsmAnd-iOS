//
//  OAModel3dHelper_cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 26/06/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAModel3dHelper.h"
#include <OsmAndCore/ObjParser.h>
#include "OsmAndCore/Map/Model3D.h"

@interface OAModel3dWrapper(cpp)

- (instancetype)initWith:(std::shared_ptr<const OsmAnd::Model3D>)model;
- (std::shared_ptr<const OsmAnd::Model3D>) model;

@end
