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

@interface OAResourcesInstaller : NSObject

- (instancetype)init;

+ (BOOL) installCustomResource:(NSString *)localPath nsResourceId:(NSString *)nsResourceId fileName:(NSString *)fileName;

@end
