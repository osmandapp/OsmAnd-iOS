//
//  OASettingsItemReader.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OASettingsItem;

NS_ASSUME_NONNULL_BEGIN

@interface OASettingsItemReader<__covariant ObjectType : OASettingsItem *> : NSObject

@property (nonatomic, readonly) ObjectType item;

- (instancetype) initWithItem:(ObjectType)item;
- (BOOL) readFromFile:(NSString *)filePath error:(NSError * _Nullable *)error;

+ (void) performPreferenceWrites:(void (^)(void))writes;

@end

NS_ASSUME_NONNULL_END
