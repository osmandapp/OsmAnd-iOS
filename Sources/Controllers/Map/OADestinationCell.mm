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
#import "Localization.h"
#import "OAUtilities.h"

#import <OsmAndCore.h>
#import <OsmAndCore/Utilities.h>

@implementation OADestinationCell

-(instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithDestination:(OADestination *)destination
{
    self = [super init];
    if (self) {
        [self commonInit];
        self.destinations = @[destination];
    }
    return self;
}

- (void)commonInit
{
    _infoLabelWidth = 120.0;
    
    _timeFmt = [[NSDateFormatter alloc] init];
    [_timeFmt setDateStyle:NSDateFormatterNoStyle];
    [_timeFmt setTimeStyle:NSDateFormatterShortStyle];
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
    BOOL isParking = (self.destinations.count > 0) && ((OADestination *)self.destinations[0]).parking;
    
    CGFloat h = frame.size.height;
    CGFloat dirViewWidth = frame.size.width - 41.0;
    if (_destinations.count == 3 && dirViewWidth / 3.0 < 140.0)
        h += 20.0;

    CGRect newFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, h);
    
    _contentView.frame = newFrame;
    _directionsView.frame = CGRectMake(0.0, (_drawSplitLine ? 1.0 : 0.0), dirViewWidth, h - (_drawSplitLine ? 1.0 : 0.0));
    _btnClose.frame = CGRectMake(_directionsView.frame.size.width + 1, (_drawSplitLine ? 1.0 : 0.0), 40.0, h - (_drawSplitLine ? 1.0 : 0.0));
    
    _colorView.frame = CGRectMake(5.0, 5.0, 40.0, 40.0);
    _markerView.frame = CGRectMake(32.0, 32.0, 14.0, 14.0);
    _distanceLabel.frame = CGRectMake(60.0, 7.0, _directionsView.frame.size.width - 68.0 - (isParking ? self.infoLabelWidth : 0.0), 21.0);
    _distanceLabel.textAlignment = NSTextAlignmentLeft;
    _descLabel.frame = CGRectMake(60.0, 24.0, _directionsView.frame.size.width - 68.0, 21.0);
    _descLabel.hidden = NO;
    _infoLabel.frame = CGRectMake(60.0 + _distanceLabel.frame.size.width, 7.0, self.infoLabelWidth, 21.0);
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

    if (!self.markerView) {
        self.markerView = [[UIView alloc] initWithFrame:CGRectMake(32.0, 32.0, 14.0, 14.0)];
        _markerView.backgroundColor = [UIColor whiteColor];
        _markerView.layer.cornerRadius = _markerView.bounds.size.width / 2.0;
        _markerView.layer.masksToBounds = YES;
        self.markerImage = [[UIImageView alloc] initWithFrame:_markerView.bounds];
        _markerImage.contentMode = UIViewContentModeCenter;
        [_markerView addSubview:self.markerImage];
    }

    if (!self.distanceLabel) {
        self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 7.0, 211.0 - self.infoLabelWidth, 21.0)];
        _distanceLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0];
        _distanceLabel.textAlignment = NSTextAlignmentLeft;
        _distanceLabel.textColor = [UIColor colorWithRed:0.369f green:0.510f blue:0.918f alpha:1.00f];
        _distanceLabel.minimumScaleFactor = 0.7;
        [_directionsView addSubview:_distanceLabel];
    }
    
    if (!self.infoLabel) {
        self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0 + _distanceLabel.frame.size.width, 7.0, self.infoLabelWidth, 21.0)];
        _infoLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:13.0];
        _infoLabel.textAlignment = NSTextAlignmentRight;
        _infoLabel.textColor = [UIColor colorWithRed:0.678f green:0.678f blue:0.678f alpha:1.00f];
        _infoLabel.minimumScaleFactor = 0.7;
        [_directionsView addSubview:_infoLabel];
    }
    
    if (!self.descLabel) {
        self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 24.0, 211.0, 21.0)];
        _descLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:13.0];
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

- (void)updateMapCenterArrow:(BOOL)arrow
{
    if (arrow)
    {
        [_markerImage setImage:[UIImage imageNamed:@"destination_map_center"]];
        if (!_markerView.superview)
            [_directionsView addSubview:self.markerView];
    }
    else if (((OADestination *)_destinations[0]).parking)
    {
        [_markerImage setImage:[UIImage imageNamed:@"destination_parking_place"]];
        if (!_markerView.superview)
            [_directionsView addSubview:self.markerView];
    }
    else
    {
        [_markerView removeFromSuperview];
    }
}

