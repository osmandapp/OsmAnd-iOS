//
//  OAUsernameFilterViewController.h
//  OsmAnd
//
//  Created by Paul on 4/06/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "OAMapSettingsMapillaryScreen.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAUsernameFilterViewController : OACompoundViewController

@property (nonatomic) id<OAMapillaryScreenDelegate> delegate;

- (id) initWithData:(NSArray<NSString *> *)data;

@end

NS_ASSUME_NONNULL_END
