//
//  OAOsmLoginMainViewController.h
//  OsmAnd
//
//  Created by Skalii on 01.09.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@protocol OAAccountSettingDelegate;

@interface OAOsmLoginMainViewController : OACompoundViewController

@property (nonatomic, weak) id<OAAccountSettingDelegate> delegate;

@end
