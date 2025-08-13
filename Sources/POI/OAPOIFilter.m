//
//  OAPOIFilter.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOIFilter.h"
#import "OAUtilities.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAAppSettings.h"

@implementation OAPOIFilter

- (instancetype)initWithName:(NSString *)name category:(OAPOICategory *)category;
{
    self = [super initWithName:name];
    if (self)
    {
        _category = category;
    }
    return self;
}

- (UIImage *)icon
{
    UIImage *img = [super icon];
    if (!img)
        img = [UIImage mapSvgImageNamed:[NSString stringWithFormat:@"mx_%@", self.category.name]];

    return img;
}

-(BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[OAPOIFilter class]])
    {
        OAPOIFilter *obj = object;
        return [self.name isEqualToString:obj.name];
    }
    return NO;
}

-(NSUInteger)hash
{
    return [self.name hash] + (self.category ? [self.category hash] : 1);
}

- (void)addPoiType:(OAPOIType *)poiType
{
    if ([[OAAppSettings sharedManager] isTypeDisabled:poiType.name])
        return;

    if (!_poiTypes)
    {
        _poiTypes = @[poiType];
    }
    else
    {
        _poiTypes = [_poiTypes arrayByAddingObject:poiType];
    }
}

-(NSMapTable<OAPOICategory *,NSMutableSet<NSString *> *> *)putTypes:(NSMapTable<OAPOICategory *,NSMutableSet<NSString *> *> *)acceptedTypes
{
    if (![acceptedTypes objectForKey:self.category])
        [acceptedTypes setObject:[NSMutableSet set] forKey:self.category];

    NSMutableSet<NSString *> *set = [acceptedTypes objectForKey:self.category];
    for (OAPOIType *pt in _poiTypes)
    {
        [set addObject:pt.name];
    }
    [OAPOICategory addReferenceTypes:self.poiTypes acceptedTypes:acceptedTypes];
    return acceptedTypes;
}

@end
