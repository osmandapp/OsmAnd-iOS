//
//  OAValueTableViewCell.h
//  OsmAnd
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASimpleTableViewCell.h"

@interface OAValueTableViewCell : OASimpleTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

- (void)valueVisibility:(BOOL)show;

@end
