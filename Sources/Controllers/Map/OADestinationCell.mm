//
//  OADestinationCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestinationCell.h"
#import "OADestination.h"
#import "OsmAndApp.h"

@interface OADestinationCell ()

@property (nonatomic) UIView *directionsView;
@property (nonatomic) UIButton *btnClose;
@property (nonatomic) UIView *colorView;
@property (nonatomic) UIImageView *compassImage;
@property (nonatomic) UILabel *distanceLabel;
@property (nonatomic) UILabel *descLabel;

@property (nonatomic) UIView *colorView2;
@property (nonatomic) UIImageView *compassImage2;
@property (nonatomic) UILabel *distanceLabel2;
@property (nonatomic) UILabel *descLabel2;

@property (nonatomic) UIView *colorView3;
@property (nonatomic) UIImageView *compassImage3;
@property (nonatomic) UILabel *distanceLabel3;
@property (nonatomic) UILabel *descLabel3;


@end

@implementation OADestinationCell

- (instancetype)initWithDestination:(OADestination *)destination
{
    return [self initWithDestinations:@[destination]];
}

- (instancetype)initWithDestinations:(NSArray *)destinations
{
    self = [super init];
    if (self) {
        self.destinations = destinations;
    }
    return self;
}

- (void)updateLayout:(CGRect)frame
{
    
    CGFloat h = 50.0;
    if (_destinations.count == 3 && _directionsView.bounds.size.width / 3.0 < 140.0)
        h = 70.0;
    
    CGRect newFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, h);
    
    _contentView.frame = newFrame;
    _directionsView.frame = CGRectMake(0.0, 0.0, newFrame.size.width - 41.0, h);
    _btnClose.frame = CGRectMake(_directionsView.frame.size.width + 1, 0.0, 40.0, h);
    
    switch (_destinations.count) {
        case 1:
        {
            _colorView.frame = CGRectMake(5.0, 5.0, 40.0, 40.0);
            _distanceLabel.frame = CGRectMake(60.0, 7.0, _directionsView.frame.size.width - 68.0, 21.0);
            _descLabel.frame = CGRectMake(60.0, 24.0, _directionsView.frame.size.width - 68.0, 21.0);
            
            if (_colorView2)
                _colorView2.alpha = 0.0;
            if (_distanceLabel2)
                _distanceLabel2.alpha = 0.0;
            if (_descLabel2)
                _descLabel2.alpha = 0.0;

            if (_colorView3)
                _colorView3.alpha = 0.0;
            if (_distanceLabel3)
                _distanceLabel3.alpha = 0.0;
            if (_descLabel3)
                _descLabel3.alpha = 0.0;

            break;
        }
        case 2:
        {
            _colorView.frame = CGRectMake(5.0, 5.0, 40.0, 40.0);
            CGFloat textWidth = newFrame.size.width / 2.0 - 82.0;
            if (textWidth > 100.0) {
                _distanceLabel.frame = CGRectMake(55.0, 7.0, textWidth, 21.0);
                _descLabel.frame = CGRectMake(55.0, 24.0, textWidth, 21.0);
            } else {
                _distanceLabel.frame = CGRectMake(55.0, 15.0, textWidth, 21.0);
                _descLabel.alpha = 0.0;
            }
            
            _colorView2.frame = CGRectMake(newFrame.size.width / 2.0 - 20.0, 5.0, 40.0, 40.0);
            _colorView2.alpha = 1.0;
            
            if (textWidth > 100.0) {
                _distanceLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 7.0, textWidth, 21.0);
                _distanceLabel2.alpha = 1.0;
                _descLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 24.0, textWidth, 21.0);
                _descLabel2.alpha = 1.0;
            } else {
                _distanceLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 15.0, textWidth, 21.0);
                _distanceLabel2.alpha = 1.0;
                _descLabel2.alpha = 0.0;
            }
            
            if (_colorView3)
                _colorView3.alpha = 0.0;
            if (_distanceLabel3)
                _distanceLabel3.alpha = 0.0;
            if (_descLabel3)
                _descLabel3.alpha = 0.0;
            
            break;
        }
        case 3:
        {
            CGFloat width = _directionsView.bounds.size.width / 3.0;
            if (width >= 160) {
                CGFloat textWidth = width - 60.0;
                _colorView.frame = CGRectMake(5.0, 5.0, 40.0, 40.0);
                _distanceLabel.frame = CGRectMake(55.0, 7.0, textWidth, 21.0);
                _descLabel.frame = CGRectMake(55.0, 24.0, textWidth, 21.0);

                _colorView2.frame = CGRectMake(width, 5.0, 40.0, 40.0);
                _colorView2.alpha = 1.0;
                _distanceLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 7.0, textWidth, 21.0);
                _distanceLabel2.alpha = 1.0;
                _descLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 24.0, textWidth, 21.0);
                _descLabel2.alpha = 1.0;

                _colorView3.frame = CGRectMake(width * 2.0, 5.0, 40.0, 40.0);
                _colorView3.alpha = 1.0;
                _distanceLabel3.frame = CGRectMake(_colorView3.frame.origin.x + 50.0, 7.0, textWidth, 21.0);
                _distanceLabel3.alpha = 1.0;
                _descLabel3.frame = CGRectMake(_colorView3.frame.origin.x + 50.0, 24.0, textWidth, 21.0);
                _descLabel3.alpha = 1.0;

            } else if (width >= 140) {
                CGFloat textWidth = width - 60.0;
                _colorView.frame = CGRectMake(5.0, 5.0, 40.0, 40.0);
                _distanceLabel.frame = CGRectMake(55.0, 15.0, textWidth, 21.0);
                _descLabel.alpha = 0.0;
                
                _colorView2.frame = CGRectMake(width, 5.0, 40.0, 40.0);
                _colorView2.alpha = 1.0;
                _distanceLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 15.0, textWidth, 21.0);
                _distanceLabel2.alpha = 1.0;
                _descLabel2.alpha = 0.0;
                
                _colorView3.frame = CGRectMake(width * 2.0, 5.0, 40.0, 40.0);
                _colorView3.alpha = 1.0;
                _distanceLabel3.frame = CGRectMake(_colorView3.frame.origin.x + 50.0, 15.0, textWidth, 21.0);
                _distanceLabel3.alpha = 1.0;
                _descLabel3.alpha = 0.0;
                
            } else {
                CGFloat textWidth = 70.0;
                _colorView.frame = CGRectMake(width / 2.0 - 20.0, 5.0, 40.0, 40.0);
                _distanceLabel.frame = CGRectMake(width / 2.0 - 35.0, 48.0, textWidth, 21.0);
                _descLabel.alpha = 0.0;
                
                _colorView2.frame = CGRectMake(width + width / 2.0 - 20.0, 5.0, 40.0, 40.0);
                _colorView2.alpha = 1.0;
                _distanceLabel2.frame = CGRectMake(width + width / 2.0 - 35.0, 15.0, textWidth, 21.0);
                _distanceLabel2.alpha = 1.0;
                _descLabel2.alpha = 0.0;
                
                _colorView3.frame = CGRectMake(width * 2.0 + width / 2.0 - 20.0, 5.0, 40.0, 40.0);
                _colorView3.alpha = 1.0;
                _distanceLabel3.frame = CGRectMake(width * 2.0 + width / 2.0 - 35.0, 15.0, textWidth, 21.0);
                _distanceLabel3.alpha = 1.0;
                _descLabel3.alpha = 0.0;
            }
            
            break;
        }
        default:
            break;
    }
    
}


