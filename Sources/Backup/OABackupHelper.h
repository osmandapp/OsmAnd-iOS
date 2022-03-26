//
//  OABackupHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 17.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define STATUS_SUCCESS 0
#define STATUS_PARSE_JSON_ERROR 1
#define STATUS_EMPTY_RESPONSE_ERROR 2
#define STATUS_SERVER_ERROR 3
#define STATUS_NO_ORDER_ID_ERROR 4
#define STATUS_EXECUTION_ERROR 5
#define STATUS_SERVER_TEMPORALLY_UNAVAILABLE_ERROR 6

#define SERVER_ERROR_CODE_EMAIL_IS_INVALID 101
#define SERVER_ERROR_CODE_NO_VALID_SUBSCRIPTION 102
#define SERVER_ERROR_CODE_USER_IS_NOT_REGISTERED 103
#define SERVER_ERROR_CODE_TOKEN_IS_NOT_VALID_OR_EXPIRED 104
#define SERVER_ERROR_CODE_PROVIDED_TOKEN_IS_NOT_VALID 105
#define SERVER_ERROR_CODE_FILE_NOT_AVAILABLE 106
#define SERVER_ERROR_CODE_GZIP_ONLY_SUPPORTED_UPLOAD 107
#define SERVER_ERROR_CODE_SIZE_OF_SUPPORTED_BOX_IS_EXCEEDED 108
#define SERVER_ERROR_CODE_SUBSCRIPTION_WAS_USED_FOR_ANOTHER_ACCOUNT 109
#define SERVER_ERROR_CODE_SUBSCRIPTION_WAS_EXPIRED_OR_NOT_PRESENT 110
#define SERVER_ERROR_CODE_USER_IS_ALREADY_REGISTERED 111

@class OAExportSettingsType, OACommonBoolean, OAPrepareBackupResult, OABackupListeners;

@interface OABackupHelper : NSObject

@property (nonatomic, readonly) OAPrepareBackupResult *backup;
@property (nonatomic, readonly) OABackupListeners *backupListeners;

+ (NSString *) INFO_EXT;

+ (NSString *) USER_REGISTER_URL;
+ (NSString *) DEVICE_REGISTER_URL;

+ (OABackupHelper *)sharedInstance;

- (OACommonBoolean *) getBackupTypePref:(OAExportSettingsType *)type;
- (OACommonBoolean *) getVersionHistoryTypePref:(OAExportSettingsType *)type;

- (NSString *) getOrderId;
- (NSString *) getIosId;
- (NSString *) getAccessToken;
- (NSString *) getEmail;
- (BOOL) isRegistered;

@end

NS_ASSUME_NONNULL_END
