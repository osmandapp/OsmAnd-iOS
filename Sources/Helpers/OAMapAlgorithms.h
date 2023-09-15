//
//  OAMapAlgorithms.h
//  OsmAnd
//
//  Created by nnngrach on 15.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OsmAndCore/QtExtensions.h>
#include <QString>

@class OATrkSegment;

@interface OAMapAlgorithms : NSObject

+ (std::vector<int>) decodeIntHeightArrayGraph:(QString)str repeatBits:(int)repeatBits;
+ (OATrkSegment *) augmentTrkSegmentWithAltitudes:(OATrkSegment *)sgm decodedSteps:(std::vector<int>)decodedSteps startEle:(double)startEle;

@end
