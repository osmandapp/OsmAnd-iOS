//
//  OASettingsExport.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 04.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

@protocol OASettingsExportDelegate <NSObject>

- (void) onSettingsExportFinished:(NSString*)file succeed:(BOOL)succeed;

@end

@interface OASettingsExport : NSObject


@end
