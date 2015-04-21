//
//  OAMapStylesCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 12/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapStylesCell.h"
#import "Localization.h"

@implementation OAMapStylesCell

- (void)awakeFromNib
{
    [_mapTypeButtonView setTitle:OALocalizedString(@"m_style_overview") forState:UIControlStateNormal];
    [_mapTypeButtonCar setTitle:OALocalizedString(@"m_style_car") forState:UIControlStateNormal];
    [_mapTypeButtonWalk setTitle:OALocalizedString(@"m_style_walk") forState:UIControlStateNormal];
    [_mapTypeButtonBike setTitle:OALocalizedString(@"m_style_bicycle") forState:UIControlStateNormal];
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
    
    _mapTypeButtonView.layer.cornerRadius = 5;
    _mapTypeButtonCar.layer.cornerRadius = 5;
    _mapTypeButtonWalk.layer.cornerRadius = 5;
    _mapTypeButtonBike.layer.cornerRadius = 5;
    
    [_mapTypeButtonView setImage:[UIImage imageNamed:@"btn_map_type_icon_view.png"] forState:UIControlStateNormal];
    [_mapTypeButtonCar setImage:[UIImage imageNamed:@"btn_map_type_icon_car.png"] forState:UIControlStateNormal];
    [_mapTypeButtonWalk setImage:[UIImage imageNamed:@"btn_map_type_icon_walk.png"] forState:UIControlStateNormal];
    [_mapTypeButtonBike setImage:[UIImage imageNamed:@"btn_map_type_icon_bike.png"] forState:UIControlStateNormal];
    
    [_mapTypeButtonView setTitleColor:buttonColor forState:UIControlStateNormal];
    [_mapTypeButtonCar setTitleColor:buttonColor forState:UIControlStateNormal];
    [_mapTypeButtonWalk setTitleColor:buttonColor forState:UIControlStateNormal];
    [_mapTypeButtonBike setTitleColor:buttonColor forState:UIControlStateNormal];
    
    [_mapTypeButtonView setBackgroundColor:[UIColor clearColor]];
    [_mapTypeButtonCar setBackgroundColor:[UIColor clearColor]];
    [_mapTypeButtonWalk setBackgroundColor:[UIColor clearColor]];
    [_mapTypeButtonBike setBackgroundColor:[UIColor clearColor]];
    
    _mapTypeButtonView.layer.borderColor = [buttonColor CGColor];
    _mapTypeButtonView.layer.borderWidth = 1;
    _mapTypeButtonCar.layer.borderColor = [buttonColor CGColor];
    _mapTypeButtonCar.layer.borderWidth = 1;
    _mapTypeButtonWalk.layer.borderColor = [buttonColor CGColor];
    _mapTypeButtonWalk.layer.borderWidth = 1;
    _mapTypeButtonBike.layer.borderColor = [buttonColor CGColor];
    _mapTypeButtonBike.layer.borderWidth = 1;
    
    switch (tag) {
        case 0:
            [_mapTypeButtonView setBackgroundColor:buttonColor];
            [_mapTypeButtonView setImage:[UIImage imageNamed:@"btn_map_type_icon_view_selected.png"] forState:UIControlStateNormal];
            [_mapTypeButtonView setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case 1:
            [_mapTypeButtonCar setBackgroundColor:buttonColor];
            [_mapTypeButtonCar setImage:[UIImage imageNamed:@"btn_map_type_icon_car_selected.png"] forState:UIControlStateNormal];
            [_mapTypeButtonCar setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case 2:
            [_mapTypeButtonWalk setBackgroundColor:buttonColor];
            [_mapTypeButtonWalk setImage:[UIImage imageNamed:@"btn_map_type_icon_walk_selected.png"] forState:UIControlStateNormal];
            [_mapTypeButtonWalk setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        case 3:
            [_mapTypeButtonBike setBackgroundColor:buttonColor];
            [_mapTypeButtonBike setImage:[UIImage imageNamed:@"btn_map_type_icon_bike_selected.png"] forState:UIControlStateNormal];
            [_mapTypeButtonBike setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}


@end
