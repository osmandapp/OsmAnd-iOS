//
//  OAImportExportSettingsConverter.h
//  OsmAnd
//
//  Created by Paul on 13.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAAppSettings.h"

@interface OAImportExportSettingsConverter : NSObject

+ (NSString *) rulerWidgetModeToString:(EOARulerWidgetMode)rulerMode;
+ (NSString *) booleanPreferenceToString:(BOOL)pref;
+ (NSString *) arrayPreferenceToString:(NSArray *)pref;

@end
