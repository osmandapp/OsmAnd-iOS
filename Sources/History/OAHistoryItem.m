//
//  OAHistoryItem.m
//  OsmAnd
//
//  Created by Alexey Kulish on 05/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAHistoryItem.h"
#import "OADefaultFavorite.h"
#import "OAUtilities.h"
#import "OAPointDescription.h"

@implementation OAHistoryItem

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _hType = OAHistoryTypeUnknown;
    }
    return self;
}

- (instancetype)initWithPointDescription:(OAPointDescription *)pointDescription
{
    self = [super init];
    if (self)
    {
        if ([pointDescription isLocation])
        {
            _hType = OAHistoryTypeLocation;
        }
        else if ([pointDescription isPoi])
        {
            _hType = OAHistoryTypePOI;
        }
        else if ([pointDescription isWpt])
        {
            _hType = OAHistoryTypeWpt;
        }
        else if ([pointDescription isAddress])
        {
            _hType = OAHistoryTypeAddress;
        }
        else if ([pointDescription isParking])
        {
            _hType = OAHistoryTypeParking;
        }
        else if ([pointDescription isFavorite])
        {
            _hType = OAHistoryTypeFavorite;
        }
        else if ([pointDescription isDestination])
        {
            _hType = OAHistoryTypeDirection;
        }
        else
        {
            _hType = OAHistoryTypeUnknown;
        }
    }
    return self;
}

-(UIImage *)icon
{
    if (self.hType == OAHistoryTypeParking)
    {
        return [UIImage imageNamed:@"ic_parking_pin_small"];
    }
    else if (self.iconName.length > 0)
    {
        UIImage *img = [UIImage imageNamed:self.iconName];
        if (img)
        {
            if (self.hType == OAHistoryTypePOI)
            {
                return [OAUtilities applyScaleFactorToImage:img];
            }
            else
            {
                if (self.hType == OAHistoryTypeAddress)
                    return [OAUtilities getTintableImage:img];
                else
                    return img;
            }
        }
    }
    return [UIImage imageNamed:@"ic_map_pin_small"];
}

@end
