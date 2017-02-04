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
