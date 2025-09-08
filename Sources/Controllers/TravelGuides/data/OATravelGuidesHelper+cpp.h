//
//  OATravelGuidesHelper+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 09/07/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OATravelGuidesHelper.h"

#include <OsmAndCore/Data/BinaryMapObject.h>

@class OATravelGpx;

@interface OATravelGuidesHelper(cpp)

+ (QList< std::shared_ptr<const OsmAnd::BinaryMapObject> >)searchGpxMapObject:(OATravelGpx *)travelGpx bbox31:(OsmAnd::AreaI)bbox31 reader:(NSString *)reader;
+ (QList< std::shared_ptr<const OsmAnd::BinaryMapObject> >) searchGpxMapObject:(OATravelGpx *)travelGpx bbox31:(OsmAnd::AreaI)bbox31 reader:(NSString *)reader useAllObfFiles:(BOOL)useAllObfFiles;

@end
