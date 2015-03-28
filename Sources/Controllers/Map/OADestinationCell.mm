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

#import <OsmAndCore.h>
#import <OsmAndCore/Utilities.h>

@implementation OADestinationCell

- (instancetype)initWithDestination:(OADestination *)destination
{
    self = [super init];
    if (self) {
        self.destinations = @[destination];
    }
    return self;
}

- (OADestination *)destinationByPoint:(CGPoint)point
{
    if (CGRectContainsPoint(_directionsView.frame, point))
        return _destinations[0];
    else
        return nil;
}

- (void)updateLayout:(CGRect)frame
{
    CGFloat h = frame.size.height;
    CGFloat dirViewWidth = frame.size.width - 41.0;
    if (_destinations.count == 3 && dirViewWidth / 3.0 < 140.0)
        h += 20.0;

    CGRect newFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, h);
    
    _contentView.frame = newFrame;
    _directionsView.frame = CGRectMake(0.0, (_drawSplitLine ? 1.0 : 0.0), dirViewWidth, h - (_drawSplitLine ? 1.0 : 0.0));
    _btnClose.frame = CGRectMake(_directionsView.frame.size.width + 1, (_drawSplitLine ? 1.0 : 0.0), 40.0, h - (_drawSplitLine ? 1.0 : 0.0));
    
    _colorView.frame = CGRectMake(5.0, 5.0, 40.0, 40.0);
    _distanceLabel.frame = CGRectMake(60.0, 7.0, _directionsView.frame.size.width - 68.0, 21.0);
    _distanceLabel.textAlignment = NSTextAlignmentLeft;
    _descLabel.frame = CGRectMake(60.0, 24.0, _directionsView.frame.size.width - 68.0, 21.0);
    _descLabel.hidden = NO;
    
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
        [_contentView addSubview:self.directionsView];
    }
    
    if (!self.btnClose) {
        self.btnClose = [[UIButton alloc] initWithFrame:CGRectMake(280.0, 0.0, 40.0, 50.0)];
        _btnClose.backgroundColor = [UIColor whiteColor];
        _btnClose.opaque = YES;
        [_btnClose setTitle:@"" forState:UIControlStateNormal];
        [_btnClose setImage:[UIImage imageNamed:@"ic_close"] forState:UIControlStateNormal];
        [_btnClose addTarget:self action:@selector(closeDestination:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:self.btnClose];
    }
    
    if (!self.colorView) {
        self.colorView = [[UIView alloc] initWithFrame:CGRectMake(5.0, 5.0, 40.0, 40.0)];
        _colorView.layer.cornerRadius = _colorView.bounds.size.width / 2.0;
        _colorView.layer.masksToBounds = YES;
        self.compassImage = [[UIImageView alloc] initWithFrame:_colorView.bounds];
        [_compassImage setImage:[UIImage imageNamed:@"ic_destination_arrow_small"]];
        _compassImage.contentMode = UIViewContentModeCenter;
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
    
}

- (void)setDestinations:(NSArray *)destinations
{
    _destinations = destinations;
    if (_destinations) {
        [self buildUI];
        [self reloadData];
        [self updateLayout:_contentView.frame];
    }
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
                
            default:
                break;
        }
    }
}

- (void)updateDirections
{
    CLLocation *loc = [OsmAndApp instance].locationServices.lastKnownLocation;

    for (int i = 0; i < _destinations.count; i++) {
        OADestination *destination = _destinations[i];
        switch (i) {
            case 0:
                [self updateDirection:destination imageView:self.compassImage];
                self.distanceLabel.text = [destination distanceStr:loc.coordinate.latitude longitude:loc.coordinate.longitude];
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
    
    CGFloat direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
    imageView.transform = CGAffineTransformMakeRotation(direction);
}

- (void)closeDestination:(id)sender {
    if (_delegate)
        [_delegate btnCloseClicked:self destination:_destinations[0]];
}

@end
