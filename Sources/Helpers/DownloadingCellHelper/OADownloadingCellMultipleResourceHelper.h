//
//  OADownloadingCellMultipleResourceHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 06/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

// Using for cells with round downloading indicator.
// For resouces cells with subitems like CountourLines.
// For regular resources use OADownloadingCellResourceHelper.

#import "OADownloadingCellResourceHelper.h"

@class OAMultipleResourceSwiftItem;

@interface OADownloadingCellMultipleResourceHelper : OADownloadingCellResourceHelper

- (NSString *) getResourceId:(OAMultipleResourceSwiftItem *)multipleItem;

@end
