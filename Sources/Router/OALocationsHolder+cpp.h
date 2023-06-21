//
//  OALocationsHolder+cpp.h
//  OsmAnd
//
//  Created by Skalii on 12.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OALocationsHolder.h"

#include <vector>

@interface OALocationsHolder(cpp)

- (std::vector<std::pair<double, double>>) getLatLonList;

@end
