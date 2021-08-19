//
//  OASettingsItemWriter.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OASettingsItem;

NS_ASSUME_NONNULL_BEGIN

@interface OASettingsItemWriter<__covariant ObjectType : OASettingsItem *> : NSObject

@property (nonatomic, readonly) ObjectType item;

- (instancetype) initWithItem:(ObjectType)item;
- (BOOL) writeToFile:(NSString *)filePath error:(NSError * _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
