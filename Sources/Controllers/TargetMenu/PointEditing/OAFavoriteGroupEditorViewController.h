//
//  OAFavoriteGroupEditorViewController.h
//  OsmAnd
//
//  Created by Skalii on 17.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAGroupEditorViewController.h"

@interface OAFavoriteGroupEditorViewController : OAGroupEditorViewController

@property(nonatomic, copy, nullable) NSString *parentGroupName;
@property(nonatomic) BOOL validatesGroupUniqueness;

@end
