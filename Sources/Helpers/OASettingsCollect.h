//
//  OASettingsCollect.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 04.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OASettingsHelper.h"

@protocol OASettingsCollectDelegate <NSObject>

- (void) onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *>*)items;

@end

@interface OASettingsCollect : NSObject

@end
