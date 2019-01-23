//
//  OAEntityInfo.m
//  OsmAnd
//
//  Created by Paul on 1/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAEntityInfo.h"

@implementation OAEntityInfo
{
    NSString *_timestamp;
    NSString *_uid;
    NSString *_user;
    NSString *_visible;
    NSString *_version;
    NSString *_changeset;
    NSString *_action;
}

-(NSString *) getAction
{
    return _action;
}

-(void) setAction:(NSString *) action
{
    _action = action;
}

-(NSString *) getTimestamp
{
    return _timestamp;
}
-(void) setTimestamp:(NSString*) timestamp
{
    _timestamp = timestamp;
}

-(NSString *) getUid
{
    return _uid;
}

-(void) setUid:(NSString *) uid
{
    _uid = uid;
}

-(NSString *) getUser
{
    return _user;
}

-(void) setUser:(NSString *)user
{
    _user = user;
}

-(NSString *) getVisible
{
    return _visible;
}

-(void) setVisible:(NSString *)visible
{
    _visible = visible;
}

-(NSString *) getVersion
{
    return _version;
}

-(void) setVersion:(NSString *)version
{
    _version = version;
}

-(NSString *) getChangeset
{
    return _changeset;
}

-(void) setChangeset:(NSString *)changeset
{
    _changeset = changeset;
}

@end
