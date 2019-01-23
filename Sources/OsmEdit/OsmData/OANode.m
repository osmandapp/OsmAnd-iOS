//
//  OANode.m
//  OsmAnd
//
//  Created by Paul on 1/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANode.h"

static const long serialVersionUID = -2981499160640211082L;

@implementation OANode

- (CLLocationCoordinate2D)getLatLon {
    return CLLocationCoordinate2DMake([self getLatitude], [self getLongitude]);
}

- (void)initializeLinks:(nonnull NSDictionary<OAEntityId *,OAEntity *> *)entities {
    // nothing to initialize for Node
}

-(NSString *) toNSString
{
    return [NSString stringWithFormat:@"Node{\nlatitude=%f\n, longitude=%f\n, tags=%@]n}", [self getLatitude], [self getLongitude], [self getTags]];
}

@end
