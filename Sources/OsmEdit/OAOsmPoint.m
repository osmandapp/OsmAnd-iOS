//
//  OAOsmPoint.m
//  OsmAnd
//
//  Created by Paul on 1/19/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmPoint.h"

@implementation OAOsmPoint
{
    EOAAction _action;
    EOAGroup _group;
    long _id;
    double _lat;
    double _lon;
}

-(id)init
{
    self = [super init];
    if (self) {
        _stringAction = @{[NSNumber numberWithInt:CREATE] : @"create",
                          [NSNumber numberWithInt:MODIFY] : @"modify",
                          [NSNumber numberWithInt:DELETE] : @"delete",
                          [NSNumber numberWithInt:REOPEN] : @"reopen"
                          };
        _actionString = @{
                          @"create" : [NSNumber numberWithInt:CREATE],
                          @"modify" : [NSNumber numberWithInt:MODIFY],
                          @"delete" : [NSNumber numberWithInt:DELETE],
                          @"reopen" : [NSNumber numberWithInt:REOPEN]
                          };
    }
    return self;
}

-(EOAAction) getAction
{
    return _action;
}

-(NSString *) getActionString
{
    return [_stringAction objectForKey:[NSNumber numberWithInt:_action]];
}

-(void)setActionString:(NSString *)action
{
    _action = _actionString[action].intValue;
}

-(void)setAction:(EOAAction)action
{
    _action = action;
}

-(NSString *) toNSString
{
    return [NSString stringWithFormat:@"Osm Point %@", [self getActionString]];
}

@end
