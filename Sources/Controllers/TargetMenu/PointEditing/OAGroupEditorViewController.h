//
//  OAGroupEditorViewController.h
//  OsmAnd
//
//  Created by Skalii on 11.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseEditorViewController.h"

@class OASGpxUtilitiesPointsGroup;

@interface OAGroupEditorViewController: OABaseEditorViewController

@property(nonatomic, readonly) OASGpxUtilitiesPointsGroup *group;

- (instancetype)initWithGroup:(OASGpxUtilitiesPointsGroup *)group;

@end