- (void)setMapCenterArrow:(BOOL)mapCenterArrow
{
    if (_mapCenterArrow == mapCenterArrow)
        return;
    
    _mapCenterArrow = mapCenterArrow;
    [self updateMapCenterArrow:mapCenterArrow];
}

- (void)setParkingTimerStr:(OADestination *)destination label:(UILabel *)label
{
    if (!destination.carPickupDate)
        return;
    
    NSTimeInterval timeInterval = [destination.carPickupDate timeIntervalSinceNow];
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSMutableString *time = [NSMutableString string];
    if (hours > 0)
        [time appendFormat:@"%d %@", hours, OALocalizedString(@"units_hour")];
    if (minutes > 0)
    {
        if (time.length > 0)
            [time appendString:@" "];
        [time appendFormat:@"%d %@", minutes, OALocalizedString(@"units_min")];
    }
    if (minutes == 0 && hours == 0)
    {
        if (time.length > 0)
            [time appendString:@" "];
        [time appendFormat:@"%d %@", seconds, OALocalizedString(@"units_sec")];
    }
    
    if (timeInterval > 0.0)
    {
        label.textColor = [UIColor colorWithRed:0.678f green:0.678f blue:0.678f alpha:1.00f];
        label.text = [NSString stringWithFormat:@"%@ %@", time, OALocalizedString(@"time_left")];
    }
    else
    {
        label.textColor = [UIColor redColor];
        label.text = [NSString stringWithFormat:@"%@ %@", time, OALocalizedString(@"time_overdue")];
    }
}

- (void)reloadData
{
    for (int i = 0; i < _destinations.count; i++) {
        OADestination *destination = _destinations[i];
        switch (i) {
            case 0:
                self.colorView.backgroundColor = destination.color;
                
                if (destination.parking)
                {
                    [_markerImage setImage:[UIImage imageNamed:@"destination_parking_place"]];
                    if (!_markerView.superview)
                        [_directionsView addSubview:self.markerView];
                }

                [self updateDirection:destination imageView:self.compassImage];
                self.distanceLabel.text = [destination distanceStr:_currentLocation.latitude longitude:_currentLocation.longitude];
                if (destination.parking && destination.carPickupDate)
                {
                    NSString *timeLimit = [_timeFmt stringFromDate:destination.carPickupDate];
                    self.descLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
                    self.descLabel.text = [NSString stringWithFormat:@"%@ %@", OALocalizedString(@"parking_time_limited"), timeLimit];
                    [self setParkingTimerStr:destination label:self.infoLabel];
                    self.infoLabel.hidden = NO;
                }
                else
                {
                    self.infoLabel.hidden = YES;
                    self.descLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                    self.descLabel.text = destination.desc;
                }
                break;
                
            default:
                break;
        }
    }
}

- (void)updateDirections:(CLLocationCoordinate2D)myLocation direction:(CLLocationDirection)direction
{
    self.currentLocation = myLocation;
    self.currentDirection = direction;
    
    for (int i = 0; i < _destinations.count; i++)
    {
        OADestination *destination = _destinations[i];
        switch (i)
        {
            case 0:
                [self updateDirection:destination imageView:self.compassImage];
                self.distanceLabel.text = [destination distanceStr:_currentLocation.latitude longitude:_currentLocation.longitude];
                [self setParkingTimerStr:destination label:self.infoLabel];
                break;
                
            default:
                break;
        }
    }
}

- (void)updateDirection:(OADestination *)destination imageView:(UIImageView *)imageView
{
    CGFloat itemDirection = [[OsmAndApp instance].locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:destination.latitude longitude:destination.longitude] sourceLocation:[[CLLocation alloc] initWithLatitude:self.currentLocation.latitude longitude:self.currentLocation.longitude]];
    
    CGFloat direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - self.currentDirection) * (M_PI / 180);
    imageView.transform = CGAffineTransformMakeRotation(direction);
}

- (void)closeDestination:(id)sender {
    if (_delegate)
        [_delegate btnCloseClicked:self destination:_destinations[0]];
}

@end
