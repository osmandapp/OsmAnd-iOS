//
//  OASegmentTableViewCell.h
//  OsmAnd
//
//  Created by igor on 12.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OASegmentTableViewCell : OABaseCell
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentControl;

@end

