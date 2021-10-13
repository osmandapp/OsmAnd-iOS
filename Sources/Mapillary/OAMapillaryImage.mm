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
                    _compassAngle = val;
            }
            else if ([key isEqualToString:@"key"])
                _imageId = values[key];
        }
    }
    return self;
}

- (BOOL) setData:(QHash<uint8_t, QVariant>)data geometryTile:(const std::shared_ptr<const OsmAnd::MvtReader::Tile>&)geometryTile
{
    BOOL res = YES;
    @try {
        _capturedAt = data[OsmAnd::MvtReader::getUserDataId(kCapturedAtKey)].toUInt();
        _compassAngle = data[OsmAnd::MvtReader::getUserDataId(kCompassAngleKey)].toDouble();
        _imageId = data[OsmAnd::MvtReader::getUserDataId(kImageIdKey)].toString().toNSString();
        _sequenceId = geometryTile->getSequenceKey(data[OsmAnd::MvtReader::getUserDataId(kSequenceIdKey)].toInt()).toNSString();
        if (data.contains(OsmAnd::MvtReader::getUserDataId(kOrganizationIdKey)))
            _organizationId = geometryTile->getUserKey(data[OsmAnd::MvtReader::getUserDataId(kOrganizationIdKey)].toInt()).toNSString();
        _panoramicImage = data[OsmAnd::MvtReader::getUserDataId(kIsPanoramiceKey)].toBool();
    }
    @catch (NSException * e) {
        res = NO;
    }

    return res && self.imageId;
}

@end
