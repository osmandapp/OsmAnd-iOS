//
//  OAMultiDestinationCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestinationCell.h"

@interface OAMultiDestinationCell : OADestinationCell

@property (nonatomic) UIView *colorView2;
@property (nonatomic) UIImageView *compassImage2;
@property (nonatomic) UIView *markerView2;
@property (nonatomic) UIImageView *markerImage2;
@property (nonatomic) UILabel *distanceLabel2;
@property (nonatomic) UILabel *descLabel2;
@property (nonatomic) UILabel *infoLabel2;
@property (nonatomic) UIButton *btnOK2;
@property (nonatomic, assign) BOOL buttonOkVisible2;
@property (nonatomic) UIView *backgroundView2;
@property (nonatomic) UIView *closeBtnSeparator;

@property (nonatomic) UIView *colorView3;
@property (nonatomic) UIImageView *compassImage3;
@property (nonatomic) UIView *markerView3;
@property (nonatomic) UIImageView *markerImage3;
@property (nonatomic) UILabel *distanceLabel3;
@property (nonatomic) UILabel *descLabel3;
@property (nonatomic) UILabel *infoLabel3;
@property (nonatomic) UIButton *btnOK3;
@property (nonatomic, assign) BOOL buttonOkVisible3;

- (instancetype)initWithDestinations:(NSArray *)destinations;

- (void)updateLayout:(CGRect)frame;
- (void)reloadData;
- (void)updateDirections:(CLLocationCoordinate2D)myLocation direction:(CLLocationDirection)direction;

@end

