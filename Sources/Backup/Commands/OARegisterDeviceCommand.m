//
//  OARegisterDeviceCommand.m
//  OsmAnd Maps
//
//  Created by Paul on 25.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OARegisterDeviceCommand.h"
#import "OABackupListeners.h"
#import "OABackupHelper.h"
#import "OABackupError.h"
#import "OANetworkUtilities.h"
#import "OAAppSettings.h"

#define kUserOperation @"Register device"

@implementation OARegisterDeviceCommand
{
    NSString *_token;
}

- (instancetype) initWithToken:(NSString *)token
{
    self = [super init];
    if (self) {
        _token = token;
    }
    return self;
}

- (NSArray<id<OAOnRegisterDeviceListener>> *) getListeners
{
    return OABackupHelper.sharedInstance.backupListeners.getRegisterDeviceListeners;
}

- (void) main
{
    OABackupHelper *backupHelper = OABackupHelper.sharedInstance;
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    params[@"email"] = backupHelper.getEmail;
    NSString *orderId = backupHelper.getOrderId;
    if (orderId)
        params[@"orderid"] = orderId;
    NSString *deviceId = backupHelper.getIosId;
    if (deviceId.length > 0)
        params[@"deviceid"] = deviceId;
    params[@"token"] = _token;
    [OANetworkUtilities sendRequestWithUrl:OABackupHelper.DEVICE_REGISTER_URL params:params post:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        int status;
        NSString *message;
        OABackupError *backupError = nil;
        NSString *result = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
        NSString *err = result;
        NSInteger responseCode = ((NSHTTPURLResponse *)response).statusCode;
        if ([self isTemporallyUnavailableErrorCode:responseCode])
        {
            message = [NSString stringWithFormat:@"Device registration error code: %ld", responseCode];
            err = [NSString stringWithFormat:@"{\"error\":{\"errorCode\":%d,\"message\":\"%@\"}}", STATUS_SERVER_TEMPORALLY_UNAVAILABLE_ERROR, message];
        }
        
        if (responseCode != 200 && err.length > 0)
        {
            backupError = [[OABackupError alloc] initWithError:err];
            message = [NSString stringWithFormat:@"Device registration error: %@", backupError.toString];
            status = STATUS_SERVER_ERROR;
        }
        else if (result.length > 0)
        {
            OAAppSettings *settings = OAAppSettings.sharedManager;
            NSError *jsonParsingError = nil;
            NSDictionary *resultJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonParsingError];
            if (!jsonParsingError)
            {
                [settings.backupDeviceId set:[resultJson[@"id"] stringValue]];
                [settings.backupUserId set:[resultJson[@"userid"] stringValue]];
                [settings.backupNativeDeviceId set:resultJson[@"deviceid"]];
                [settings.backupAccessToken set:resultJson[@"accesstoken"]];
                [settings.backupAccessTokenUpdateTime set:resultJson[@"udpatetime"]];
                
                message = @"Device have been registered successfully";
                status = STATUS_SUCCESS;
            }
            else
            {
                message = @"Device registration error: json parsing";
                status = STATUS_PARSE_JSON_ERROR;
            }
        }
        else
        {
            message = @"Device registration error: empty response";
            status = STATUS_EMPTY_RESPONSE_ERROR;
        }
        [self onProgressUpdate:status message:message error:backupError];
//        operationLog.finishOperation(status + " " + message);
    }];
}

- (void) onProgressUpdate:(NSInteger)status message:(NSString *)message error:(OABackupError *)error
{
    for (id<OAOnRegisterDeviceListener> listener in [self getListeners])
    {
        [listener onRegisterDevice:status message:message error:error];
    }
}

- (BOOL) isTemporallyUnavailableErrorCode:(NSInteger)code
{
    return code == 404 || (code >= 500 && code < 600);
}

@end
