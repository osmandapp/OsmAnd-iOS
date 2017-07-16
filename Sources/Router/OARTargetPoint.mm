//
//  OARTargetPoint.m
//  OsmAnd
//
//  Created by Alexey Kulish on 16/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARTargetPoint.h"
#import "OAPointDescription.h"
#import "Localization.h"

@implementation OARTargetPoint

- (instancetype) initWithPoint:(CLLocation *)point name:(OAPointDescription *)name
{
    self = [super init];
    if (self)
    {
        _point = point;
        _pointDescription = name;
    }
    return self;
}

- (instancetype) initWithPoint:(CLLocation *)point name:(OAPointDescription *)name index:(int)index
{
    self = [super init];
    if (self)
    {
        _point = point;
        _pointDescription = name;
        _index = index;
        _intermediate = YES;
    }
    return self;
}

- (BOOL) isEqual:(id)o
{
    if (self == o)
        return YES;
    if (!o || ![self isKindOfClass:[o class]])
        return NO;
    
    OARTargetPoint *targetPoint = (OARTargetPoint *) o;
    
    if (self.start != targetPoint.start)
        return NO;
    if (self.intermediate != targetPoint.intermediate)
        return NO;
    if (self.index != targetPoint.index)
        return NO;
    
    return [self.point isEqual:targetPoint.point];
}

- (NSUInteger) hash
{
    NSUInteger result = self.point.hash;
    result = 31 * result + self.index;
    result = 31 * result + (self.start ? 10 : 20);
    result = 31 * result + (self.intermediate ? 100 : 200);
    return result;
}

- (OAPointDescription *) getOriginalPointDescription
{
    return self.pointDescription;
}

- (double) getLatitude
{
    return self.point.coordinate.latitude;
}

- (double) getLongitude
{
    return self.point.coordinate.longitude;
}

- (UIColor *) getColor
{
    return nil;
}

- (BOOL) isVisible
{
    return NO;
}

- (NSString *) getOnlyName
{
    return !self.pointDescription ? @"" : self.pointDescription.name;
}

- (OAPointDescription *) getPointDescription
{
    if (!self.intermediate)
    {
        return [[OAPointDescription alloc] initWithType:POINT_TYPE_TARGET typeName:[NSString stringWithFormat:OALocalizedString(@"destination_point"), @""] name:[self getOnlyName]];
    }
    else
    {
        NSString *s = [NSString stringWithFormat:OALocalizedString(@"intermediate_point"), @""];
        return [[OAPointDescription alloc] initWithType:POINT_TYPE_TARGET typeName:[NSString stringWithFormat:@"%d. %@", (self.index + 1), s] name:[self getOnlyName]];
    }
}

- (BOOL) isSearchingAddress
{
    return self.pointDescription && [self.pointDescription isSearchingAddress];
}

+ (OARTargetPoint *) create:(CLLocation *)point name:(OAPointDescription *)name
{
    if (point)
        return [[OARTargetPoint alloc] initWithPoint:point name:name];
    
    return nil;
}

+ (OARTargetPoint *) createStartPoint:(CLLocation *)point name:(OAPointDescription *)name
{
    if (point)
    {
        OARTargetPoint *target = [[OARTargetPoint alloc] initWithPoint:point name:name];
        target.start = YES;
        return target;
    }
    return nil;
}

#pragma mark - NSCoding

#define kPoint @"point"
#define kPointDescription @"pointDescription"
#define kIndex @"index"
#define kIntermediate @"intermediate"
#define kStart @"start"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_point forKey:kPoint];
    [aCoder encodeObject:[OAPointDescription serializeToString:_pointDescription] forKey:kPointDescription];
    [aCoder encodeObject:[NSNumber numberWithInt:_index] forKey:kIndex];
    [aCoder encodeObject:[NSNumber numberWithBool:_intermediate] forKey:kIntermediate];
    [aCoder encodeObject:[NSNumber numberWithBool:_start] forKey:kStart];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _point = [aDecoder decodeObjectOfClass:[CLLocation class] forKey:kPoint];
        NSString *pointDescriptionStr = [aDecoder decodeObjectOfClass:[NSString class] forKey:kPointDescription];
        if (pointDescriptionStr)
            _pointDescription = [OAPointDescription deserializeFromString:pointDescriptionStr l:_point];
        
        _index = [[aDecoder decodeObjectForKey:kIndex] intValue];
        _intermediate = [[aDecoder decodeObjectForKey:kIntermediate] boolValue];
        _start = [[aDecoder decodeObjectForKey:kStart] boolValue];
    }
    return self;
}

@end
