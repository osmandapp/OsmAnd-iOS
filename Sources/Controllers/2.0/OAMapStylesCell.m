//
//  OAMapStylesCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 12/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapStylesCell.h"

@implementation OAMapStylesCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setSelectedIndex:(NSInteger)selectedIndex
{
    _selectedIndex = selectedIndex;
    [self setupMapTypeButtons:selectedIndex];
}

-(void)setupMapTypeButtons:(NSInteger)tag {
    
    UIColor* buttonColor = [UIColor colorWithRed:83.0/255.0 green:109.0/255.0 blue:254.0/255.0 alpha:1.0];
    
    self.mapTypeButtonView.layer.cornerRadius = 5;
    self.mapTypeButtonCar.layer.cornerRadius = 5;
    self.mapTypeButtonWalk.layer.cornerRadius = 5;
    self.mapTypeButtonBike.layer.cornerRadius = 5;
    
    [self.mapTypeButtonView setImage:[UIImage imageNamed:@"btn_map_type_icon_view.png"] forState:UIControlStateNormal];
    [self.mapTypeButtonCar setImage:[UIImage imageNamed:@"btn_map_type_icon_car.png"] forState:UIControlStateNormal];
    [self.mapTypeButtonWalk setImage:[UIImage imageNamed:@"btn_map_type_icon_walk.png"] forState:UIControlStateNormal];
    [self.mapTypeButtonBike setImage:[UIImage imageNamed:@"btn_map_type_icon_bike.png"] forState:UIControlStateNormal];
    
    [self.mapTypeButtonView setTitleColor:buttonColor forState:UIControlStateNormal];
    [self.mapTypeButtonCar setTitleColor:buttonColor forState:UIControlStateNormal];
    [self.mapTypeButtonWalk setTitleColor:buttonColor forState:UIControlStateNormal];
    [self.mapTypeButtonBike setTitleColor:buttonColor forState:UIControlStateNormal];
    
    [self.mapTypeButtonView setBackgroundColor:[UIColor clearColor]];
    [self.mapTypeButtonCar setBackgroundColor:[UIColor clearColor]];
    [self.mapTypeButtonWalk setBackgroundColor:[UIColor clearColor]];
    [self.mapTypeButtonBike setBackgroundColor:[UIColor clearColor]];
    
    self.mapTypeButtonView.layer.borderColor = [buttonColor CGColor];
    self.mapTypeButtonView.layer.borderWidth = 1;
    self.mapTypeButtonCar.layer.borderColor = [buttonColor CGColor];
    self.mapTypeButtonCar.layer.borderWidth = 1;
    self.mapTypeButtonWalk.layer.borderColor = [buttonColor CGColor];
    self.mapTypeButtonWalk.layer.borderWidth = 1;
    self.mapTypeButtonBike.layer.borderColor = [buttonColor CGColor];
    self.mapTypeButtonBike.layer.borderWidth = 1;
    
    switch (tag) {
        case 0:
            [self.mapTypeButtonView setBackgroundColor:buttonColor];
            [self.mapTypeButtonView setImage:[UIImage imageNamed:@"btn_map_type_icon_view_selected.png"] forState:UIControlStateNormal];
            [self.mapTypeButtonView setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case 1:
            [self.mapTypeButtonCar setBackgroundColor:buttonColor];
            [self.mapTypeButtonCar setImage:[UIImage imageNamed:@"btn_map_type_icon_car_selected.png"] forState:UIControlStateNormal];
            [self.mapTypeButtonCar setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case 2:
            [self.mapTypeButtonWalk setBackgroundColor:buttonColor];
            [self.mapTypeButtonWalk setImage:[UIImage imageNamed:@"btn_map_type_icon_walk_selected.png"] forState:UIControlStateNormal];
            [self.mapTypeButtonWalk setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case 3:
            [self.mapTypeButtonBike setBackgroundColor:buttonColor];
            [self.mapTypeButtonBike setImage:[UIImage imageNamed:@"btn_map_type_icon_bike_selected.png"] forState:UIControlStateNormal];
            [self.mapTypeButtonBike setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}


@end
