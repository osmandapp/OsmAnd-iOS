//
//  OAMapStylesCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 12/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAMapStylesCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *mapTypeButtonView;
@property (weak, nonatomic) IBOutlet UIButton *mapTypeButtonCar;
@property (weak, nonatomic) IBOutlet UIButton *mapTypeButtonWalk;
@property (weak, nonatomic) IBOutlet UIButton *mapTypeButtonBike;

@property (nonatomic) NSInteger selectedIndex;

-(void)setupMapTypeButtons:(NSInteger)tag;

@end
