//
//  OAGpxSettingsItem.h
//  OsmAnd
//
//  Created by Anna Bibyk on 29.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAFileSettingsItem.h"

@class OAGpxAppearanceInfo;

@interface OAGpxSettingsItem : OAFileSettingsItem

- (OAGpxAppearanceInfo *) getAppearanceInfo;

@end
