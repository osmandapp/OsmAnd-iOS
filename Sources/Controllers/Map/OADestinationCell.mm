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
#import "OADestinationCardsViewController.h"

#import <OsmAndCore.h>
#import <OsmAndCore/Utilities.h>

@implementation OADestinationCell
{
    BOOL _firstRow;
    CGFloat _height;
}

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithDestination:(OADestination *)destination destinationIndex:(NSInteger)destinationIndex
{
    self = [super init];
    if (self)
    {
        _destinationIndex = destinationIndex;
        
        _firstRow = _destinationIndex == 0;
        
        if (_firstRow)
            _height = 50.0;
        else
            _height = 35.0;

        [self commonInit];

        self.destinations = @[destination];
    }
    return self;
}

- (void)commonInit
{
    _infoLabelWidth = 100.0;
    
    if (_firstRow)
    {
        _primaryFont = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
        _unitsFont = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        _descFont = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
        _descColor = UIColorFromRGB(0x8ea2b9);
    }
    else
    {
        _primaryFont = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
        _unitsFont = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
        _descFont = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
        
        _descColor = UIColorFromRGB(0x6C95B1);
    }
    
    _primaryColor = UIColorFromRGB(0xffffff);
    _unitsColor = UIColorFromRGB(0xffffff);
    
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
    CGFloat rightMargin = (_firstRow || self.buttonOkVisible ? 40.0 : 0.0) + (self.buttonOkVisible ? 40.0 : 0.0);
    CGFloat h = frame.size.height;
    CGFloat dirViewWidth = frame.size.width - rightMargin;

    CGRect newFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, h);
    
    _contentView.frame = newFrame;
    
    if (![_contentView isDirectionRTL])
    {
        _directionsView.frame = CGRectMake(0.0, 0.0, dirViewWidth, h);
        
        if (_firstRow)
            _btnClose.frame = CGRectMake(frame.size.width - 40.0, 0.0, 40.0, h);

        if (self.buttonOkVisible)
        {
            _btnOK.frame = CGRectMake(frame.size.width - rightMargin, 0.0, 40.0, h);
            _btnOK.hidden = NO;
        }
        else
        {
            _btnOK.hidden = YES;
        }
        
        _colorView.frame = CGRectMake(5.0, 0.0, 40.0, h);
        _markerView.frame = CGRectMake(32.0, h - 18.0, 14.0, 14.0);
        
        _distanceLabel.frame = CGRectMake(60.0, 7.0, _directionsView.frame.size.width - 68.0, 21.0);
        _distanceLabel.textAlignment = NSTextAlignmentLeft;
        
        _descLabel.frame = CGRectMake(60.0, 24.0, _directionsView.frame.size.width - 68.0, 21.0);
        _descLabel.hidden = !_firstRow;
        
        _infoLabel.frame = CGRectMake(frame.size.width - self.infoLabelWidth - rightMargin - 8.0, 7.0, self.infoLabelWidth, 21.0);
    }
    else
    {
        _directionsView.frame = CGRectMake(40, 0.0, dirViewWidth, h);
        
        if (_firstRow)
            _btnClose.frame = CGRectMake(0, 0.0, 40.0, h);

        if (self.buttonOkVisible)
        {
            _btnOK.frame = CGRectMake(0, 0.0, 40.0, h);
            _btnOK.hidden = NO;
        }
        else
        {
            _btnOK.hidden = YES;
        }
        
        _colorView.frame = CGRectMake(frame.size.width - 85, 0.0, 40.0, h);
        _markerView.frame = CGRectMake(frame.size.width - 53.0, h - 18.0, 14.0, 14.0);
        
        if (_firstRow)
            _distanceLabel.frame = CGRectMake(5, 7.0, _directionsView.frame.size.width - 68.0, 21.0);
        else
            _distanceLabel.frame = CGRectMake(-35, 7.0, _directionsView.frame.size.width - 68.0, 21.0);
        
        _distanceLabel.textAlignment = NSTextAlignmentRight;
        
        _descLabel.frame = CGRectMake(5, 24.0, _directionsView.frame.size.width - 68.0, 21.0);
        _descLabel.hidden = !_firstRow;
        _descLabel.textAlignment = NSTextAlignmentRight;
        
        _infoLabel.frame = CGRectMake(frame.size.width - self.infoLabelWidth - rightMargin - 8.0, 7.0, self.infoLabelWidth, 21.0);
    }
}

