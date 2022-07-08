//
//  OABackupStatus.m
//  OsmAnd Maps
//
//  Created by Paul on 05.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABackupStatus.h"
#import "OAPrepareBackupResult.h"
#import "OABackupInfo.h"
#import "OABackupError.h"
#import "OABackupHelper.h"
#import "Reachability.h"
#import "Localization.h"

@implementation OABackupStatus

static OABackupStatus *BACKUP_COMPLETE;
static OABackupStatus *MAKE_BACKUP;
static OABackupStatus *CONFLICTS;
static OABackupStatus *NO_INTERNET_CONNECTION;
static OABackupStatus *SUBSCRIPTION_EXPIRED;
static OABackupStatus *ERROR;

- (instancetype) initWithStatusTitle:(NSString *)statusTitle
                      statusIconName:(NSString *)statusIconName
                     warningIconName:(NSString *)warningIconName
                        warningTitle:(NSString *)warningTitle
                  warningDescription:(NSString *)warningDescription
                         actionTitle:(NSString *)actionTitle
{
    self = [super init];
    if (self) {
        _statusTitle = statusTitle;
        _statusIconName = statusIconName;
        _warningIconName = warningIconName;
        _warningTitle = warningTitle;
        _warningDescription = warningDescription;
        _actionTitle = actionTitle;
    }
    return self;
}

+ (OABackupStatus *) BACKUP_COMPLETE
{
    if (!BACKUP_COMPLETE)
    {
        BACKUP_COMPLETE = [[OABackupStatus alloc] initWithStatusTitle:OALocalizedString(@"backup_complete")
                                                       statusIconName:@"ic_custom_cloud_done"
                                                      warningIconName:nil warningTitle:nil
                                                   warningDescription:nil
                                                          actionTitle:OALocalizedString(@"cloud_backup_now")];
    }
    return BACKUP_COMPLETE;
}
+ (OABackupStatus *) MAKE_BACKUP
{
    if (!MAKE_BACKUP)
    {
        MAKE_BACKUP = [[OABackupStatus alloc] initWithStatusTitle:OALocalizedString(@"cloud_last_backup")
                                                   statusIconName:@"ic_custom_cloud"
                                                  warningIconName:@"ic_custom_alert_circle"
                                                     warningTitle:OALocalizedString(@"cloud_make_backup")
                                               warningDescription:OALocalizedString(@"cloud_make_backup_descr")
                                                      actionTitle:OALocalizedString(@"cloud_backup_now")];
    }
    return MAKE_BACKUP;
}

+ (OABackupStatus *) CONFLICTS
{
    if (!CONFLICTS)
    {
        CONFLICTS = [[OABackupStatus alloc] initWithStatusTitle:OALocalizedString(@"cloud_last_backup")
                                                 statusIconName:@"ic_custom_cloud_alert"
                                                warningIconName:@"ic_custom_alert"
                                                   warningTitle:OALocalizedString(@"cloud_conflicts")
                                             warningDescription:OALocalizedString(@"cloud_conflicts_descr")
                                                    actionTitle:OALocalizedString(@"cloud_view_conflicts")];
    }
    return CONFLICTS;
}

+ (OABackupStatus *) NO_INTERNET_CONNECTION
{
    if (!NO_INTERNET_CONNECTION)
    {
        NO_INTERNET_CONNECTION = [[OABackupStatus alloc] initWithStatusTitle:OALocalizedString(@"cloud_last_backup")
                                                              statusIconName:@"ic_custom_cloud_alert"
                                                             warningIconName:@"ic_custom_wifi_off"
                                                                warningTitle:OALocalizedString(@"no_inet_connection")
                                                          warningDescription:OALocalizedString(@"osm_upload_no_internet")
                                                                 actionTitle:OALocalizedString(@"shared_string_retry")];
    }
    return NO_INTERNET_CONNECTION;
}

+ (OABackupStatus *) SUBSCRIPTION_EXPIRED
{
    if (!SUBSCRIPTION_EXPIRED)
    {
        SUBSCRIPTION_EXPIRED = [[OABackupStatus alloc] initWithStatusTitle:OALocalizedString(@"cloud_last_backup")
                                                            statusIconName:@"ic_custom_cloud_alert"
                                                           warningIconName:@"ic_custom_osmand_pro_logo_colored"
                                                              warningTitle:OALocalizedString(@"backup_error_subscription_was_expired")
                                                        warningDescription:OALocalizedString(@"backup_error_subscription_was_expired_descr")
                                                               actionTitle:OALocalizedString(@"renew_subscription")];
    }
    return SUBSCRIPTION_EXPIRED;
}
+ (OABackupStatus *) ERROR
{
    if (!ERROR)
    {
        ERROR = [[OABackupStatus alloc] initWithStatusTitle:OALocalizedString(@"cloud_last_backup")
                                             statusIconName:@"ic_custom_cloud_alert"
                                            warningIconName:@"ic_custom_alert"
                                               warningTitle:nil
                                         warningDescription:nil
                                                actionTitle:OALocalizedString(@"shared_string_retry")];
    }
    return ERROR;
}

+ (OABackupStatus *) getBackupStatus:(OAPrepareBackupResult *)backup
{
    OABackupInfo *info = backup.backupInfo;
    
    if (backup.error.length > 0)
    {
        OABackupError *error = [[OABackupError alloc] initWithError:backup.error];
        NSInteger errorCode = error.code;
        if (errorCode == SERVER_ERROR_CODE_SUBSCRIPTION_WAS_EXPIRED_OR_NOT_PRESENT
            || errorCode == STATUS_NO_ORDER_ID_ERROR)
        {
            return OABackupStatus.SUBSCRIPTION_EXPIRED;
        }
    }
    if (info != nil)
    {
        if (info.filteredFilesToMerge.count > 0)
        {
            return OABackupStatus.CONFLICTS;
        }
        else if (info.itemsToUpload.count > 0 || info.itemsToDelete.count > 0)
        {
            return OABackupStatus.MAKE_BACKUP;
        }
    }
    else if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable)
    {
        return OABackupStatus.NO_INTERNET_CONNECTION;
    }
    else if (backup.error != nil)
    {
        return OABackupStatus.ERROR;
    }
    return OABackupStatus.BACKUP_COMPLETE;
}

@end
