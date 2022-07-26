//
//  OAAbstractWriter.h
//  OsmAnd Maps
//
//  Created by Paul on 07.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OASettingsItem;

@interface OAAbstractWriter : NSObject

- (BOOL) isCancelled;
- (void) cancel;
- (void) write:(OASettingsItem *)item;

@end

NS_ASSUME_NONNULL_END
