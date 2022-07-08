//
//  OABackupStatus.h
//  OsmAnd Maps
//
//  Created by Paul on 05.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAPrepareBackupResult;

@interface OABackupStatus : NSObject

+ (OABackupStatus *) BACKUP_COMPLETE;
+ (OABackupStatus *) MAKE_BACKUP;
+ (OABackupStatus *) CONFLICTS;
+ (OABackupStatus *) NO_INTERNET_CONNECTION;
+ (OABackupStatus *) SUBSCRIPTION_EXPIRED;
+ (OABackupStatus *) ERROR;

+ (OABackupStatus *) getBackupStatus:(OAPrepareBackupResult *)backup;

@property (nonatomic, readonly) NSString *statusTitle;
@property (nonatomic, readonly) NSString *statusIconName;
@property (nonatomic, readonly) NSString *warningIconName;
@property (nonatomic, readonly) NSString *warningTitle;
@property (nonatomic, readonly) NSString *warningDescription;
@property (nonatomic, readonly) NSString *actionTitle;

@end
