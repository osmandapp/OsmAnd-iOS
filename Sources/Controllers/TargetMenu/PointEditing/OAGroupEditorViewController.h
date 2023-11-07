//
//  OAGroupEditorViewController.h
//  OsmAnd
//
//  Created by Skalii on 11.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseEditorViewController.h"

@class OAPointsGroup;

@interface OAGroupEditorViewController: OABaseEditorViewController

@property(nonatomic, readonly) OAPointsGroup *group;

- (instancetype)initWithGroup:(OAPointsGroup *)group;

@end
