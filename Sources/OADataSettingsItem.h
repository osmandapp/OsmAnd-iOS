//
//  OADataSettingsItem.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsItem.h"
#import "OASettingsItemReader.h"
#import "OASettingsItemWriter.h"

@interface OADataSettingsItem : OASettingsItem

@property (nonatomic) NSData *data;

- (instancetype) initWithName:(NSString *)name;
- (instancetype) initWithData:(NSData *)data name:(NSString *)name;

@end

@interface OADataSettingsItemReader : OASettingsItemReader<OADataSettingsItem *>

@end

@interface OADataSettingsItemWriter : OASettingsItemWriter<OADataSettingsItem *>

@end

