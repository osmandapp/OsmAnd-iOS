//
//  OATableViewCellRightIcon.h
//  OsmAnd
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATableViewCellSimple.h"

@interface OATableViewCellRightIcon : OATableViewCellSimple

@property (weak, nonatomic) IBOutlet UIImageView *rightIconView;

- (void)rightIconVisibility:(BOOL)show;

@end
