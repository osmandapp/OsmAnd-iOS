//
//  OAPOICategory.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOICategory.h"
#import "OAUtilities.h"

@implementation OAPOICategory

- (UIImage *)icon
{
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/mx_%@", [OAUtilities drawablePostfix], self.name]];

    return [OAUtilities applyScaleFactorToImage:img];
}

-(BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[OAPOICategory class]]) {
        OAPOICategory *obj = object;
        return [self.name isEqualToString:obj.name];
    }
    return NO;
}

-(NSUInteger)hash
{
    return [_name hash] + (_tag ? [_tag hash] : 1);
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OAPOICategory* clone = [[OAPOICategory allocWithZone:zone] init];
    
    clone.name = self.name;
    clone.tag = self.tag;
    clone.top = self.top;
    clone.nameLocalized = self.nameLocalized;
    clone.nameLocalizedEN = self.nameLocalizedEN;
    
    return clone;
}

@end
