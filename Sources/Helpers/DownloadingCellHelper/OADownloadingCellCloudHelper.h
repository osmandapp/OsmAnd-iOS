//
//  OADownloadingCellCloudHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 08/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OADownloadingCellBaseHelper.h"

@interface OADownloadingCellCloudHelper : OADownloadingCellBaseHelper

- (NSString *) getResourceId:(NSString *)typeName filename:(NSString *)filename;

@end
