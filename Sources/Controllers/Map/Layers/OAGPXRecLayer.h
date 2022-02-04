//
//  OARecGPXLayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAGPXLayer.h"

@interface OAGPXRecLayer : OAGPXLayer

- (void) updateGpxTrack:(QHash< QString, std::shared_ptr<const OsmAnd::GpxDocument> >)gpxDocs;

@end
