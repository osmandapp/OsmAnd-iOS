//
//  OARemoteFile.m
//  OsmAnd Maps
//
//  Created by Paul on 19.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OARemoteFile.h"
#import "OABackupHelper.h"

@implementation OARemoteFile

- (instancetype) initWithJson:(NSDictionary *)json
{
    self = [super init];
    if (self)
    {
        if (json[@"userid"])
            _userid = [json[@"userid"] integerValue];
        if (json[@"id"])
            _identifier = [json[@"id"] longValue];
        if (json[@"deviceid"])
            _deviceid = [json[@"deviceid"] integerValue];
        if (json[@"filesize"])
            _filesize = [json[@"filesize"] integerValue];
        if (json[@"type"])
            _type = json[@"type"];
        if (json[@"name"])
            _name = json[@"name"];
        if (json[@"updatetimems"])
        {
            _updatetimems = [json[@"updatetimems"] longValue];
            _updatetime = [NSDate dateWithTimeIntervalSince1970:_updatetimems / 1000];
        }
        if (json[@"clienttimems"])
        {
            _clienttimems = [json[@"clienttimems"] longValue];
            _clienttime = [NSDate dateWithTimeIntervalSince1970:_clienttimems / 1000];
        }
        if (json[@"zipSize"])
            _zipSize = [json[@"zipSize"] integerValue];
    }
    return self;
}

- (BOOL) isDeleted
{
    return _filesize < 0;
}

- (BOOL) isInfoFile
{
    return _name != nil && [_name hasSuffix:OABackupHelper.INFO_EXT];
}

- (BOOL) isRecordedVoiceFile
{
//    return name != null
//    && name.startsWith(FileSettingsItem.FileSubtype.VOICE.getSubtypeFolder())
//    && !name.endsWith(IndexConstants.TTSVOICE_INDEX_EXT_JS);
    return  NO;
}

- (NSString *) getTypeNamePath
{
    if (_name.length > 0)
        return [NSString stringWithFormat:@"%@%@", _type, _name];
//        type + (name.charAt(0) == '/' ? name : "/" + name);
    else
        return _type;
}

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    if (object == nil || ![object isKindOfClass:self.class])
        return NO;
    
    OARemoteFile *that = (OARemoteFile *) object;
    return _identifier == that.identifier &&
    _userid == that.userid &&
    _deviceid == that.deviceid &&
    _filesize == that.filesize &&
    _updatetimems == that.updatetimems &&
    _clienttimems == that.clienttimems &&
    [_type isEqualToString:that.type] &&
    [_name isEqualToString:that.name] &&
    [_updatetime isEqual:that.updatetime] &&
    [_clienttime isEqual:that.clienttime];
}

- (NSUInteger) hash
{
    NSUInteger result = _identifier;
    result = 31 * result + _userid;
    result = 31 * result + _deviceid;
    result = 31 * result + _filesize;
    result = 31 * result + _updatetimems;
    result = 31 * result + _clienttimems;
    result = 31 * result + _type.hash;
    result = 31 * result + _name.hash;
    result = 31 * result + _updatetime.hash;
    result = 31 * result + _clienttime.hash;
    return result;
}

- (NSString *) toString
{
    return [NSString stringWithFormat:@"%@/%@ (%ld) clientTime=%ld updateTime=%ld", _type, _name, _filesize, _clienttimems, _updatetimems];
}

- (NSDictionary *) toJson
{
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    if (_userid != 0)
        res[@"userid"] = @(_userid).stringValue;
    if (_identifier != 0)
        res[@"id"] = @(_identifier).stringValue;
    if (_deviceid != 0)
        res[@"deviceid"] = @(_deviceid).stringValue;
    if (_filesize != 0)
        res[@"filesize"] = @(_filesize).stringValue;
    if (_type)
        res[@"type"] = _type;
    if (_name)
        res[@"name"] = _name;
    if (_updatetime)
    {
        res[@"updatetimems"] = @(_updatetimems).stringValue;
    }
    if (_clienttime)
    {
        res[@"clienttimems"] = @(_clienttimems).stringValue;
    }
    if (_zipSize > 0)
        res[@"zipSize"] = @(_zipSize).stringValue;
    
    return res;
}

// MARK: NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OARemoteFile* clone = [[OARemoteFile alloc] initWithJson:self.toJson];
    return clone;
}

@end