- (void)buildUI
{
    if (!self.contentView) {
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 50.0)];
        _contentView.backgroundColor = [UIColor colorWithRed:0.937f green:0.937f blue:0.937f alpha:1.00f];
        _contentView.opaque = YES;
    }
    if (!self.directionsView) {
        self.directionsView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 279.0, 50.0)];
        _directionsView.backgroundColor = [UIColor whiteColor];
        _directionsView.opaque = YES;
    }
    [_contentView addSubview:self.directionsView];
    
    if (!self.btnClose) {
        self.btnClose = [[UIButton alloc] initWithFrame:CGRectMake(280.0, 0.0, 40.0, 50.0)];
        _btnClose.backgroundColor = [UIColor whiteColor];
        _btnClose.opaque = YES;
        [_btnClose setTitle:@"" forState:UIControlStateNormal];
        [_btnClose setImage:[UIImage imageNamed:@"ic_close"] forState:UIControlStateNormal];
        [_btnClose addTarget:self action:@selector(closeDestination:) forControlEvents:UIControlEventTouchUpInside];
        _btnClose.tag = 0;
        [_contentView addSubview:self.btnClose];
    }
    
    if (!self.colorView) {
        self.colorView = [[UIView alloc] initWithFrame:CGRectMake(5.0, 5.0, 40.0, 40.0)];
        _colorView.layer.cornerRadius = _colorView.bounds.size.width / 2.0;
        _colorView.layer.masksToBounds = YES;
        self.compassImage = [[UIImageView alloc] initWithFrame:_colorView.bounds];
        [_compassImage setImage:[UIImage imageNamed:@"ic_destination_arrow_small"]];
        [_colorView addSubview:self.compassImage];
        [_directionsView addSubview:self.colorView];
    }
    
    if (!self.distanceLabel) {
        self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 7.0, 211.0, 21.0)];
        _distanceLabel.font = [UIFont fontWithName:@"Avenir-Black" size:16.0];
        _distanceLabel.textAlignment = NSTextAlignmentLeft;
        _distanceLabel.textColor = [UIColor colorWithRed:0.369f green:0.510f blue:0.918f alpha:1.00f];
        _distanceLabel.minimumScaleFactor = 0.7;
        [_directionsView addSubview:_distanceLabel];
    }
    
    if (!self.descLabel) {
        self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 24.0, 211.0, 21.0)];
        _descLabel.font = [UIFont fontWithName:@"Avenir-Roman" size:13.0];
        _descLabel.textAlignment = NSTextAlignmentLeft;
        _descLabel.textColor = [UIColor colorWithRed:0.678f green:0.678f blue:0.678f alpha:1.00f];
        //_descLabel.minimumScaleFactor = 0.7;
        [_directionsView addSubview:_descLabel];
    }
    
    if (_destinations.count > 1) {
        if (!self.colorView2) {
            self.colorView2 = [[UIView alloc] initWithFrame:CGRectMake(5.0, 5.0, 40.0, 40.0)];
            _colorView2.layer.cornerRadius = _colorView2.bounds.size.width / 2.0;
            _colorView2.layer.masksToBounds = YES;
            self.compassImage2 = [[UIImageView alloc] initWithFrame:_colorView.bounds];
            [_compassImage2 setImage:[UIImage imageNamed:@"ic_destination_arrow_small"]];
            [_colorView2 addSubview:self.compassImage2];
            [_directionsView addSubview:self.colorView2];
        }
        
        if (!self.distanceLabel2) {
            self.distanceLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 7.0, 211.0, 21.0)];
            _distanceLabel2.font = [UIFont fontWithName:@"Avenir-Black" size:16.0];
            _distanceLabel2.textAlignment = NSTextAlignmentLeft;
            _distanceLabel2.textColor = [UIColor colorWithRed:0.369f green:0.510f blue:0.918f alpha:1.00f];
            _distanceLabel2.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_distanceLabel2];
        }
        
        if (!self.descLabel2) {
            self.descLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 24.0, 211.0, 21.0)];
            _descLabel2.font = [UIFont fontWithName:@"Avenir-Roman" size:13.0];
            _descLabel2.textAlignment = NSTextAlignmentLeft;
            _descLabel2.textColor = [UIColor colorWithRed:0.678f green:0.678f blue:0.678f alpha:1.00f];
            //_descLabel2.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_descLabel2];
        }
    }
    
    if (_destinations.count > 2) {
        if (!self.colorView3) {
            self.colorView3 = [[UIView alloc] initWithFrame:CGRectMake(5.0, 5.0, 40.0, 40.0)];
            _colorView3.layer.cornerRadius = _colorView3.bounds.size.width / 2.0;
            _colorView3.layer.masksToBounds = YES;
            self.compassImage3 = [[UIImageView alloc] initWithFrame:_colorView.bounds];
            [_compassImage3 setImage:[UIImage imageNamed:@"ic_destination_arrow_small"]];
            [_colorView3 addSubview:self.compassImage3];
            [_directionsView addSubview:self.colorView3];
        }
        
        if (!self.distanceLabel3) {
            self.distanceLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 7.0, 211.0, 21.0)];
            _distanceLabel3.font = [UIFont fontWithName:@"Avenir-Black" size:16.0];
            _distanceLabel3.textAlignment = NSTextAlignmentLeft;
            _distanceLabel3.textColor = [UIColor colorWithRed:0.369f green:0.510f blue:0.918f alpha:1.00f];
            _distanceLabel3.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_distanceLabel3];
        }
        
        if (!self.descLabel3) {
            self.descLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 24.0, 211.0, 21.0)];
            _descLabel3.font = [UIFont fontWithName:@"Avenir-Roman" size:13.0];
            _descLabel3.textAlignment = NSTextAlignmentLeft;
            _descLabel3.textColor = [UIColor colorWithRed:0.678f green:0.678f blue:0.678f alpha:1.00f];
            //_descLabel3.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_descLabel3];
        }
    }
}

