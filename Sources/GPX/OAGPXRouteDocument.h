//
//  OAGPXRouteDocument.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXDocument.h"



@interface OAGPXRouteDocument : OAGPXDocument

- (const std::shared_ptr<OsmAnd::GpxDocument>&) getDocument;

- (void)buildRouteTrack;

@end
