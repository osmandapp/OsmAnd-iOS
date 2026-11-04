//
//  OAResourcesInstaller.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/27/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

UIKIT_EXTERN NSString *const OAResourceInstalledNotification;
UIKIT_EXTERN NSString *const OAResourceInstallationFailedNotification;
// Posted on the main thread with the resource id when a downloaded resource is no longer being installed
UIKIT_EXTERN NSString *const OAResourceInstallingFinishedNotification;

@interface OAResourcesInstaller : NSObject

- (instancetype)init;

+ (BOOL) installCustomResource:(NSString *)localPath resourceId:(NSString *)resourceId fileName:(NSString *)fileName hidden:(BOOL)hidden;

// Downloaded, but not installed yet
+ (BOOL) isInstalling:(NSString *)resourceId;

@end
