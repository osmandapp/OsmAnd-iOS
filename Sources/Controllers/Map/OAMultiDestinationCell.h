//
//  OAMultiDestinationCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestinationCell.h"

@interface OAMultiDestinationCell : OADestinationCell

@property (nonatomic) UIButton *editButton1;
@property (nonatomic) UIButton *editButton2;
@property (nonatomic) UIButton *editButton3;

@property (nonatomic) UIView *colorView2;
@property (nonatomic) UIImageView *compassImage2;
@property (nonatomic) UILabel *distanceLabel2;
@property (nonatomic) UILabel *descLabel2;

@property (nonatomic) UIView *colorView3;
@property (nonatomic) UIImageView *compassImage3;
@property (nonatomic) UILabel *distanceLabel3;
@property (nonatomic) UILabel *descLabel3;

@property (nonatomic, readonly) BOOL editModeActive;

- (instancetype)initWithDestinations:(NSArray *)destinations;

- (void)updateLayout:(CGRect)frame;
- (void)reloadData;
- (void)updateDirections;

-(void)exitEditMode;

@end

