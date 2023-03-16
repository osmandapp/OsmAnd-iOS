//
//  OAProfilesGroup.m
//  OsmAnd
//
//  Created by Skalii on 16.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAProfilesGroup.h"
#import "OARoutingDataObject.h"

@implementation OAProfilesGroup
{
    NSMutableArray<OARoutingDataObject *> *_mProfiles;
}

- (instancetype)initWithTitle:(NSString *)title profiles:(NSArray<OARoutingDataObject *> *)profiles
{
    self = [super init];
    if (self)
    {
        _title = title;
        _mProfiles = [NSMutableArray arrayWithArray:profiles];
    }
    return self;
}

- (NSArray<OARoutingDataObject *> *)profiles
{
    return [NSArray arrayWithArray:_mProfiles];
}

- (void)sortProfiles
{
    [_mProfiles sortUsingComparator:^NSComparisonResult(OARoutingDataObject *p1, OARoutingDataObject *p2) {
        return [p1 compare:p2];
    }];
}

@end
