//
//  OARoutingFile.m
//  OsmAnd
//
//  Created by Skalii on 16.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OARoutingFile.h"

@implementation OARoutingFile
{
    NSMutableArray<OARoutingDataObject *> *_mProfiles;
}

- (instancetype)initWithFileName:(NSString *)fileName
{
    self = [super init];
    if (self)
    {
        _fileName = fileName;
        _mProfiles = [NSMutableArray array];
    }
    return self;
}

- (NSArray<OARoutingDataObject *> *)profiles
{
    return [NSArray arrayWithArray:_mProfiles];
}

- (void)addProfile:(OARoutingDataObject *)profile
{
    [_mProfiles addObject:profile];
}

@end
