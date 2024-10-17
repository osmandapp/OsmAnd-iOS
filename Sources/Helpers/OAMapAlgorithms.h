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

@class OASTrkSegment;

@interface OAMapAlgorithms : NSObject

+ (QList<int>) decodeIntHeightArrayGraph:(const QString &)str repeatBits:(int)repeatBits;
+ (OASTrkSegment *) augmentTrkSegmentWithAltitudes:(OASTrkSegment *)sgm decodedSteps:(const QList<int> &)decodedSteps startEle:(double)startEle;

@end
