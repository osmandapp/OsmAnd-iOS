//
//  OACloudAccountVerificationViewController.h
//  OsmAnd
//
//  Created by nnngrach on 23.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudAccountBaseViewController.h"
#import "OACloudBackupViewController.h"

@interface OACloudAccountVerificationViewController : OACloudAccountBaseViewController

- (instancetype) initWithEmail:(NSString *)email sourceType:(EOACloudScreenSourceType)type;

@end