- (void)buildUI
{
    UIColor *backgroundColor;
    if (_firstRow)
        backgroundColor = UIColorFromRGB(0x044b7f);
    else
        backgroundColor = UIColorFromRGB(0x03416e);
    
    if (!self.contentView)
    {
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, _height)];
        _contentView.backgroundColor = backgroundColor;
        _contentView.opaque = YES;

        [_contentView.layer setShadowColor:[UIColor blackColor].CGColor];
        [_contentView.layer setShadowOpacity:0.3];
        [_contentView.layer setShadowRadius:3.0];
        [_contentView.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    }
    if (!self.directionsView)
    {
        self.directionsView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth - 41.0, _height)];
        _directionsView.backgroundColor = backgroundColor;
        _directionsView.opaque = YES;
        [_contentView addSubview:self.directionsView];
    }
    
    if (!self.btnClose && _firstRow)
    {
        self.btnClose = [UIButton buttonWithType:UIButtonTypeSystem];
        _btnClose.frame = CGRectMake(DeviceScreenWidth - 40.0, 0.0, 40.0, _height);
        _btnClose.backgroundColor = backgroundColor;
        _btnClose.opaque = YES;
        _btnClose.tintColor = UIColorFromRGB(0x5081a6);
        [_btnClose setTitle:@"" forState:UIControlStateNormal];
        [_btnClose setImage:[UIImage imageNamed:@"ic_arrow_open"] forState:UIControlStateNormal];
        [_btnClose addTarget:self action:@selector(openHideDestinationsView:) forControlEvents:UIControlEventTouchUpInside];
        
        if (self.btnClose)
            [_contentView addSubview:self.btnClose];
    }
    
    if (!self.btnOK)
    {
        self.btnOK = [UIButton buttonWithType:UIButtonTypeSystem];
        _btnOK.frame = CGRectMake(DeviceScreenWidth - 40.0 - (self.btnClose ? 40.0 : 0.0), 0.0, 40.0, _height);
        _btnOK.backgroundColor = backgroundColor;
        _btnOK.opaque = YES;
        _btnOK.tintColor = UIColorFromRGB(0xffffff);
        [_btnOK setTitle:@"" forState:UIControlStateNormal];
        [_btnOK setImage:[UIImage imageNamed:@"ic_trip_visitedpoint"] forState:UIControlStateNormal];
        [_btnOK addTarget:self action:@selector(buttonOKClicked) forControlEvents:UIControlEventTouchUpInside];
        _btnOK.hidden = YES;
        [_contentView addSubview:self.btnOK];
    }
    
    if (!self.colorView)
    {
        self.colorView = [[UIView alloc] initWithFrame:CGRectMake(5.0, 0.0, 40.0, _height)];
        self.colorView.backgroundColor = [UIColor clearColor];
        self.compassImage = [[UIImageView alloc] initWithFrame:_colorView.bounds];
        _compassImage.contentMode = UIViewContentModeCenter;
        [_colorView addSubview:self.compassImage];
        [_directionsView addSubview:self.colorView];
    }

    if (!self.markerView)
    {
        self.markerView = [[UIView alloc] initWithFrame:CGRectMake(32.0, 32.0, 14.0, 14.0)];
        _markerView.backgroundColor = [UIColor clearColor];
        self.markerImage = [[UIImageView alloc] initWithFrame:_markerView.bounds];
        _markerImage.contentMode = UIViewContentModeCenter;
        [_markerView addSubview:self.markerImage];
    }

    if (!self.distanceLabel)
    {
        self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 7.0, 211.0 - self.infoLabelWidth, 21.0)];
        _distanceLabel.font = _primaryFont;
        _distanceLabel.textAlignment = NSTextAlignmentLeft;
        _distanceLabel.textColor = _primaryColor;
        _distanceLabel.minimumScaleFactor = 0.7;
        [_directionsView addSubview:_distanceLabel];
    }
    
    if (!self.infoLabel)
    {
        self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0 + _distanceLabel.frame.size.width, 7.0, self.infoLabelWidth, 21.0)];
        _infoLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
        _infoLabel.textAlignment = NSTextAlignmentRight;
        _infoLabel.textColor = UIColorFromRGB(0x8ea2b9);
        _infoLabel.minimumScaleFactor = 0.7;
        [_directionsView addSubview:_infoLabel];
    }
    
    if (!self.descLabel)
    {
        self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 24.0, 211.0, 21.0)];
        _descLabel.font = _descFont;
        _descLabel.textAlignment = NSTextAlignmentLeft;
        _descLabel.textColor = _descColor;
        [_directionsView addSubview:_descLabel];
    }
    
}

