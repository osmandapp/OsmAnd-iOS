//
//  OAPOIViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATransportStopsBaseController.h"

static NSString * OTHER_MAP_CATEGORY = @"Other";

@class OAPOI, OARenderedObject, OAMapObject;

@interface OAPOIViewController : OATransportStopsBaseController

- (id) initWithPOI:(OAPOI *)poi;

- (void) setObject:(id)object;
- (void) setup:(OAPOI *)poi;
- (NSString *) getOsmUrl;

- (BOOL)buildShortWikiDescription:(NSDictionary<NSString *, id> *)filteredInfo allowOnlineWiki:(BOOL)allowOnlineWiki rows:(NSMutableArray<OAAmenityInfoRow *> *)rows;

@end
