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
        if (self.hType == OAHistoryTypeFavorite)
        {
            UIImage *img = [UIImage imageNamed:self.iconName];
            if (img)
                return img;
        }
        else
        {
            UIImage *img = [UIImage imageNamed:self.iconName];
            if (img)
                return [OAUtilities applyScaleFactorToImage:img];
        }
    }
    return [UIImage imageNamed:@"ic_map_pin_small"];
}

@end
