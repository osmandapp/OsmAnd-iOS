//
//  OABasePointEditingHandler.m
//  OsmAnd Maps
//
//  Created by Paul on 01.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABasePointEditingHandler.h"

@implementation OAPointEditingData

@end

@implementation OABasePointEditingHandler

- (UIColor *)getColor
{
    return nil; // override
}

- (NSString *)getGroupTitle
{
    return nil; // override
}

- (NSString *)getIcon
{
    return nil; //override
}

- (NSString *)getBackgroundIcon
{
    return nil; //override
}

- (NSString *)getName
{
    return nil; //override
}

- (BOOL)isSpecialPoint
{
    return NO;
}

- (void)deleteItem
{
    //override
}

- (NSDictionary *)checkDuplicates:(NSString *)name group:(NSString *)group
{
    return nil; //override
}

- (void)savePoint:(OAPointEditingData *)data newPoint:(BOOL)newPoint
{
    // override
}

+ (NSString *) getPoiIconName:(id)object
{
    NSString *preselectedIconName;
    if (object)
    {
        if ([object isKindOfClass:OAPOI.class])
        {
            OAPOI *poi = (OAPOI *)object;
            preselectedIconName = [self getPreselectedIconName:poi];
            preselectedIconName = [preselectedIconName stringByReplacingOccurrencesOfString:@"mx_" withString:@""];
        }
    }
    return preselectedIconName;
}

+ (NSString *) getPreselectedIconName:(OAPOI *)poi
{
    NSString *poiIcon = [poi.iconName lastPathComponent];
    NSString *preselectedIconName = ([self isExistsIcon:poiIcon]) ? poiIcon : [self getIconNameForPOI:poi];
    return preselectedIconName;
}

+ (NSString *) getIconNameForPOI:(OAPOI *)poi
{
    OAPOIType *poiType = poi.type;
    if (!poiType)
        return nil;
    else if ([self isExistsIcon:[NSString stringWithFormat:@"mx_%@", poiType.value]])
        return [NSString stringWithFormat:@"mx_%@", poiType.value];
    else if ([self isExistsIcon:[NSString stringWithFormat:@"mx_%@_%@", poiType.tag, poiType.value]])
        return [NSString stringWithFormat:@"mx_%@_%@", poiType.tag, poiType.value];
    return nil;
}

+ (BOOL) isExistsIcon:(NSString *)iconName
{
    NSString *path = [[NSBundle mainBundle] pathForResource:[@"poi-icons-png/drawable-xhdpi/" stringByAppendingPathComponent:iconName] ofType:@"png"];
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

@end
