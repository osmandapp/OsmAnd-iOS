//
//  OASettingsImport.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 04.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

@class OASettingsItem;

@protocol OASettingsImportDelegate <NSObject>

- (void) onSettingsImportFinished:(BOOL)succeed items:(NSMutableArray<OASettingsItem *>*)items;

@end


@interface OASettingsImport : NSObject


@end
