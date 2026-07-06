//
//  OAFavoriteFolderBridgeItem.m
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAFavoriteFolderBridgeItem.h"
#import "OAFavoritesHelper.h"

@implementation OAFavoriteFolderBridgeItem

- (instancetype)initWithGroup:(OAFavoriteGroup *)group index:(NSUInteger)index lastModifiedDate:(nullable NSDate *)lastModifiedDate fileSize:(long long)fileSize subtreePointsCount:(NSUInteger)subtreePointsCount
{
    self = [super init];
    if (self)
    {
        NSString *groupName = group.name;
        _identifier = [NSString stringWithFormat:@"%@-%lu", groupName, (unsigned long)index];
        _groupName = groupName;
        _title = [self.class titleForGroupName:groupName];
        _pointsCount = group.points.count;
        _subtreePointsCount = subtreePointsCount;
        _isVisible = group.isVisible;
        _isPinned = group.isPinned;
        _color = group.color;
        _lastModifiedDate = lastModifiedDate;
        _fileSize = fileSize;
    }

    return self;
}

+ (NSString *)titleForGroupName:(NSString *)groupName
{
    NSString *lastComponent = [[groupName componentsSeparatedByString:@"/"] lastObject] ?: groupName;
    return [OAFavoriteGroup getDisplayName:lastComponent] ?: lastComponent;
}

@end
