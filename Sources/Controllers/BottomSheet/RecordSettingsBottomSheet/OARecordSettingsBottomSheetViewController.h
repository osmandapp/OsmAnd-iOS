//
//  OARecordSettingsBottomSheetViewController.h
//  OsmAnd
//
//  Created by nnngrach on 15.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

typedef void(^OARecordSettingsBottomSheetCompletionBlock)(int recordingInterval, BOOL rememberChoice, BOOL showOnMap);

@interface OARecordSettingsBottomSheetViewController : OABaseBottomSheetViewController

- (instancetype) initWithCompletitionBlock:(OARecordSettingsBottomSheetCompletionBlock)completitionBlock;

@end
