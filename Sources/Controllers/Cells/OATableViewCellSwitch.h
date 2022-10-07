//
//  OATableViewCellSwitch.h
//  OsmAnd
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASimpleTableViewCell.h"

@interface OATableViewCellSwitch : OASimpleTableViewCell

@property (weak, nonatomic) IBOutlet UIView *dividerView;
@property (weak, nonatomic) IBOutlet UISwitch *switchView;

- (void)dividerVisibility:(BOOL)show;
- (void)switchVisibility:(BOOL)show;

@end
