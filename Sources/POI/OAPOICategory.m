//
//  OAPOICategory.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOICategory.h"

@implementation OAPOICategory

- (UIImage *)icon
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-hdpi/mx_%@", self.name]];
}

-(BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[OAPOICategory class]]) {
        OAPOICategory *obj = object;
        return [self.name isEqualToString:obj.name];
    }
    return NO;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OAPOICategory* clone = [[OAPOICategory allocWithZone:zone] init];
    
    clone.name = self.name;
    clone.tag = self.tag;
    clone.nameLocalized = self.nameLocalized;
    clone.nameLocalizedEN = self.nameLocalizedEN;
    
    return clone;
}

@end
