//
//  OARightIconTableViewCell.h
//  OsmAnd
//
//  Created by Skalii on 22.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASimpleTableViewCell.h"

@interface OARightIconTableViewCell : OASimpleTableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *rightIconView;

- (void)rightIconVisibility:(BOOL)show;

@end
