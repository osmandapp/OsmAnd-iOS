//
//  OATwoButtonsTableViewCell.h
//  OsmAnd
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASimpleTableViewCell.h"

@interface OATwoButtonsTableViewCell : OASimpleTableViewCell

@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

- (void)buttonsVisibility:(BOOL)show;

@end
