//
//  OAGroupEditorViewController.h
//  OsmAnd
//
//  Created by Skalii on 11.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseEditorViewController.h"

@class OASGpxUtilitiesPointsGroup;

NS_ASSUME_NONNULL_BEGIN

@interface OAGroupEditorViewController: OABaseEditorViewController

@property(nonatomic, readonly) OASGpxUtilitiesPointsGroup *group;

- (nullable instancetype)initWithGroup:(OASGpxUtilitiesPointsGroup *)group;

@end

NS_ASSUME_NONNULL_END
