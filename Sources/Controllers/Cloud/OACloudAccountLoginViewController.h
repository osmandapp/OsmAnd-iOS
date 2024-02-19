//
//  OACloudAccountLoginViewController.h
//  OsmAnd
//
//  Created by nnngrach on 22.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudAccountBaseViewController.h"


typedef NS_ENUM(NSInteger, EOACloudAccountScreenType)
{
    EOACloudAccountLoginScreenType = 0,
    EOACloudAccountDeletionScreenType
};

@interface OACloudAccountLoginViewController : OACloudAccountBaseViewController

- (instancetype)initWithScreenType:(EOACloudAccountScreenType)type;

@end
