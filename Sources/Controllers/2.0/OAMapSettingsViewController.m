//
//  OAMapSettingsViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 12.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSettingsViewController.h"
#import "OASettingsTableViewCell.h"

@interface OAMapSettingsViewController ()

@property NSArray* tableData;

@end

@implementation OAMapSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setupView {

    [self.mapTypeScrollView setContentSize:CGSizeMake(404, 70)];
    [self setupMapTypeButtons:0];
    
    [self.tableView setDelegate:self];
    [self.tableView setDataSource:self];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    [self setupTableData];
    
}

-(void)setupMapTypeButtons:(int)selectedMapType {

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
    
    switch (selectedMapType) {
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

-(void)setupTableData {
    self.tableData = @[@{@"groupName": @"Show on map",
                         @"cells": @[
                                 @{@"name": @"POI",
                                   @"value": @"",
                                   @"type": @"button"},
                                 @{@"name": @"GPX",
                                   @"value": @"",
                                   @"type": @"button"},
                                 @{@"name": @"Favorite",
                                   @"value": @"",
                                   @"type": @"checkButton"},
                                 @{@"name": @"Transport",
                                   @"value": @"",
                                   @"type": @"button"}
                                 ]
                         },
                       @{@"groupName": @"Map type",
                         @"cells": @[
                                 @{@"name": @"Map type",
                                   @"value": @"UniRS",
                                   @"type": @"button"}
                                 ],
                         },
                       @{@"groupName": @"Map style",
                         @"cells": @[
                                 @{@"name": @"Details",
                                   @"value": @"",
                                   @"type": @"button"},
                                 @{@"name": @"Routes",
                                   @"value": @"",
                                   @"type": @"button"},
                                 @{@"name": @"Other",
                                   @"value": @"",
                                   @"type": @"button"}

                                 ],
                         }
                       ];
}

- (IBAction)changeMapTypeButtonClicked:(id)sender {
    int type = ((UIButton*)sender).tag;
    [self setupMapTypeButtons:type];
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.tableData count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [((NSDictionary*)[self.tableData objectAtIndex:section]) objectForKey:@"groupName"];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [((NSArray*)[((NSDictionary*)[self.tableData objectAtIndex:section]) objectForKey:@"cells"]) count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary* data = (NSDictionary*)[((NSArray*)[((NSDictionary*)[self.tableData objectAtIndex:indexPath.section]) objectForKey:@"cells"]) objectAtIndex:indexPath.row];
    
    OASettingsTableViewCell* cell = nil;
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
    cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
    if (cell) {
        [cell.textView setText: [data objectForKey:@"name"]];
        [cell.descriptionView setText: [data objectForKey:@"value"]];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
}





@end