- (void)setDestinations:(NSArray *)destinations
{
    _destinations = destinations;
    [self buildUI];
    [self reloadData];
}

- (void)reloadData
{
    CLLocation *loc = [OsmAndApp instance].locationServices.lastKnownLocation;
    
    for (int i = 0; i < _destinations.count; i++) {
        OADestination *destination = _destinations[i];
        switch (i) {
            case 0:
                self.colorView.backgroundColor = destination.color;
                [self updateDirection:destination imageView:self.compassImage];
                self.distanceLabel.text = [destination distanceStr:loc.coordinate.latitude longitude:loc.coordinate.longitude];
                self.descLabel.text = destination.desc;
                break;
            case 1:
                self.colorView2.backgroundColor = destination.color;
                [self updateDirection:destination imageView:self.compassImage2];
                self.distanceLabel2.text = [destination distanceStr:loc.coordinate.latitude longitude:loc.coordinate.longitude];
                self.descLabel2.text = destination.desc;
                break;
            case 2:
                self.colorView3.backgroundColor = destination.color;
                [self updateDirection:destination imageView:self.compassImage3];
                self.distanceLabel3.text = [destination distanceStr:loc.coordinate.latitude longitude:loc.coordinate.longitude];
                self.descLabel3.text = destination.desc;
                break;
                
            default:
                break;
        }
    }
}

- (void)updateDirections
{
    for (int i = 0; i < _destinations.count; i++) {
        OADestination *destination = _destinations[i];
        switch (i) {
            case 0:
                [self updateDirection:destination imageView:self.compassImage];
                break;
            case 1:
                [self updateDirection:destination imageView:self.compassImage2];
                break;
            case 2:
                [self updateDirection:destination imageView:self.compassImage3];
                break;
                
            default:
                break;
        }
    }
}

- (void)updateDirection:(OADestination *)destination imageView:(UIImageView *)imageView
{
    OsmAndAppInstance app = [OsmAndApp instance];
    // Obtain fresh location and heading
    CLLocation* newLocation = app.locationServices.lastKnownLocation;
    CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection =
    (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
    ? newLocation.course
    : newHeading;
    
    CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:destination.latitude longitude:destination.longitude]];
    CGFloat direction = -(itemDirection + newDirection / 180.0f * M_PI);
    
    imageView.transform = CGAffineTransformMakeRotation(direction);
}

- (void)closeDestination:(id)sender {
    if (_delegate) {
        [_delegate btnCloseClicked:((UIButton*)sender).tag];
    }
}

@end
