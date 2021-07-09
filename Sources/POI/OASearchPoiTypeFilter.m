//
//  OASearchPoiTypeFilter.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OASearchPoiTypeFilter.h"
#import "OAPOICategory.h"

@implementation OASearchPoiTypeFilter

- (BOOL) accept:(OAPOICategory *)type subcategory:(NSString *)subcategory
{
    if (_acceptFunction)
        return _acceptFunction(type, subcategory);
    
    return NO;
}

- (BOOL) isEmpty
{
    if (_emptyFunction)
        return _emptyFunction();
    
    return NO;
}

- (instancetype)initWithAcceptFunc:(OASearchPoiTypeFilterAccept)aFunction emptyFunction:(OASearchPoiTypeFilterIsEmpty)eFunction getTypesFunction:(OASearchPoiTypeFilterGetTypes)tFunction;
{
    self = [super init];
    if (self) {
        _acceptFunction = aFunction;
        _emptyFunction = eFunction;
        _getAcceptedTypesFunction = tFunction;
    }
    return self;
}

- (NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *) getAcceptedTypes
{
    if (_getAcceptedTypesFunction)
        return _getAcceptedTypesFunction();

    return nil;
}

- (NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *) getAcceptedTypesOrigin
{
    if (_getAcceptedTypesFunction)
        return _getAcceptedTypesFunction();

    return nil;
}

@end
