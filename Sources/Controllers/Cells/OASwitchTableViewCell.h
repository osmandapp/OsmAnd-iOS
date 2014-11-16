//
//  OASwitchTableViewCell.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 16.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OATableViewCell.h"

@interface OASwitchTableViewCell : OATableViewCell
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UISwitch *switchView;

@end
