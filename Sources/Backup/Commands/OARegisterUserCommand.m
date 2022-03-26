//
//  OARegisterUserCommand.m
//  OsmAnd Maps
//
//  Created by Paul on 24.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OARegisterUserCommand.h"
#import "OABackupHelper.h"
#import "OABackupError.h"
#import "OABackupListeners.h"
#import "OANetworkUtilities.h"
#import "OsmAndApp.h"

#define kUserOperation @"Register user"

@implementation OARegisterUserCommand
{
    BOOL _login;
    NSString *_email;
    NSString *_promoCode;
}

- (instancetype) initWithEmail:(NSString *)email promoCode:(NSString *)promoCode login:(BOOL)login
{
    self = [super init];
    if (self) {
        _email = email;
        _promoCode = promoCode;
        _login = login;
    }
    return self;
}

- (NSArray<id<OAOnRegisterUserListener>> *) getListeners
{
    return OABackupHelper.sharedInstance.backupListeners.getRegisterUserListeners;
}

- (void) main
{
    OABackupHelper *backupHelper = OABackupHelper.sharedInstance;
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    params[@"email"] = _email;
    params[@"login"] = _login ? @"true" : @"false";
    NSString *orderId = _promoCode.length == 0 ? backupHelper.getOrderId : _promoCode;
    if (orderId && orderId.length > 0)
        params[@"orderId"] = orderId;
    NSString *deviceId = OsmAndApp.instance.getUserIosId;
    params[@"deviceId"] = deviceId;
    [OANetworkUtilities sendRequestWithUrl:OABackupHelper.USER_REGISTER_URL params:params post:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        int status;
        NSString *message;
        OABackupError *backupError = nil;
        NSString *result = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
        if (((NSHTTPURLResponse *)response).statusCode != 200)
        {
            NSString *err = [NSString stringWithFormat:@"%@ failed: %@", kUserOperation, result];
            backupError = [[OABackupError alloc] initWithError:err];
            message = [NSString stringWithFormat:@"User registration error: %@\nEmail=%@\nOrderId=%@\nDeviceId=%@", backupError.toString, _email, orderId, deviceId];
            status = STATUS_SERVER_ERROR;
        }
        else if (result.length > 0)
        {
            NSError *jsonParsingError = nil;
            NSDictionary *resultJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonParsingError];
            if (!jsonParsingError)
            {
                if (resultJson[@"status"] && [@"ok" isEqualToString:resultJson[@"status"]])
                {
                    message = @"You have been registered successfully. Please check for email with activation code.";
                    status = STATUS_SUCCESS;
                }
                else
                {
                    message = @"User registration error: unknown";
                    status = STATUS_SERVER_ERROR;
                }
            }
            else
            {
                message = @"User registration error: json parsing";
                status = STATUS_PARSE_JSON_ERROR;
            }
            
        }
        else
        {
            message = @"User registration error: empty response";
            status = STATUS_EMPTY_RESPONSE_ERROR;
        }
        [self onProgressUpdate:status message:message error:backupError];
//        operationLog.finishOperation(status + " " + message);
    }];
}

- (void) onProgressUpdate:(NSInteger)status message:(NSString *)message error:(OABackupError *)error
{
    for (id<OAOnRegisterUserListener> listener in [self getListeners])
    {
        [listener onRegisterUser:status message:message error:error];
    }
}

@end
