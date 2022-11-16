//
//  OACloudBackupViewController.h
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 19.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseCloudBackupViewController.h"
#import "OASettingsItem.h"

typedef NS_ENUM(NSInteger, EOACloudScreenSourceType) {
    EOACloudScreenSourceTypeSignIn = 0,
    EOACloudScreenSourceTypeSignUp,
    EOACloudScreenSourceTypeDirect
};

@class OATableRowData;

@protocol OAStatusBackupDelegate

- (void)setRowIcon:(OATableRowData *)rowData item:(OASettingsItem *)item;
- (NSString *)getDescriptionForItemType:(EOASettingsItemType)type fileName:(NSString *)fileName summary:(NSString *)summary;
- (NSString *)generateTimeString:(long)timeMs summary:(NSString *)summary;

@end

@interface OACloudBackupViewController : OABaseCloudBackupViewController

- (instancetype) initWithSourceType:(EOACloudScreenSourceType)type;

@end

