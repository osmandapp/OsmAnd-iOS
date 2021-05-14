//
//  OADownloadsItem.h
//  OsmAnd Maps
//
//  Created by Paul on 24.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASettingsItem.h"

NS_ASSUME_NONNULL_BEGIN

@class OAWorldRegion;

@interface OADownloadsItem : OASettingsItem

@property (nonatomic, readonly) NSArray<OAWorldRegion *> *items;

@end

NS_ASSUME_NONNULL_END
