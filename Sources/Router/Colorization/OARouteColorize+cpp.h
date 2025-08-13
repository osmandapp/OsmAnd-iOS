//
//  OARouteColorize+cpp.h
//  OsmAnd
//
//  Created by Skalii on 09.07.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OARouteColorize.h"

#include <OsmAndCore/QtExtensions.h>
#include <QList>
#include <OsmAndCore/Color.h>

@interface OARouteColorize(cpp)

- (QList<OsmAnd::FColorARGB>)getResultQList;

@end
