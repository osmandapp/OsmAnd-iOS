//
//  OACardTableViewCell.h
//  OsmAnd
//
//  Created by Skalii on 23.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleTableViewCell.h"

@interface OACardTableViewCell : OASimpleTableViewCell

@property (weak, nonatomic) IBOutlet UIButton *button;

- (void)topBackgroundMarginVisibility:(BOOL)show;
- (void)buttonVisibility:(BOOL)show;

@end