- (void)setDestinations:(NSArray *)destinations
{
    _destinations = destinations;
    if (_destinations)
    {
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

+ (NSString *)parkingTimeStr:(OADestination *)destination shortText:(BOOL)shortText
{
    if (!destination.carPickupDate)
        return nil;
    
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
        if (!shortText)
            return [NSString stringWithFormat:@"%@ %@", time, OALocalizedString(@"time_left")];
        else
            return [NSString stringWithFormat:@"%@", time];
    }
    else
    {
        if (!shortText)
            return [NSString stringWithFormat:@"%@ %@", time, OALocalizedString(@"time_overdue")];
        else
            return [NSString stringWithFormat:@"%@", time];
    }
}

+ (void)setParkingTimerStr:(OADestination *)destination label:(UILabel *)label shortText:(BOOL)shortText
{
    if (!destination.carPickupDate)
        return;
    
    NSTimeInterval timeInterval = [destination.carPickupDate timeIntervalSinceNow];
    
    label.text = [OADestinationCell parkingTimeStr:destination shortText:shortText];
    
    if (timeInterval > 0.0)
        label.textColor = [UIColor colorWithRed:0.678f green:0.678f blue:0.678f alpha:1.00f];
    else
        label.textColor = [UIColor redColor];
}

- (void)reloadData
{
    for (int i = 0; i < _destinations.count; i++) {
        OADestination *destination = _destinations[i];
        switch (i)
        {
            case 0:
                
                if (_firstRow)
                    self.compassImage.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_destination_arrow"] color:destination.color];
                else
                    self.compassImage.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_destination_arrow_small"] color:destination.color];
                
                [self updateMapCenterArrow:self.mapCenterArrow];

                if (destination.parking)
                {
                    if (!_markerView.superview)
                        [_directionsView addSubview:self.markerView];
                }

                [self updateDirection:destination imageView:self.compassImage];
                [self updateDistanceLabel:destination];
                [self updateOkButton:destination];
                
                if (destination.parking && destination.carPickupDate)
                {
                    [OADestinationCell setParkingTimerStr:destination label:self.infoLabel shortText:YES];
                    self.infoLabel.hidden = !_firstRow;
                }
                else
                {
                    self.infoLabel.hidden = YES;
                }
                self.descLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                self.descLabel.text = destination.desc;
                break;
                
            default:
                break;
        }
    }
}

- (void)updateOkButton:(OADestination *)destination
{
    if (!self.mapCenterArrow)
    {
        double distance = OsmAnd::Utilities::distance(self.currentLocation.longitude, self.currentLocation.latitude, destination.longitude, destination.latitude);
        self.buttonOkVisible = distance < kDestinationMinDistanceCheckMarkVisibleMeters;
    }
}

- (void)updateDistanceLabel:(OADestination *)destination
{
    NSString *text = [destination distanceStr:_currentLocation.latitude longitude:_currentLocation.longitude];
    if (!_firstRow)
    {
        if (destination.parking && destination.carPickupDate)
        {
            text = [text stringByAppendingString:[NSString stringWithFormat:@" — %@ (%@)", OALocalizedString(@"parking"), [OADestinationCell parkingTimeStr:destination shortText:YES]]];
        }
        else
        {
            text = [text stringByAppendingString:[NSString stringWithFormat:@" — %@", destination.desc]];
        }
    }

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text];
    
    
    NSUInteger spaceIndex1 = 0;
    NSUInteger spaceIndex2 = 0;
    for (NSUInteger i = 0; i < text.length; i++)
        if ([text characterAtIndex:i] == ' ')
        {
            if (spaceIndex1 == 0)
            {
                spaceIndex1 = i;
                if (_firstRow)
                    break;
            }
            else if (spaceIndex2 == 0)
            {
                spaceIndex2 = i;
            }
            else
                break;
        }
    
    NSRange valueRange = NSMakeRange(0, spaceIndex1);
    NSRange unitRange = NSMakeRange(spaceIndex1, text.length - spaceIndex1);
    NSRange descRange = NSMakeRange(spaceIndex2, text.length - spaceIndex2);
    
    [string addAttribute:NSForegroundColorAttributeName value:_primaryColor range:valueRange];
    [string addAttribute:NSFontAttributeName value:_primaryFont range:valueRange];
    [string addAttribute:NSForegroundColorAttributeName value:_unitsColor range:unitRange];
    [string addAttribute:NSFontAttributeName value:_unitsFont range:unitRange];
    if (spaceIndex2 > 0)
    {
        [string addAttribute:NSForegroundColorAttributeName value:_descColor range:descRange];
        [string addAttribute:NSFontAttributeName value:_descFont range:descRange];
    }
    
    self.distanceLabel.attributedText = string;
}

