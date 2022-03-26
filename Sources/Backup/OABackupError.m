//
//  OABackupError.m
//  OsmAnd Maps
//
//  Created by Paul on 24.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABackupError.h"
#import "OABackupHelper.h"
#import "Localization.h"

@implementation OABackupError

- (instancetype) initWithError:(NSString *)error
{
    self = [super init];
    if (self) {
        _error = error;
        [self parseError:error];
    }
    return self;
}

- (void) parseError:(NSString *)error
{
    NSData* data = [error dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err = nil;
    NSMutableDictionary *resultError = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
    if (err)
        return;
    if (resultError[@"error"])
    {
        NSDictionary *errorObj = resultError[@"error"];
        _code = [errorObj[@"errorCode"] integerValue];
        _message = errorObj[@"message"];
    }
}

- (NSString *) getLocalizedError
{
    switch (_code)
    {
        case SERVER_ERROR_CODE_EMAIL_IS_INVALID:
            return OALocalizedString(@"osm_live_enter_email");
        case SERVER_ERROR_CODE_NO_VALID_SUBSCRIPTION:
            return OALocalizedString(@"backup_error_no_valid_subscription");
        case SERVER_ERROR_CODE_USER_IS_NOT_REGISTERED:
            return OALocalizedString(@"backup_error_user_is_not_registered");
        case SERVER_ERROR_CODE_TOKEN_IS_NOT_VALID_OR_EXPIRED:
            return OALocalizedString(@"backup_error_token_is_not_valid_or_expired");
        case SERVER_ERROR_CODE_PROVIDED_TOKEN_IS_NOT_VALID:
            return OALocalizedString(@"backup_error_token_is_not_valid");
        case SERVER_ERROR_CODE_FILE_NOT_AVAILABLE:
            return OALocalizedString(@"backup_error_file_not_available");
        case SERVER_ERROR_CODE_GZIP_ONLY_SUPPORTED_UPLOAD:
            return OALocalizedString(@"backup_error_gzip_only_supported_upload");
        case SERVER_ERROR_CODE_SIZE_OF_SUPPORTED_BOX_IS_EXCEEDED:
        {
            if (_message.length > 0)
            {
                NSString *prefix = @"Maximum size of OsmAnd Cloud exceeded ";
                int indexStart = [_message indexOf:prefix];
                int indexEnd = [_message indexOf:@"."];
                if (indexStart != -1 && indexEnd != -1)
                {
                    NSString *size = [_message substringWithRange:NSMakeRange(indexStart + prefix.length, _message.length - (indexEnd + indexStart + prefix.length))];
                    return [NSString stringWithFormat:OALocalizedString(@"backup_error_size_is_exceeded"), size];
                }
            }
            break;
        }
        case SERVER_ERROR_CODE_SUBSCRIPTION_WAS_USED_FOR_ANOTHER_ACCOUNT:
        {
            if (_message.length > 0)
            {
                NSString *prefix = @"user was already signed up as ";
                int index = [_message indexOf:prefix];
                if (index != -1)
                {
                    NSString *login = [_message substringFromIndex:index + prefix.length];
                    return [NSString stringWithFormat:OALocalizedString(@"backup_error_subscription_was_used"), login];
                }
            }
            break;
        }
        case SERVER_ERROR_CODE_SUBSCRIPTION_WAS_EXPIRED_OR_NOT_PRESENT:
            return OALocalizedString(@"backup_error_subscription_was_expired");
        case SERVER_ERROR_CODE_USER_IS_ALREADY_REGISTERED:
            return OALocalizedString(@"backup_error_user_is_already_registered");
        case STATUS_SERVER_TEMPORALLY_UNAVAILABLE_ERROR:
            return OALocalizedString(@"service_is_not_available_please_try_later");
        case STATUS_NO_ORDER_ID_ERROR:
            return OALocalizedString(@"backup_error_no_subscription");
        default:
            break;
    }
    return _message != nil ? _message : _error;
}

- (NSString *) toString
{
    return [NSString stringWithFormat:@"%ld ( %@ )", _code, _message];
}

@end
