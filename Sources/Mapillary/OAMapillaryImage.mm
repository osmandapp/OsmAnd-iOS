//
//  OAMapillaryImage.m
//  OsmAnd
//
//  Created by Alexey on 20/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapillaryImage.h"

@implementation OAMapillaryImage

- (instancetype) initWithLatitude:(double)latitude longitude:(double)longitude
{
    self = [super init];
    if (self) {
        _latitude = latitude;
        _longitude = longitude;
    }
    return self;
}

- (instancetype) initWithDictionary:(NSDictionary *)values
{
    self = [super init];
    if (self) {
        for (NSString *key in values.allKeys)
        {
            BOOL isLat = [key isEqualToString:@"lat"];
            BOOL isLon = [key isEqualToString:@"lon"];
            BOOL isCA = [key isEqualToString:@"ca"];
            if (isLat || isLon || isCA)
            {
                NSNumber *num = values[key];
                double val = num.doubleValue;
                if (isLat)
                    _latitude = val;
                else if (isLon)
                    _longitude = val;
                else
                    _ca = val;
            }
            else if ([key isEqualToString:@"key"])
                _key = values[key];
        }
    }
    return self;
}

- (BOOL) setData:(QHash<uint8_t, QVariant>)data geometryTile:(const std::shared_ptr<const OsmAnd::MvtReader::Tile>&)geometryTile
{
    BOOL res = YES;
    @try {
        _ca = data[OsmAnd::MvtReader::getUserDataId("ca")].toDouble();
        _capturedAt = data[OsmAnd::MvtReader::getUserDataId("captured_at")].toUInt();
        _key = data[OsmAnd::MvtReader::getUserDataId("key")].toString().toNSString();
        _pano = data[OsmAnd::MvtReader::getUserDataId("pano")].toInt() == 1;
        _sKey = geometryTile->getSequenceKey(data[OsmAnd::MvtReader::getUserDataId("skey")].toInt()).toNSString();
        _userKey = geometryTile->getUserKey(data[OsmAnd::MvtReader::getUserDataId("userkey")].toInt()).toNSString();
    }
    @catch (NSException * e) {
        res = NO;
    }

    return res && self.key;
}

@end
