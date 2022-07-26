//
//  OASettingsItemWriter.m
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsItemWriter.h"

@interface OASettingsItemWriter<__covariant ObjectType : OASettingsItem *>()

@property (nonatomic) ObjectType item;

@end

@implementation OASettingsItemWriter

- (instancetype) initWithItem:(id)item
{
    _item = item;
    return self;
}

- (BOOL) writeToFile:(NSString *)filePath error:(NSError * _Nullable *)error
{
    return NO;
}

@end
