//
//  OAProfileDataObject.m
//  OsmAnd
//
//  Created by Paul on 02.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileDataObject.h"

@implementation OAProfileDataObject

- (instancetype)initWithStringKey:(NSString *)stringKey name:(NSString *)name descr:(NSString *)descr iconName:(NSString *)iconName isSelected:(BOOL)isSelected
{
    self = [super init];
    if (self) {
        _stringKey = stringKey;
        _name = name;
        _descr = descr;
        _iconName = iconName;
        _isSelected = isSelected;
    }
    return self;
}

- (NSComparisonResult)compare:(OAProfileDataObject *)other
{
    return [_name compare:other.name];
}

@end
