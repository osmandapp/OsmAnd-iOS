//
//  OATableViewCellButton.h
//  OsmAnd
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OATableViewCellSimple.h"

@interface OATableViewCellButton : OATableViewCellSimple

@property (weak, nonatomic) IBOutlet UIButton *button;

- (void)buttonVisibility:(BOOL)show;

@end
