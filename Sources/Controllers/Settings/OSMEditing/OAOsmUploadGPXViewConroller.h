//
//  OAOsmUploadGPXViewConroller.h
//  OsmAnd
//
//  Created by nnngrach on 31.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseBigTitleSettingsViewController.h"
#import "OAOsmUploadGPXVisibilityViewConroller.h"
#import "OAGPXDatabase.h"

@interface OAOsmUploadGPXViewConroller : OABaseBigTitleSettingsViewController

- (instancetype)initWithGPXItems:(NSArray<OAGPX *> *)gpxItemsToUpload;

@end
