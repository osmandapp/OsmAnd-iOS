//
//  OAOsmPoint.m
//  OsmAnd
//
//  Created by Paul on 1/19/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmPoint.h"
#import "Localization.h"

@implementation OAOsmPoint
{
    EOAAction _action;
    EOAGroup _group;
    long _id;
    double _lat;
    double _lon;
}

+ (NSDictionary<NSNumber *, NSString *> *)getStringAction
{
    static NSDictionary<NSNumber *, NSString *> *stringAction = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stringAction = @{[NSNumber numberWithInt:CREATE] : @"create",
                          [NSNumber numberWithInt:MODIFY] : @"modify",
                          [NSNumber numberWithInt:DELETE] : @"delete",
                          [NSNumber numberWithInt:REOPEN] : @"reopen"
                          };
    });
    return stringAction;
}

+ (NSDictionary<NSString *, NSNumber *> *)getActionString
{
    static NSDictionary<NSString *, NSNumber *> *actionString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        actionString = @{
                         @"create" : [NSNumber numberWithInt:CREATE],
                         @"modify" : [NSNumber numberWithInt:MODIFY],
                         @"delete" : [NSNumber numberWithInt:DELETE],
                         @"reopen" : [NSNumber numberWithInt:REOPEN]
                         };
    });
    return actionString;
}

-(EOAAction) getAction
{
    return _action;
}

-(NSString *) getActionString
{
    return [[self.class getStringAction] objectForKey:[NSNumber numberWithInt:_action]];
}

-(void)setActionString:(NSString *)action
{
    _action = [self.class getActionString][action].intValue;
}

-(void)setAction:(EOAAction)action
{
    _action = action;
}

-(NSString *) toNSString
{
    return [NSString stringWithFormat:@"Osm Point %@", [self getActionString]];
}

- (EOAGroup)getGroup {
    return UNDETERMINED;
}

- (NSString *)getLocalizedAction
{
    switch (_action) {
        case CREATE:
            return OALocalizedString(@"osm_created");
        case DELETE:
            return OALocalizedString(@"osm_deleted");
        case MODIFY:
            return OALocalizedString(@"osm_modified");
        case REOPEN:
            return OALocalizedString(@"osm_reopened");
        default:
            return @"";
    }
}


- (long long)getId {
    return 0;
}


- (double)getLatitude {
    return -1;
}


- (double)getLongitude {
    return -1;
}

-(NSString *)getSubType
{
    return nil;
}

-(NSDictionary<NSString *, NSString *> *)getTags
{
    return [NSDictionary new];
}

-(NSString *)getName
{
    return @"";
}


@end
