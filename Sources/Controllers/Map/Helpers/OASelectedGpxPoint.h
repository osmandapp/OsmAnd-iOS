//
//  OASelectedGpxPoint.h
//  OsmAnd
//
//  Created by Max Kojin on 02/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@class OASGpxFile, OASWptPt;

@interface OASelectedGpxPoint: NSObject

- (OASGpxFile *) getSelectedGpxFile;
- (OASWptPt *) getSelectedPoint;

@end
