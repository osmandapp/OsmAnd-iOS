//
//  OAPOIFilter.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIFilter.h"

@implementation OAPOIFilter

- (UIImage *)icon
{
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-hdpi/mx_%@", self.name]];
    if (!img)
        img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-hdpi/mx_%@", self.category]];
    
    return img;
}

-(BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[OAPOIFilter class]]) {
        OAPOIFilter *obj = object;
        return [self.name isEqualToString:obj.name];
    }
    return NO;
}

-(NSUInteger)hash
{
    return [_name hash] + (_category ? [_category hash] : 1);
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OAPOIFilter* clone = [[OAPOIFilter allocWithZone:zone] init];
    
    clone.name = self.name;
    clone.nameLocalized = self.nameLocalized;
    clone.nameLocalizedEN = self.nameLocalizedEN;

    clone.category = self.category;
    clone.categoryLocalized = self.categoryLocalized;
    clone.categoryLocalizedEN = self.categoryLocalizedEN;
    
    return clone;
}

@end