- (void)updateDirections:(CLLocationCoordinate2D)myLocation direction:(CLLocationDirection)direction
{
    if (!isnan(myLocation.latitude))
    {
        self.currentLocation = myLocation;
        self.currentDirection = direction;
    }
    
    for (int i = 0; i < _destinations.count; i++)
    {
        OADestination *destination = _destinations[i];
        switch (i)
        {
            case 0:
            {
                [self updateDirection:destination imageView:self.compassImage];
                [self updateDistanceLabel:destination];
                [self updateOkButton:destination];
                
                [OADestinationCell setParkingTimerStr:destination label:self.infoLabel shortText:YES];
                break;
            }
                
            default:
                break;
        }
    }
}


-(void)setButtonOkVisible:(BOOL)buttonOkVisible
{
    if (_buttonOkVisible == buttonOkVisible)
        return;
    
    _buttonOkVisible = buttonOkVisible;
    [self updateLayout:_contentView.frame];
}

- (void)updateDirection:(OADestination *)destination imageView:(UIImageView *)imageView
{
    CGFloat itemDirection = [[OsmAndApp instance].locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:destination.latitude longitude:destination.longitude] sourceLocation:[[CLLocation alloc] initWithLatitude:self.currentLocation.latitude longitude:self.currentLocation.longitude]];
    
    CGFloat direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - self.currentDirection) * (M_PI / 180);
    imageView.transform = CGAffineTransformMakeRotation(direction);
}

- (void)closeDestination:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate)
            [_delegate removeDestination:_destinations[0]];
    });
}

- (void)openHideDestinationsView:(id)sender
{
    if (self.delegate)
        [_delegate openHideDestinationCardsView:sender];
}

- (void)updateCloseButton
{
    if (!self.btnClose)
        return;
    
    BOOL cardsVisible = [OADestinationCardsViewController sharedInstance].isVisible;
    
    if (!cardsVisible)
    {
        [self.btnClose setImage:[UIImage imageNamed:@"ic_arrow_open"] forState:UIControlStateNormal];
        self.btnClose.tintColor = UIColorFromRGB(0x5081a6);
    }
    else
    {
        [self.btnClose setImage:[UIImage imageNamed:@"ic_arrow_close"] forState:UIControlStateNormal];
        self.btnClose.tintColor = UIColorFromRGB(0xffffff);
    }
}

- (void)buttonOKClicked
{
    if (self.delegate)
        [self.delegate markAsVisited:_destinations[0]];
}

@end
