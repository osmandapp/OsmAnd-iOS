//
//  OAClickableWayHelper.mm
//  OsmAnd
//
//  Created by Max Kojin on 07/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAClickableWayHelper.h"
#import "OAClickableWayHelper+cpp.h"
#import "OARenderedObject.h"
#import "OAClickableWay.h"

#include <OsmAndCore/Data/ObfMapObject.h>

@implementation OAClickableWayHelper
{
    NSSet<NSString *> *_clickableTags;
    NSDictionary<NSString *, NSString *> *_forbiddenTags;
    NSSet<NSString *> *_requiredTagsAny;
    NSDictionary<NSString *, NSString *> *_gpxColors;
    
    id _activator;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _clickableTags = [NSSet setWithArray:@[
        @"piste:type",
        @"piste:difficulty",
        @"mtb:scale",
        @"dirtbike:scale"
    ]];
    
    _requiredTagsAny = [NSSet setWithArray:@[
        @"name",
        @"ref",
        @"piste:name",
        @"mtb:name"
    ]];
    
    _forbiddenTags = @{
        @"area": @"yes",
        @"access": @"no",
        @"aerialway": @"*"
    };
    _gpxColors = @{
        @"0": @"brown",
        @"1": @"green",
        @"2": @"blue",
        @"3": @"red",
        @"4": @"black",
        @"5": @"black",
        @"6": @"black",
        @"novice": @"green",
        @"easy": @"blue",
        @"intermediate": @"red",
        @"advanced": @"black",
        @"expert": @"black",
        @"freeride": @"yellow"
        // others are default (red)
    };
    
    //TODO: implement
    //this.activator = new ClickableWayMenuProvider(view, this::readHeightData, this::openAsGpxFile);
    
    _activator = nil;
}

- (id) getContextMenuProvider
{
    return _activator;
}

- (BOOL) isClickableWay:(OARenderedObject *)renderedObject
{
    return renderedObject.x.count > 1 && [self isClickableWayTags:renderedObject.tags]; // v1
}

- (BOOL) isClickableWay:(const std::shared_ptr<const OsmAnd::MapObject>)obfMapObject tags:(NSDictionary<NSString *, NSString *> *)tags
{
    return obfMapObject->points31.size() > 1 && [self isClickableWayTags:tags]; // v2 with prefetched tags
}

- (OAClickableWay *) loadClickableWay:(CLLocation *)selectedLatLon obfMapObject:(const std::shared_ptr<const OsmAnd::MapObject>)obfMapObject tags:(NSDictionary<NSString *, NSString *> *)tags
{
    // TODO: Implement
    
    return nil;
}

- (BOOL) isClickableWayTags:(NSDictionary<NSString *, NSString *> *)tags
{
    for (NSString *forbiddenKey in _forbiddenTags)
    {
        NSString *forbiddenValue = _forbiddenTags[forbiddenKey];
        NSString *tagValue = tags[forbiddenKey];
        if ([forbiddenValue isEqualToString:tagValue] ||
            ([@"*" isEqualToString:forbiddenValue] && tagValue))
        {
            return  NO;
        }
    }
    
    for (NSString *required in _requiredTagsAny)
    {
        if (tags[required])
        {
            for (NSString *key in tags)
            {
                if ([_clickableTags containsObject:key])
                    return YES;
            }
        }
    }
    return NO;
}

@end
