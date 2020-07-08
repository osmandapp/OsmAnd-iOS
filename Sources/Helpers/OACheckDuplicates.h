//
//  OACheckDuplicates.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 04.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsHelper.h"

@protocol OACheckDuplicatesDelegate <NSObject>

- (void) onDuplicatesChecked:(NSMutableArray<OASettingsItem *>*)duplicates items:(NSMutableArray<OASettingsItem *>*)items;

@end

@interface OACheckDuplicates : NSObject


@end
