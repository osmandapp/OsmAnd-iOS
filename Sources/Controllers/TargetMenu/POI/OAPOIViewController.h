//
//  OAPOIViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATransportStopsBaseController.h"

@class OAPOI, OARenderedObject, OAMapObject;

@interface OAPOIViewController : OATransportStopsBaseController

- (id) initWithPOI:(OAPOI *)poi;

- (void) setup:(OAPOI *)poi;
- (NSString *) getOsmUrl;

@end
